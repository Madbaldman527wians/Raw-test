--[[
    UnifiedSpy v3.0
    Advanced Signal/Remote/Request Logger
    
    Features:
    - API Dump caching with version control
    - Signal hooking via getconnections()
    - Syntax highlighting
    - Built-in executor
    - Debug info (upvalues, constants, protos, metatable)
    - Collapsible log groups
    - Search and filters
    - Statistics and analytics
    - Decompiler integration
    - Condition breakpoints
    - Network monitor
    - Theme system with customizable colors
    - Settings persistence
    - Export logs
    - RobloxReplicatedStorage logging
    - Bindable Events/Functions logging
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local function missing(t, f, fallback)
    if type(f) == t then return f end
    return fallback
end

local cloneref = missing("function", cloneref, function(...) return ... end)
local hookfunction = missing("function", hookfunction)
local hookmetamethod = missing("function", hookmetamethod)
local getnamecallmethod = missing("function", getnamecallmethod or get_namecall_method)
local checkcaller = missing("function", checkcaller, function() return false end)
local newcclosure = missing("function", newcclosure, function(f) return f end)
local replicatesignal = missing("function", replicatesignal)
local getconnections = missing("function", getconnections or get_signal_cons)
local firesignal = missing("function", firesignal)
local getgenv = missing("function", getgenv, function() return _G end)
local getcallingscript = missing("function", getcallingscript, function() return nil end)
local setclipboard = missing("function", setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set))
local iscclosure = missing("function", iscclosure, function() return false end)
local islclosure = missing("function", islclosure, function() return false end)
local getconstants = missing("function", debug.getconstants or getconstants, function() return {} end)
local getupvalues = missing("function", debug.getupvalues or getupvalues, function() return {} end)
local getprotos = missing("function", debug.getprotos or getprotos, function() return {} end)
local getinfo = missing("function", debug.info or getinfo)
local getnilinstances = missing("function", getnilinstances, function() return {} end)
local getrawmetatable = missing("function", getrawmetatable)
local isreadonly = missing("function", isreadonly or table.isfrozen, function() return false end)
local setreadonly = missing("function", setreadonly or makewriteable)
local gethui = missing("function", gethui or get_hidden_gui)
local getgc = missing("function", getgc or get_gc_objects, function() return {} end)
local getreg = missing("function", getreg or debug.getregistry, function() return {} end)
local getinstances = missing("function", getinstances, function() return {} end)
local decompile = missing("function", decompile)
local request = missing("function", request or http_request or (syn and syn.request) or (http and http.request))
local queueteleport = missing("function", queueteleport or queue_on_teleport or (syn and syn.queue_on_teleport))
local isfile = missing("function", isfile, function() return false end)
local readfile = missing("function", readfile, function() return "" end)
local writefile = missing("function", writefile, function() end)
local appendfile = missing("function", appendfile, function() end)
local makefolder = missing("function", makefolder, function() end)
local isfolder = missing("function", isfolder, function() return false end)
local listfiles = missing("function", listfiles, function() return {} end)
local delfile = missing("function", delfile, function() end)
local delfolder = missing("function", delfolder, function() end)

local DEBUG = getgenv().unifiedspyDEBUG or false

DEBUG = true
getgenv().unifiedspyDEBUG = true

local function debugLog(...)
    if DEBUG then print("[UnifiedSpy DEBUG]", ...) end
end

local function debugWarn(...)
    if DEBUG then warn("[UnifiedSpy WARN]", ...) end
end

if getgenv().UnifiedSpyExecuted and type(getgenv().UnifiedSpyShutdown) == "function" then
    debugLog("Shutting down previous instance...")
    pcall(getgenv().UnifiedSpyShutdown)
    task.wait(0.2)
end

local Services = setmetatable({}, {
    __index = function(self, name)
        local success, service = pcall(function()
            return cloneref(game:GetService(name))
        end)
        if success and service then
            rawset(self, name, service)
            return service
        end
        return nil
    end
})

local HttpService = Services.HttpService
local TweenService = Services.TweenService
local UserInputService = Services.UserInputService
local RunService = Services.RunService
local Players = Services.Players
local CoreGui = Services.CoreGui
local MarketplaceService = Services.MarketplaceService
local TextService = Services.TextService
local ReplicatedStorage = Services.ReplicatedStorage
local RobloxReplicatedStorage = nil
pcall(function() RobloxReplicatedStorage = cloneref(game:GetService("RobloxReplicatedStorage")) end)

local FOLDER_MAIN = "UnifiedSpy"
local FOLDER_CACHE = "UnifiedSpy/Cache"
local FOLDER_LOGS = "UnifiedSpy/Logs"
local FILE_SETTINGS = "UnifiedSpy/Settings.json"

local API_DUMP_URL = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/refs/heads/roblox/Full-API-Dump.json"
local VERSION_GUID_URL = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/refs/heads/roblox/version-guid.txt"
local VERSION_URL = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/refs/heads/roblox/version.txt"

local DefaultSettings = {
    Theme = "Dark",
    Colors = {
        Background = {22, 22, 28},
        Sidebar = {28, 28, 35},
        TopBar = {18, 18, 24},
        Accent = {100, 180, 255},
        Text = {220, 220, 230},
        TextDim = {120, 120, 130},
        Success = {100, 255, 120},
        Error = {255, 80, 80},
        Warning = {255, 180, 100},
        Signals = {120, 255, 150},
        Requests = {255, 180, 100},
        Remotes = {100, 180, 255},
        Audios = {255, 100, 200},
        Animations = {100, 255, 255},
        Bindables = {200, 150, 255},
        System = {255, 200, 100},
        SettingsTab = {180, 150, 255},
    },
    Logging = {
        Enabled = true,
        LogRemotes = true,
        LogSignals = true,
        LogRequests = true,
        LogAudios = true,
        LogAnimations = true,
        LogBindables = true,
        LogRobloxReplicatedStorage = true,
        LogCheckcaller = false,
        LogLocalPlayerOnly = false,
    },
    Filters = {
        FilterSpammy = true,
        IgnoreSpammyLogs = true,
        SpamThreshold = 5,
        SpamTimeWindow = 1,
    },
    Display = {
        MaxLogs = 500,
        PathStyle = "Auto",
        EnableAnimations = true,
        ShowTimestamps = true,
        GroupSimilarLogs = true,
    },
    Breakpoints = {},
    Blacklist = {},
    Blocklist = {},
    CollapsedGroups = {},
    TeleportScript = "",
}

local Settings = {}
local SignalDatabase = {}
local ClassSignals = {}
local CachedVersion = nil

local Logs = {
    Signals = {},
    Requests = {},
    Remotes = {},
    Audios = {},
    Animations = {},
    Bindables = {},
    System = {},
}

local LogGroups = {}
local GroupFrames = {}

local Statistics = {
    TotalCalls = 0,
    CallsByType = {},
    CallsByName = {},
    DataTransferred = 0,
    StartTime = tick(),
}

local LogFrames = {}
local TabData = {}
local Selected = nil
local LayoutOrders = {}
local SpamHistory = {}
local SpammySignals = {}
local HookedSignals = {}
local HookedConnections = {}
local OriginalFunctions = {}
local Connections = {}
local Running = true
local CurrentTab = "Remotes"
local TrackedSounds = {}
local TrackedAnimations = {}
local SearchQuery = ""

for tab in pairs(Logs) do
    LayoutOrders[tab] = 999999999
    LogFrames[tab] = {}
    LogGroups[tab] = {}
    GroupFrames[tab] = {}
end

local function ensureFolders()
    pcall(function()
        if not isfolder(FOLDER_MAIN) then makefolder(FOLDER_MAIN) end
        if not isfolder(FOLDER_CACHE) then makefolder(FOLDER_CACHE) end
        if not isfolder(FOLDER_LOGS) then makefolder(FOLDER_LOGS) end
    end)
end

local function httpGet(url)
    local success, result = pcall(function()
        if request then
            local res = request({Url = url, Method = "GET"})
            return res.Body
        else
            return game:HttpGet(url, true)
        end
    end)
    return success and result or nil
end

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = deepCopy(v)
    end
    return copy
end

local function mergeSettings(base, override)
    local result = deepCopy(base)
    for k, v in pairs(override or {}) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = mergeSettings(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

local function loadSettings()
    ensureFolders()
    Settings = deepCopy(DefaultSettings)
    
    if isfile(FILE_SETTINGS) then
        local success, content = pcall(readfile, FILE_SETTINGS)
        if success and content then
            local decodeSuccess, data = pcall(function()
                return HttpService:JSONDecode(content)
            end)
            if decodeSuccess and data then
                Settings = mergeSettings(DefaultSettings, data)
                debugLog("Settings loaded from file")
            end
        end
    end
    
    getgenv().UnifiedSpySettings = Settings
    return Settings
end

local function saveSettings()
    ensureFolders()
    pcall(function()
        local encoded = HttpService:JSONEncode(Settings)
        writefile(FILE_SETTINGS, encoded)
        debugLog("Settings saved")
    end)
end

local function getColor(name)
    local c = Settings.Colors[name]
    if c then
        return Color3.fromRGB(c[1], c[2], c[3])
    end
    return Color3.fromRGB(255, 255, 255)
end

local function setColor(name, r, g, b)
    Settings.Colors[name] = {r, g, b}
    saveSettings()
end

local function cleanOldCache(currentFileName)
    pcall(function()
        local files = listfiles(FOLDER_CACHE)
        for _, file in ipairs(files) do
            local fileName = file:match("([^/\\]+)$")
            if fileName and fileName ~= currentFileName then
                delfile(file)
                debugLog("Deleted old cache:", fileName)
            end
        end
    end)
end

local function loadAPIDump()
    debugLog("Loading API Dump...")
    ensureFolders()
    
    local versionGuid = httpGet(VERSION_GUID_URL)
    local version = httpGet(VERSION_URL)
    
    if not versionGuid or not version then
        debugWarn("Failed to get version info")
        return false
    end
    
    versionGuid = versionGuid:gsub("%s+", "")
    version = version:gsub("%s+", "")
    
    local cacheFileName = versionGuid .. "_Version_" .. version .. ".json"
    local cachePath = FOLDER_CACHE .. "/" .. cacheFileName
    
    CachedVersion = {guid = versionGuid, version = version}
    debugLog("Current version:", version, "GUID:", versionGuid)
    
    local cachedData = nil
    
    if isfile(cachePath) then
        debugLog("Loading from cache:", cacheFileName)
        local success, content = pcall(readfile, cachePath)
        if success and content then
            local decodeSuccess, data = pcall(function()
                return HttpService:JSONDecode(content)
            end)
            if decodeSuccess and data then
                cachedData = data
            end
        end
    end
    
    if not cachedData then
        debugLog("Downloading fresh API Dump...")
        local apiDumpRaw = httpGet(API_DUMP_URL)
        if not apiDumpRaw then
            debugWarn("Failed to download API Dump")
            return false
        end
        
        local decodeSuccess, apiData = pcall(function()
            return HttpService:JSONDecode(apiDumpRaw)
        end)
        
        if not decodeSuccess or not apiData then
            debugWarn("Failed to decode API Dump")
            return false
        end
        
        local processedData = {
            Version = version,
            VersionGuid = versionGuid,
            Classes = {},
            ConnectionFunctions = {}
        }
        
        for _, classData in ipairs(apiData.Classes or {}) do
            local className = classData.Name
            local signals = {}
            local connFuncs = {}
            
            for _, memberData in ipairs(classData.Members or {}) do
                if memberData.MemberType == "Event" or memberData.MemberType == "RBXScriptSignal" then
                    table.insert(signals, {
                        Name = memberData.Name,
                        Security = memberData.Security and memberData.Security.Read or "None",
                        Tags = memberData.Tags or {}
                    })
                elseif memberData.MemberType == "Function" and memberData.ReturnType and memberData.ReturnType.Name == "RBXScriptConnection" then
                    table.insert(connFuncs, {
                        Name = memberData.Name,
                        Security = memberData.Security and memberData.Security.Read or "None",
                    })
                end
            end
            
            if #signals > 0 then
                processedData.Classes[className] = signals
            end
            if #connFuncs > 0 then
                processedData.ConnectionFunctions[className] = connFuncs
            end
        end
        
        pcall(function()
            local encoded = HttpService:JSONEncode(processedData)
            writefile(cachePath, encoded)
            cleanOldCache(cacheFileName)
            debugLog("Cache saved:", cacheFileName)
        end)
        
        cachedData = processedData
    end
    
    for className, signals in pairs(cachedData.Classes or {}) do
        ClassSignals[className] = signals
        for _, signalInfo in ipairs(signals) do
            local key = className .. "." .. signalInfo.Name
            SignalDatabase[key] = {
                ClassName = className,
                SignalName = signalInfo.Name,
                Security = signalInfo.Security,
                Tags = signalInfo.Tags
            }
        end
    end
    
    local signalCount = 0
    for _ in pairs(SignalDatabase) do signalCount = signalCount + 1 end
    debugLog("Loaded", signalCount, "signals from version", cachedData.Version or "unknown")
    
    return true
end

local function instanceToPath(instance)
    if instance == nil then return "nil" end
    if instance == game then return "game" end
    if instance == workspace then return "workspace" end
    
    local style = Settings.Display.PathStyle or "Auto"
    
    local player = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and (instance:IsDescendantOf(p.Character) or instance == p.Character) then
            player = p
            break
        end
    end
    
    local function formatName(name, parent, child)
        if style == "WaitForChild" then
            return ':WaitForChild("' .. name:gsub('"', '\\"') .. '")'
        elseif style == "FindFirstChild" then
            return ':FindFirstChild("' .. name:gsub('"', '\\"') .. '")'
        elseif style == "Index" then
            if name:match("^[%a_][%w_]*$") then
                return "." .. name
            else
                return '["' .. name:gsub('"', '\\"') .. '"]'
            end
        elseif style == "GetChildren" and parent then
            local children = parent:GetChildren()
            for i, c in ipairs(children) do
                if c == child then
                    return ":GetChildren()[" .. i .. "]"
                end
            end
        end
        if name:match("^[%a_][%w_]*$") then
            return "." .. name
        else
            return ':FindFirstChild("' .. name:gsub('"', '\\"') .. '")'
        end
    end
    
    local path = ""
    local current = instance
    
    if player then
        while current and current ~= player.Character do
            path = formatName(current.Name, current.Parent, current) .. path
            current = current.Parent
        end
        if player == Players.LocalPlayer then
            return 'game:GetService("Players").LocalPlayer.Character' .. path
        else
            return 'game:GetService("Players"):FindFirstChild("' .. player.Name .. '").Character' .. path
        end
    end
    
    while current and current.Parent ~= game do
        if current.Parent == nil then
            return string.format('getNil("%s", "%s")', instance.Name:gsub('"', '\\"'), instance.ClassName)
        end
        path = formatName(current.Name, current.Parent, current) .. path
        current = current.Parent
    end
    
    if current and current.Parent == game then
        local serviceName = current.ClassName
        if pcall(function() return game:GetService(serviceName) end) then
            return 'game:GetService("' .. serviceName .. '")' .. path
        else
            return "game" .. formatName(current.Name, game, current) .. path
        end
    end
    
    return "game"
end

local function deepClone(args, copies)
    copies = copies or {}
    local copy
    if type(args) == "table" then
        if copies[args] then
            copy = copies[args]
        else
            copy = {}
            copies[args] = copy
            for k, v in next, args do
                copy[deepClone(k, copies)] = deepClone(v, copies)
            end
        end
    elseif typeof(args) == "Instance" then
        pcall(function() copy = cloneref(args) end)
        if not copy then copy = args end
    else
        copy = args
    end
    return copy
end

local function deepSerialize(value, depth, indent)
    depth = depth or 0
    indent = indent or 4
    if depth > 6 then return "-- max depth" end
    
    local t = typeof(value)
    local spacing = string.rep(" ", depth * indent)
    local nextSpacing = string.rep(" ", (depth + 1) * indent)
    
    if t == "nil" then return "nil"
    elseif t == "string" then
        if #value > 500 then
            return string.format('"%s" --[[%d chars]]', value:sub(1, 500):gsub('"', '\\"'):gsub("\n", "\\n"), #value)
        end
        return '"' .. value:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\t", "\\t") .. '"'
    elseif t == "number" then
        if value == math.huge then return "math.huge"
        elseif value == -math.huge then return "-math.huge"
        elseif value ~= value then return "0/0"
        else return tostring(value) end
    elseif t == "boolean" then return tostring(value)
    elseif t == "Instance" then return instanceToPath(value)
    elseif t == "Vector3" then
        if value == Vector3.zero then return "Vector3.zero" end
        if value == Vector3.one then return "Vector3.one" end
        return string.format("Vector3.new(%s, %s, %s)", value.X, value.Y, value.Z)
    elseif t == "Vector2" then
        if value == Vector2.zero then return "Vector2.zero" end
        if value == Vector2.one then return "Vector2.one" end
        return string.format("Vector2.new(%s, %s)", value.X, value.Y)
    elseif t == "CFrame" then
        if value == CFrame.identity then return "CFrame.identity" end
        return string.format("CFrame.new(%s)", table.concat({value:GetComponents()}, ", "))
    elseif t == "Color3" then
        return string.format("Color3.new(%s, %s, %s)", value.R, value.G, value.B)
    elseif t == "BrickColor" then
        return string.format("BrickColor.new(%d)", value.Number)
    elseif t == "UDim" then
        return string.format("UDim.new(%s, %s)", value.Scale, value.Offset)
    elseif t == "UDim2" then
        return string.format("UDim2.new(%s, %s, %s, %s)", value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
    elseif t == "Rect" then
        return string.format("Rect.new(%s, %s, %s, %s)", value.Min.X, value.Min.Y, value.Max.X, value.Max.Y)
    elseif t == "NumberRange" then
        return string.format("NumberRange.new(%s, %s)", value.Min, value.Max)
    elseif t == "NumberSequence" then
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("NumberSequenceKeypoint.new(%s, %s)", kp.Time, kp.Value))
        end
        return "NumberSequence.new({" .. table.concat(keypoints, ", ") .. "})"
    elseif t == "ColorSequence" then
        local keypoints = {}
        for _, kp in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("ColorSequenceKeypoint.new(%s, Color3.new(%s, %s, %s))", kp.Time, kp.Value.R, kp.Value.G, kp.Value.B))
        end
        return "ColorSequence.new({" .. table.concat(keypoints, ", ") .. "})"
    elseif t == "EnumItem" then return tostring(value)
    elseif t == "RBXScriptSignal" then return "RBXScriptSignal"
    elseif t == "RBXScriptConnection" then return "RBXScriptConnection"
    elseif t == "function" then
        local info = "?"
        pcall(function()
            local src, line, name = debug.info(value, "sln")
            info = string.format("%s:%s:%s", tostring(src or "?"), tostring(line or "?"), tostring(name or "?"))
        end)
        return "function() end --[[" .. info .. "]]"
    elseif t == "table" then
        local parts = {}
        local count = 0
        local isArray = true
        local maxIndex = 0
        
        for k, _ in pairs(value) do
            if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                isArray = false
                break
            end
            maxIndex = math.max(maxIndex, k)
        end
        
        if isArray and maxIndex > 0 then
            for i = 1, maxIndex do
                if count >= 50 then
                    table.insert(parts, nextSpacing .. "-- ... more")
                    break
                end
                count = count + 1
                table.insert(parts, nextSpacing .. deepSerialize(value[i], depth + 1, indent))
            end
        else
            for k, v in pairs(value) do
                if count >= 50 then
                    table.insert(parts, nextSpacing .. "-- ... more")
                    break
                end
                count = count + 1
                local keyStr
                if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                    keyStr = k
                else
                    keyStr = "[" .. deepSerialize(k, depth + 1, indent) .. "]"
                end
                table.insert(parts, nextSpacing .. keyStr .. " = " .. deepSerialize(v, depth + 1, indent))
            end
        end
        if #parts == 0 then return "{}" end
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. spacing .. "}"
    else
        return "nil --[[" .. t .. "]]"
    end
end

local function estimateDataSize(value, seen)
    seen = seen or {}
    local t = typeof(value)
    
    if t == "nil" then return 1
    elseif t == "boolean" then return 1
    elseif t == "number" then return 8
    elseif t == "string" then return #value + 2
    elseif t == "Instance" then return 8
    elseif t == "Vector3" then return 24
    elseif t == "Vector2" then return 16
    elseif t == "CFrame" then return 48
    elseif t == "Color3" then return 12
    elseif t == "UDim2" then return 16
    elseif t == "table" then
        if seen[value] then return 0 end
        seen[value] = true
        local size = 8
        for k, v in pairs(value) do
            size = size + estimateDataSize(k, seen) + estimateDataSize(v, seen)
        end
        return size
    else
        return 8
    end
end

local function getFunctionInfo(func)
    if type(func) ~= "function" then return nil end
    
    local info = {
        Type = "Unknown",
        Source = "?",
        Line = 0,
        Name = "anonymous",
        Upvalues = {},
        Constants = {},
        ProtoCount = 0,
    }
    
    pcall(function()
        if islclosure(func) then info.Type = "Lua"
        elseif iscclosure(func) then info.Type = "C"
        end
    end)
    
    pcall(function()
        local src, line, name = debug.info(func, "sln")
        info.Source = tostring(src or "?")
        info.Line = line or 0
        info.Name = tostring(name or "anonymous")
    end)
    
    pcall(function()
        for i, v in pairs(getupvalues(func)) do
            info.Upvalues[i] = {Value = v, Type = typeof(v)}
        end
    end)
    
    pcall(function()
        for i, v in pairs(getconstants(func)) do
            info.Constants[i] = {Value = v, Type = type(v)}
        end
    end)
    
    pcall(function()
        info.ProtoCount = #getprotos(func)
    end)
    
    return info
end

local function getMetaInfo(obj)
    if not getrawmetatable then return nil end
    local mt = nil
    pcall(function() mt = getrawmetatable(obj) end)
    if not mt then return nil end
    
    local info = {ReadOnly = false, Methods = {}}
    pcall(function() info.ReadOnly = isreadonly(mt) end)
    for k, v in pairs(mt) do
        if type(k) == "string" and k:sub(1, 2) == "__" then
            info.Methods[k] = typeof(v)
        end
    end
    return info
end

local function decompileScript(script)
    if not decompile then return "-- Decompiler not available" end
    local success, result = pcall(decompile, script)
    if success then
        return result or "-- Decompile returned nil"
    else
        return "-- Decompile failed: " .. tostring(result)
    end
end

local function generateScript(logData)
    local lines = {}
    local needsGetNil = false
    
    local function add(text) table.insert(lines, text) end
    
    if Settings.Display.ShowTimestamps and logData.Timestamp then
        add("-- Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S", logData.Timestamp))
    end
    
    if logData.Type == "RemoteEvent" or logData.Type == "UnreliableRemoteEvent" then
        local remotePath = instanceToPath(logData.Remote)
        if remotePath:find("getNil") then needsGetNil = true end
        
        add("-- Remote: " .. logData.Name)
        add("-- Type: " .. logData.Type)
        add("-- Method: " .. (logData.Method or "FireServer"))
        if logData.DataSize then
            add("-- Data Size: ~" .. logData.DataSize .. " bytes")
        end
        add("")
        
        if logData.Args and #logData.Args > 0 then
            add("local args = " .. deepSerialize(logData.Args))
            add("")
            add(remotePath .. ":FireServer(unpack(args))")
        else
            add(remotePath .. ":FireServer()")
        end
        
    elseif logData.Type == "RemoteFunction" then
        local remotePath = instanceToPath(logData.Remote)
        if remotePath:find("getNil") then needsGetNil = true end
        
        add("-- Remote: " .. logData.Name)
        add("-- Type: RemoteFunction")
        if logData.DataSize then
            add("-- Data Size: ~" .. logData.DataSize .. " bytes")
        end
        add("")
        
        if logData.Args and #logData.Args > 0 then
            add("local args = " .. deepSerialize(logData.Args))
            add("")
            add("local result = " .. remotePath .. ":InvokeServer(unpack(args))")
        else
            add("local result = " .. remotePath .. ":InvokeServer()")
        end
        add("print(result)")
        
    elseif logData.Type == "BindableEvent" then
        local bindablePath = instanceToPath(logData.Remote)
        if bindablePath:find("getNil") then needsGetNil = true end
        
        add("-- Bindable: " .. logData.Name)
        add("-- Type: BindableEvent")
        add("")
        
        if logData.Args and #logData.Args > 0 then
            add("local args = " .. deepSerialize(logData.Args))
            add("")
            add(bindablePath .. ":Fire(unpack(args))")
        else
            add(bindablePath .. ":Fire()")
        end
        
    elseif logData.Type == "BindableFunction" then
        local bindablePath = instanceToPath(logData.Remote)
        if bindablePath:find("getNil") then needsGetNil = true end
        
        add("-- Bindable: " .. logData.Name)
        add("-- Type: BindableFunction")
        add("")
        
        if logData.Args and #logData.Args > 0 then
            add("local args = " .. deepSerialize(logData.Args))
            add("")
            add("local result = " .. bindablePath .. ":Invoke(unpack(args))")
        else
            add("local result = " .. bindablePath .. ":Invoke()")
        end
        add("print(result)")
        
    elseif logData.Type == "Signal" then
        local instancePath = instanceToPath(logData.Instance)
        if instancePath:find("getNil") then needsGetNil = true end
        
        add("-- Signal: " .. logData.SignalName)
        add("-- Instance: " .. logData.Instance.Name .. " (" .. logData.Instance.ClassName .. ")")
        add("-- Path: " .. instancePath .. "." .. logData.SignalName)
        add("")
        
        if logData.Args and #logData.Args > 0 then
            add("local args = " .. deepSerialize(logData.Args))
            add("")
        end
        
        if logData.FuncInfo then
            add("--[[ Function Info:")
            add("     Type: " .. logData.FuncInfo.Type)
            add("     Source: " .. logData.FuncInfo.Source)
            add("     Line: " .. logData.FuncInfo.Line)
            add("     Name: " .. logData.FuncInfo.Name)
            add("]]")
            add("")
        end
        
        local sigPath = instancePath .. "." .. logData.SignalName
        if replicatesignal then
            add("-- Replicate:")
            if logData.Args and #logData.Args > 0 then
                add("replicatesignal(" .. sigPath .. ", unpack(args))")
            else
                add("replicatesignal(" .. sigPath .. ")")
            end
        elseif firesignal then
            add("-- Fire:")
            if logData.Args and #logData.Args > 0 then
                add("firesignal(" .. sigPath .. ", unpack(args))")
            else
                add("firesignal(" .. sigPath .. ")")
            end
        end
        
    elseif logData.Type == "Audio" then
        add("-- Audio: " .. logData.Name)
        add("-- SoundId: " .. logData.SoundId)
        add("-- Volume: " .. (logData.Volume or 1))
        add("")
        add("local sound = Instance.new(\"Sound\")")
        add("sound.SoundId = \"" .. logData.SoundId .. "\"")
        add("sound.Volume = " .. (logData.Volume or 1))
        add("sound.Parent = game:GetService(\"SoundService\")")
        add("sound:Play()")
        add("sound.Ended:Wait()")
        add("sound:Destroy()")
        
    elseif logData.Type == "Animation" then
        add("-- Animation: " .. logData.Name)
        add("-- AnimationId: " .. logData.AnimationId)
        add("")
        add("local player = game:GetService(\"Players\").LocalPlayer")
        add("local humanoid = player.Character:FindFirstChildOfClass(\"Humanoid\")")
        add("local animator = humanoid:FindFirstChildOfClass(\"Animator\")")
        add("")
        add("local animation = Instance.new(\"Animation\")")
        add("animation.AnimationId = \"" .. logData.AnimationId .. "\"")
        add("")
        add("local track = animator:LoadAnimation(animation)")
        add("track:Play()")
        
    elseif logData.Type == "HttpRequest" then
        add("-- HTTP Request")
        add("-- URL: " .. (logData.Request.Url or "?"))
        add("-- Method: " .. (logData.Request.Method or "GET"))
        if logData.DataSize then
            add("-- Data Size: ~" .. logData.DataSize .. " bytes")
        end
        add("")
        add("local requestData = " .. deepSerialize(logData.Request))
        add("")
        add("local response = request(requestData)")
        add("print(response.StatusCode)")
        add("print(response.Body)")
        
    elseif logData.Type == "SystemRemote" then
        local remotePath = instanceToPath(logData.Remote)
        if remotePath:find("getNil") then needsGetNil = true end
        
        add("-- System Remote (RobloxReplicatedStorage)")
        add("-- Name: " .. logData.Name)
        add("-- Type: " .. logData.RemoteType)
        add("")
        
        if logData.Args and #logData.Args > 0 then
            add("local args = " .. deepSerialize(logData.Args))
            add("")
        end
        
        add("-- Path: " .. remotePath)
    end
    
    local script = table.concat(lines, "\n")
    
    if needsGetNil then
        script = "local function getNil(name, class)\n    for _, v in ipairs(getnilinstances()) do\n        if v.ClassName == class and v.Name == name then\n            return v\n        end\n    end\nend\n\n" .. script
    end
    
    if logData.Blocked then
        script = "-- THIS CALL WAS BLOCKED\n\n" .. script
    end
    
    return script
end

local function isSpammy(key)
    if not Settings.Filters.FilterSpammy then return false end
    local now = tick()
    if not SpamHistory[key] then
        SpamHistory[key] = {count = 1, lastTime = now}
        return false
    end
    local h = SpamHistory[key]
    if now - h.lastTime > Settings.Filters.SpamTimeWindow then
        h.count = 1
    else
        h.count = h.count + 1
    end
    h.lastTime = now
    if h.count > Settings.Filters.SpamThreshold then
        if Settings.Filters.IgnoreSpammyLogs and not SpammySignals[key] then
            SpammySignals[key] = true
            debugLog("Auto-ignoring spammy:", key)
        end
        return true
    end
    return false
end

local function isFromLocalPlayer(instance)
    if not instance then return false end
    local lp = Players.LocalPlayer
    if not lp or not lp.Character then return false end
    return instance:IsDescendantOf(lp.Character) or instance == lp.Character or instance:IsDescendantOf(lp)
end

local function checkBreakpoint(logData)
    for _, bp in pairs(Settings.Breakpoints) do
        if bp.Enabled then
            if bp.Type == "Name" and logData.Name == bp.Value then
                return true, bp
            elseif bp.Type == "Contains" and logData.Name:find(bp.Value) then
                return true, bp
            elseif bp.Type == "ArgType" then
                for _, arg in pairs(logData.Args or {}) do
                    if typeof(arg) == bp.Value then
                        return true, bp
                    end
                end
            elseif bp.Type == "ArgValue" then
                for _, arg in pairs(logData.Args or {}) do
                    if tostring(arg) == bp.Value then
                        return true, bp
                    end
                end
            end
        end
    end
    return false, nil
end

local function updateStatistics(logData)
    Statistics.TotalCalls = Statistics.TotalCalls + 1
    
    local typeName = logData.Type
    Statistics.CallsByType[typeName] = (Statistics.CallsByType[typeName] or 0) + 1
    
    local name = logData.Name
    Statistics.CallsByName[name] = (Statistics.CallsByName[name] or 0) + 1
    
    if logData.DataSize then
        Statistics.DataTransferred = Statistics.DataTransferred + logData.DataSize
    end
end

local function getStatisticsReport()
    local uptime = tick() - Statistics.StartTime
    local report = {
        "-- UnifiedSpy Statistics Report",
        "-- ================================",
        "",
        "-- Uptime: " .. string.format("%.1f", uptime) .. " seconds",
        "-- Total Calls: " .. Statistics.TotalCalls,
        "-- Calls/Second: " .. string.format("%.2f", Statistics.TotalCalls / math.max(uptime, 1)),
        "-- Data Transferred: ~" .. string.format("%.2f", Statistics.DataTransferred / 1024) .. " KB",
        "",
        "-- By Type:",
    }
    
    for typeName, count in pairs(Statistics.CallsByType) do
        table.insert(report, "    " .. typeName .. ": " .. count)
    end
    
    table.insert(report, "")
    table.insert(report, "-- Top 15 by Name:")
    
    local sorted = {}
    for name, count in pairs(Statistics.CallsByName) do
        table.insert(sorted, {name = name, count = count})
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    
    for i = 1, math.min(15, #sorted) do
        table.insert(report, "    " .. sorted[i].name .. ": " .. sorted[i].count)
    end
    
    return table.concat(report, "\n")
end

local function exportLogs(tabName, format)
    ensureFolders()
    format = format or "lua"
    
    local logs = Logs[tabName] or {}
    local fileName = FOLDER_LOGS .. "/" .. tabName .. "_" .. os.date("%Y%m%d_%H%M%S") .. "." .. format
    
    local content = ""
    
    if format == "lua" then
        content = "-- UnifiedSpy Export\n"
        content = content .. "-- Tab: " .. tabName .. "\n"
        content = content .. "-- Date: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
        content = content .. "-- Count: " .. #logs .. "\n\n"
        
        content = content .. "local logs = {\n"
        for i, log in ipairs(logs) do
            content = content .. "    [" .. i .. "] = {\n"
            content = content .. "        Name = " .. string.format("%q", log.Name or "") .. ",\n"
            content = content .. "        Type = " .. string.format("%q", log.Type or "") .. ",\n"
            content = content .. "        Timestamp = " .. (log.Timestamp or 0) .. ",\n"
            if log.Args then
                content = content .. "        Args = " .. deepSerialize(log.Args, 2) .. ",\n"
            end
            content = content .. "    },\n"
        end
        content = content .. "}\n\nreturn logs"
    elseif format == "json" then
        local exportData = {
            tab = tabName,
            date = os.date("%Y-%m-%d %H:%M:%S"),
            count = #logs,
            logs = {}
        }
        for _, log in ipairs(logs) do
            table.insert(exportData.logs, {
                Name = log.Name,
                Type = log.Type,
                Timestamp = log.Timestamp,
            })
        end
        local success, encoded = pcall(function()
            return HttpService:JSONEncode(exportData)
        end)
        content = success and encoded or "{}"
    end
    
    pcall(function()
        writefile(fileName, content)
    end)
    
    return fileName
end

local function randomString(len)
    len = len or math.random(12, 18)
    local chars = {}
    for i = 1, len do chars[i] = string.char(math.random(97, 122)) end
    return table.concat(chars)
end

local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then pcall(function() inst[k] = v end) end
    end
    for _, child in pairs(children or {}) do child.Parent = inst end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end

local function Tween(inst, props, duration)
    if not Settings.Display.EnableAnimations then
        for k, v in pairs(props) do
            pcall(function() inst[k] = v end)
        end
        return
    end
    TweenService:Create(inst, TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad), props):Play()
end

local Keywords = {
    ["and"]=1,["break"]=1,["do"]=1,["else"]=1,["elseif"]=1,["end"]=1,
    ["false"]=1,["for"]=1,["function"]=1,["if"]=1,["in"]=1,["local"]=1,
    ["nil"]=1,["not"]=1,["or"]=1,["repeat"]=1,["return"]=1,["then"]=1,
    ["true"]=1,["until"]=1,["while"]=1,["continue"]=1,
}

local Builtins = {
    ["print"]=1,["warn"]=1,["error"]=1,["assert"]=1,["type"]=1,["typeof"]=1,
    ["tostring"]=1,["tonumber"]=1,["pairs"]=1,["ipairs"]=1,["next"]=1,
    ["select"]=1,["unpack"]=1,["pcall"]=1,["xpcall"]=1,["rawget"]=1,
    ["rawset"]=1,["setmetatable"]=1,["getmetatable"]=1,["require"]=1,
    ["loadstring"]=1,["game"]=1,["workspace"]=1,["script"]=1,["wait"]=1,
    ["spawn"]=1,["delay"]=1,["tick"]=1,["time"]=1,["task"]=1,["coroutine"]=1,
    ["string"]=1,["table"]=1,["math"]=1,["debug"]=1,["os"]=1,
    ["Instance"]=1,["Vector3"]=1,["Vector2"]=1,["CFrame"]=1,["Color3"]=1,
    ["BrickColor"]=1,["UDim2"]=1,["UDim"]=1,["Enum"]=1,["TweenInfo"]=1,
    ["Ray"]=1,["Rect"]=1,["Region3"]=1,["NumberRange"]=1,["NumberSequence"]=1,
    ["ColorSequence"]=1,["PhysicalProperties"]=1,["RaycastParams"]=1,
}

local function syntaxHighlight(code)
    local result = {}
    local i = 1
    local len = #code
    
    while i <= len do
        local char = code:sub(i, i)
        
        if code:sub(i, i+3) == "--[[" then
            local endPos = code:find("]]", i + 4, true)
            if endPos then
                local comment = code:sub(i, endPos + 1)
                table.insert(result, '<font color="#6A9955">' .. comment:gsub("<", "&lt;"):gsub(">", "&gt;") .. '</font>')
                i = endPos + 2
            else
                local comment = code:sub(i)
                table.insert(result, '<font color="#6A9955">' .. comment:gsub("<", "&lt;"):gsub(">", "&gt;") .. '</font>')
                break
            end
        elseif code:sub(i, i+1) == "--" then
            local endPos = code:find("\n", i) or len + 1
            local comment = code:sub(i, endPos - 1)
            table.insert(result, '<font color="#6A9955">' .. comment:gsub("<", "&lt;"):gsub(">", "&gt;") .. '</font>')
            i = endPos
        elseif code:sub(i, i+1) == "[[" then
            local endPos = code:find("]]", i + 2, true)
            if endPos then
                local str = code:sub(i, endPos + 1)
                table.insert(result, '<font color="#CE9178">' .. str:gsub("<", "&lt;"):gsub(">", "&gt;") .. '</font>')
                i = endPos + 2
            else
                local str = code:sub(i)
                table.insert(result, '<font color="#CE9178">' .. str:gsub("<", "&lt;"):gsub(">", "&gt;") .. '</font>')
                break
            end
        elseif char == '"' or char == "'" then
            local quote = char
            local j = i + 1
            while j <= len do
                local c = code:sub(j, j)
                if c == quote then break
                elseif c == "\\" then j = j + 1
                end
                j = j + 1
            end
            local str = code:sub(i, j)
            table.insert(result, '<font color="#CE9178">' .. str:gsub("<", "&lt;"):gsub(">", "&gt;") .. '</font>')
            i = j + 1
        elseif char:match("%d") or (char == "." and code:sub(i+1, i+1):match("%d")) then
            local j = i
            local hasDecimal = false
            local hasExp = false
            local isHex = code:sub(i, i+1):lower() == "0x"
            if isHex then j = i + 2 end
            while j <= len do
                local c = code:sub(j, j):lower()
                if isHex then
                    if not c:match("[%da-f]") then break end
                else
                    if c == "." and not hasDecimal then
                        hasDecimal = true
                    elseif c == "e" and not hasExp then
                        hasExp = true
                        if code:sub(j+1, j+1):match("[%+%-]") then j = j + 1 end
                    elseif not c:match("%d") then
                        break
                    end
                end
                j = j + 1
            end
            table.insert(result, '<font color="#B5CEA8">' .. code:sub(i, j-1) .. '</font>')
            i = j
        elseif char:match("[%a_]") then
            local j = i
            while j <= len and code:sub(j, j):match("[%w_]") do j = j + 1 end
            local word = code:sub(i, j-1)
            if Keywords[word] then
                table.insert(result, '<font color="#C586C0">' .. word .. '</font>')
            elseif word == "true" or word == "false" or word == "nil" then
                table.insert(result, '<font color="#569CD6">' .. word .. '</font>')
            elseif word == "self" then
                table.insert(result, '<font color="#569CD6">' .. word .. '</font>')
            elseif Builtins[word] then
                table.insert(result, '<font color="#4EC9B0">' .. word .. '</font>')
            elseif code:sub(j, j) == "(" then
                table.insert(result, '<font color="#DCDCAA">' .. word .. '</font>')
            elseif code:sub(i-1, i-1) == ":" then
                table.insert(result, '<font color="#DCDCAA">' .. word .. '</font>')
            else
                table.insert(result, '<font color="#9CDCFE">' .. word .. '</font>')
            end
            i = j
        elseif char:match("[%+%-%%%*/%^#=<>~]") then
            table.insert(result, '<font color="#D4D4D4">' .. char:gsub("<", "&lt;"):gsub(">", "&gt;") .. '</font>')
            i = i + 1
        elseif char:match("[%(%)%[%]%{%}]") then
            table.insert(result, '<font color="#FFD700">' .. char .. '</font>')
            i = i + 1
        elseif char == "," or char == ";" then
            table.insert(result, '<font color="#D4D4D4">' .. char .. '</font>')
            i = i + 1
        else
            table.insert(result, char:gsub("<", "&lt;"):gsub(">", "&gt;"))
            i = i + 1
        end
    end
    
    return table.concat(result)
end

loadSettings()

local ScreenGui = Create("ScreenGui", {
    Name = randomString(),
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
})

pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
end)

ScreenGui.Parent = (gethui and gethui()) or CoreGui
local uiScale = Instance.new("UIScale")
local drag = Instance.new("UIDragDetector")
uiScale.Scale = 0.5
local MainFrame = Create("Frame", {
    Name = "Main",
    Parent = ScreenGui,
    BackgroundColor3 = getColor("Background"),
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, -520, 0.5, -330),
    Size = UDim2.new(0, 1040, 0, 660),
    ClipsDescendants = true,
})
Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = MainFrame})
Create("UIStroke", {Color = Color3.fromRGB(55, 55, 65), Thickness = 1.5, Parent = MainFrame})
uiScale.Parent = MainFrame
drag.Parent = MainFrame
local TopBar = Create("Frame", {
    Name = "TopBar",
    Parent = MainFrame,
    BackgroundColor3 = getColor("TopBar"),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 42),
})
Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = TopBar})
Create("Frame", {
    Parent = TopBar,
    BackgroundColor3 = getColor("TopBar"),
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0.5, 0),
    Size = UDim2.new(1, 0, 0.5, 0),
})

local TitleBtn = Create("TextButton", {
    Parent = TopBar,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 15, 0, 0),
    Size = UDim2.new(0, 130, 1, 0),
    Font = Enum.Font.GothamBlack,
    Text = "UnifiedSpy",
    TextColor3 = getColor("Accent"),
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
    AutoButtonColor = false,
})

local StatusLabel = Create("TextLabel", {
    Parent = TopBar,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 140, 0, 0),
    Size = UDim2.new(0, 60, 1, 0),
    Font = Enum.Font.GothamBold,
    Text = "ACTIVE",
    TextColor3 = getColor("Success"),
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local VersionLabel = Create("TextLabel", {
    Parent = TopBar,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 200, 0, 0),
    Size = UDim2.new(0, 120, 1, 0),
    Font = Enum.Font.Gotham,
    Text = "v3.0",
    TextColor3 = getColor("TextDim"),
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local SearchBox = Create("TextBox", {
    Parent = TopBar,
    BackgroundColor3 = Color3.fromRGB(35, 35, 45),
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, -110, 0, 9),
    Size = UDim2.new(0, 220, 0, 24),
    Font = Enum.Font.Gotham,
    PlaceholderText = "Search logs...",
    Text = "",
    TextColor3 = getColor("Text"),
    PlaceholderColor3 = getColor("TextDim"),
    TextSize = 11,
    ClearTextOnFocus = false,
})
Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = SearchBox})
Create("UIStroke", {Color = Color3.fromRGB(50, 50, 60), Thickness = 1, Parent = SearchBox})

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    SearchQuery = SearchBox.Text:lower()
end)

local function makeWindowBtn(name, text, pos)
    local btn = Create("TextButton", {
        Name = name,
        Parent = TopBar,
        BackgroundTransparency = 1,
        Position = pos,
        Size = UDim2.new(0, 42, 0, 42),
        Font = Enum.Font.GothamBold,
        Text = text,
        TextColor3 = getColor("TextDim"),
        TextSize = 18,
        AutoButtonColor = false,
    })
    btn.MouseEnter:Connect(function()
        Tween(btn, {TextColor3 = getColor("Text")})
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, {TextColor3 = getColor("TextDim")})
    end)
    return btn
end

local CloseBtn = makeWindowBtn("Close", "×", UDim2.new(1, -42, 0, 0))
local MaxBtn = makeWindowBtn("Max", "□", UDim2.new(1, -84, 0, 0))
local MinBtn = makeWindowBtn("Min", "−", UDim2.new(1, -126, 0, 0))

local ContentFrame = Create("Frame", {
    Name = "Content",
    Parent = MainFrame,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 42),
    Size = UDim2.new(1, 0, 1, -42),
})

local Sidebar = Create("Frame", {
    Name = "Sidebar",
    Parent = ContentFrame,
    BackgroundColor3 = getColor("Sidebar"),
    BorderSizePixel = 0,
    Size = UDim2.new(0, 175, 1, 0),
})

local TabListFrame = Create("ScrollingFrame", {
    Name = "TabList",
    Parent = Sidebar,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 8, 0, 10),
    Size = UDim2.new(1, -16, 1, -20),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = getColor("Accent"),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
})
Create("UIListLayout", {Parent = TabListFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})

local MainPanel = Create("Frame", {
    Name = "MainPanel",
    Parent = ContentFrame,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 175, 0, 0),
    Size = UDim2.new(1, -175, 1, 0),
})

local TabDefinitions = {
    {Name = "Remotes", Icon = "R", Order = 1, ColorKey = "Remotes"},
    {Name = "Signals", Icon = "S", Order = 2, ColorKey = "Signals"},
    {Name = "Requests", Icon = "H", Order = 3, ColorKey = "Requests"},
    {Name = "Bindables", Icon = "B", Order = 4, ColorKey = "Bindables"},
    {Name = "System", Icon = "Y", Order = 5, ColorKey = "System"},
    {Name = "Audios", Icon = "A", Order = 6, ColorKey = "Audios"},
    {Name = "Animations", Icon = "M", Order = 7, ColorKey = "Animations"},
    {Name = "Settings", Icon = "⚙", Order = 8, ColorKey = "SettingsTab", IsSettings = true},
}

local function createLogTab(tabDef)
    local tabName = tabDef.Name
    local color = getColor(tabDef.ColorKey)
    
    local content = Create("Frame", {
        Name = tabName,
        Parent = MainPanel,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
    })
    
    local leftPanel = Create("Frame", {
        Parent = content,
        BackgroundColor3 = Color3.fromRGB(30, 30, 38),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 6, 0, 6),
        Size = UDim2.new(0.34, -8, 1, -12),
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = leftPanel})
    
    local headerLeft = Create("Frame", {
        Parent = leftPanel,
        BackgroundColor3 = Color3.fromRGB(35, 35, 45),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36),
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = headerLeft})
    Create("Frame", {Parent = headerLeft, BackgroundColor3 = Color3.fromRGB(35, 35, 45), BorderSizePixel = 0, Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0.5, 0)})
    
    Create("TextLabel", {
        Parent = headerLeft,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.6, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = tabDef.Icon .. " " .. tabName,
        TextColor3 = color,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local countLabel = Create("TextLabel", {
        Name = "Count",
        Parent = headerLeft,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.6, 0, 0, 0),
        Size = UDim2.new(0.4, -12, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "0",
        TextColor3 = getColor("TextDim"),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    
    local logScroll = Create("ScrollingFrame", {
        Parent = leftPanel,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 1, -44),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = color,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    Create("UIListLayout", {Parent = logScroll, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3)})
    Create("UIPadding", {Parent = logScroll, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})
    
    local rightPanel = Create("Frame", {
        Parent = content,
        BackgroundColor3 = Color3.fromRGB(22, 22, 28),
        BorderSizePixel = 0,
        Position = UDim2.new(0.34, 4, 0, 6),
        Size = UDim2.new(0.66, -10, 0.56, -8),
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = rightPanel})
    
    local codeHeader = Create("Frame", {
        Parent = rightPanel,
        BackgroundColor3 = Color3.fromRGB(28, 28, 36),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 34),
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = codeHeader})
    Create("Frame", {Parent = codeHeader, BackgroundColor3 = Color3.fromRGB(28, 28, 36), BorderSizePixel = 0, Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0.5, 0)})
    
    Create("TextLabel", {
        Parent = codeHeader,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "Code / Executor",
        TextColor3 = getColor("Text"),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local copyBtn = Create("TextButton", {
        Parent = codeHeader,
        BackgroundColor3 = Color3.fromRGB(50, 70, 100),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -150, 0, 5),
        Size = UDim2.new(0, 60, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = "Copy",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 10,
        AutoButtonColor = false,
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = copyBtn})
    
    local runBtn = Create("TextButton", {
        Parent = codeHeader,
        BackgroundColor3 = Color3.fromRGB(50, 100, 50),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -82, 0, 5),
        Size = UDim2.new(0, 72, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = "▶ Run",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 11,
        AutoButtonColor = false,
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = runBtn})
    
    local codeContainer = Create("Frame", {
        Parent = rightPanel,
        BackgroundColor3 = Color3.fromRGB(18, 18, 22),
        Position = UDim2.new(0, 5, 0, 38),
        Size = UDim2.new(1, -10, 1, -43),
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = codeContainer})
    
    local lineNums = Create("TextLabel", {
        Parent = codeContainer,
        BackgroundColor3 = Color3.fromRGB(25, 25, 32),
        Size = UDim2.new(0, 38, 1, 0),
        Font = Enum.Font.Code,
        Text = "1",
        TextColor3 = Color3.fromRGB(75, 75, 90),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextYAlignment = Enum.TextYAlignment.Top,
    })
    Create("UIPadding", {Parent = lineNums, PaddingTop = UDim.new(0, 10), PaddingRight = UDim.new(0, 8)})
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = lineNums})
    
    local codeScroll = Create("ScrollingFrame", {
        Parent = codeContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0, 0),
        Size = UDim2.new(1, -46, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = color,
        AutomaticCanvasSize = Enum.AutomaticSize.XY,
    })
    
    local codeDisplay = Create("TextLabel", {
        Parent = codeScroll,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        Font = Enum.Font.Code,
        Text = "",
        TextColor3 = getColor("Text"),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        RichText = true,
        TextWrapped = false,
    })
    Create("UIPadding", {Parent = codeDisplay, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
    
    local codeInput = Create("TextBox", {
        Parent = codeScroll,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        Font = Enum.Font.Code,
        Text = "-- Select a log entry or type code here",
        TextColor3 = getColor("Text"),
        TextTransparency = 0,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ClearTextOnFocus = false,
        MultiLine = true,
        TextWrapped = false,
        Visible = false,
    })
    Create("UIPadding", {Parent = codeInput, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
    
    local currentCode = "-- Select a log entry or type code here"
    local isEditing = false
    
    local function updateLineNumbers(code)
        local lines = 1
        for _ in code:gmatch("\n") do lines = lines + 1 end
        local nums = {}
        for i = 1, lines do nums[i] = tostring(i) end
        lineNums.Text = table.concat(nums, "\n")
    end
    
    local function updateCode(code)
        currentCode = code
        updateLineNumbers(code)
        
        if not isEditing then
            codeInput.Visible = false
            codeDisplay.Visible = true
            codeDisplay.Text = syntaxHighlight(code)
        end
    end
    
    codeContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not isEditing then
            isEditing = true
            codeDisplay.Visible = false
            codeInput.Visible = true
            codeInput.Text = currentCode
            task.defer(function()
                codeInput:CaptureFocus()
            end)
        end
    end)
    
    codeInput.FocusLost:Connect(function()
        isEditing = false
        currentCode = codeInput.Text
        updateCode(currentCode)
    end)
    
    codeInput:GetPropertyChangedSignal("Text"):Connect(function()
        if isEditing then
            updateLineNumbers(codeInput.Text)
        end
    end)
    
    copyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(currentCode)
            copyBtn.Text = "Copied!"
            task.delay(1.5, function()
                copyBtn.Text = "Copy"
            end)
        end
    end)
    
    runBtn.MouseButton1Click:Connect(function()
        if currentCode ~= "" then
            runBtn.Text = "Running..."
            runBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 50)
            
            task.spawn(function()
                local fn, err = loadstring(currentCode)
                if fn then
                    local ok, execErr = pcall(fn)
                    if not ok then
                        debugWarn("Execution error:", execErr)
                        runBtn.Text = "Error!"
                        runBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
                    else
                        runBtn.Text = "Success!"
                        runBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
                    end
                else
                    debugWarn("Syntax error:", err)
                    runBtn.Text = "Syntax Error!"
                    runBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
                end
                
                task.delay(1.5, function()
                    runBtn.Text = "▶ Run"
                    runBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
                end)
            end)
        end
    end)
    
    local actionsPanel = Create("Frame", {
        Parent = content,
        BackgroundColor3 = Color3.fromRGB(28, 28, 36),
        BorderSizePixel = 0,
        Position = UDim2.new(0.34, 4, 0.56, 2),
        Size = UDim2.new(0.66, -10, 0.44, -8),
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = actionsPanel})
    
    local actionsHeader = Create("Frame", {
        Parent = actionsPanel,
        BackgroundColor3 = Color3.fromRGB(32, 32, 42),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30),
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = actionsHeader})
    Create("Frame", {Parent = actionsHeader, BackgroundColor3 = Color3.fromRGB(32, 32, 42), BorderSizePixel = 0, Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0.5, 0)})
    
    Create("TextLabel", {
        Parent = actionsHeader,
--        BackgroundTransparency = 
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -14, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "Actions / Debug Info",
        TextColor3 = getColor("TextDim"),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local btnScroll = Create("ScrollingFrame", {
        Parent = actionsPanel,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 5, 0, 34),
        Size = UDim2.new(1, -10, 1, -38),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = color,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    Create("UIGridLayout", {
        Parent = btnScroll,
        CellSize = UDim2.new(0, 100, 0, 32),
        CellPadding = UDim2.new(0, 6, 0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    Create("UIPadding", {Parent = btnScroll, PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5)})
    
    local function makeActionBtn(text, order, bgColor)
        local btn = Create("TextButton", {
            Parent = btnScroll,
            BackgroundColor3 = bgColor or Color3.fromRGB(45, 45, 58),
            BorderSizePixel = 0,
            Font = Enum.Font.GothamBold,
            Text = text,
            TextColor3 = Color3.fromRGB(220, 220, 230),
            TextSize = 10,
            AutoButtonColor = false,
            LayoutOrder = order,
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = btn})
        btn.MouseEnter:Connect(function()
            Tween(btn, {BackgroundColor3 = Color3.fromRGB(65, 65, 85)})
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundColor3 = bgColor or Color3.fromRGB(45, 45, 58)})
        end)
        return btn
    end
    
    local copyCodeBtn = makeActionBtn("Copy Code", 1, Color3.fromRGB(50, 70, 100))
    local copyPathBtn = makeActionBtn("Copy Path", 2, Color3.fromRGB(50, 70, 100))
    local copyArgsBtn = makeActionBtn("Copy Args", 3, Color3.fromRGB(50, 70, 100))
    local blockBtn = makeActionBtn("Block", 4, Color3.fromRGB(100, 50, 50))
    local ignoreBtn = makeActionBtn("Ignore", 5, Color3.fromRGB(90, 70, 40))
    local clearBtn = makeActionBtn("Clear Tab", 6, Color3.fromRGB(80, 50, 80))
    local funcInfoBtn = makeActionBtn("Func Info", 7)
    local metaInfoBtn = makeActionBtn("Meta Info", 8)
    local upvaluesBtn = makeActionBtn("Upvalues", 9)
    local constantsBtn = makeActionBtn("Constants", 10)
    local connectionsBtn = makeActionBtn("Connections", 11)
    local fireBtn = makeActionBtn("Fire/Replay", 12, Color3.fromRGB(50, 90, 50))
    local decompileBtn = makeActionBtn("Decompile", 13, Color3.fromRGB(70, 60, 90))
    local exportBtn = makeActionBtn("Export Lua", 14, Color3.fromRGB(60, 70, 90))
    local exportJsonBtn = makeActionBtn("Export JSON", 15, Color3.fromRGB(60, 70, 90))
    local statsBtn = makeActionBtn("Statistics", 16, Color3.fromRGB(70, 80, 60))
    local breakpointBtn = makeActionBtn("+ Breakpoint", 17, Color3.fromRGB(100, 80, 50))
    local clearBpBtn = makeActionBtn("Clear BPs", 18, Color3.fromRGB(80, 60, 60))
    
    copyCodeBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(currentCode)
            copyCodeBtn.Text = "Copied!"
            task.delay(1, function() copyCodeBtn.Text = "Copy Code" end)
        end
    end)
    
    copyPathBtn.MouseButton1Click:Connect(function()
        if Selected and setclipboard then
            local path = ""
            if Selected.Remote then
                path = instanceToPath(Selected.Remote)
            elseif Selected.Instance then
                path = instanceToPath(Selected.Instance)
                if Selected.SignalName then
                    path = path .. "." .. Selected.SignalName
                end
            elseif Selected.Sound then
                path = instanceToPath(Selected.Sound)
            end
            setclipboard(path)
            copyPathBtn.Text = "Copied!"
            task.delay(1, function() copyPathBtn.Text = "Copy Path" end)
        end
    end)
    
    copyArgsBtn.MouseButton1Click:Connect(function()
        if Selected and Selected.Args and setclipboard then
            setclipboard(deepSerialize(Selected.Args))
            copyArgsBtn.Text = "Copied!"
            task.delay(1, function() copyArgsBtn.Text = "Copy Args" end)
        end
    end)
    
    blockBtn.MouseButton1Click:Connect(function()
        if Selected then
            Settings.Blocklist[Selected.Name] = true
            if Selected.Remote then
                Settings.Blocklist[tostring(Selected.Remote)] = true
            end
            saveSettings()
            blockBtn.Text = "Blocked!"
            task.delay(1, function() blockBtn.Text = "Block" end)
        end
    end)
    
    ignoreBtn.MouseButton1Click:Connect(function()
        if Selected then
            Settings.Blacklist[Selected.Name] = true
            if Selected.Remote then
                Settings.Blacklist[tostring(Selected.Remote)] = true
            end
            saveSettings()
            ignoreBtn.Text = "Ignored!"
            task.delay(1, function() ignoreBtn.Text = "Ignore" end)
        end
    end)
    
    clearBtn.MouseButton1Click:Connect(function()
        for _, child in pairs(logScroll:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") then
                child:Destroy()
            end
        end
        Logs[tabName] = {}
        LogFrames[tabName] = {}
        LogGroups[tabName] = {}
        GroupFrames[tabName] = {}
        LayoutOrders[tabName] = 999999999
        countLabel.Text = "0"
        updateCode("-- Cleared")
        Selected = nil
    end)
    
    funcInfoBtn.MouseButton1Click:Connect(function()
        if Selected and Selected.FuncInfo then
            local info = "-- Function Info\n"
            info = info .. "-- ================\n\n"
            info = info .. "Type: " .. Selected.FuncInfo.Type .. "\n"
            info = info .. "Source: " .. Selected.FuncInfo.Source .. "\n"
            info = info .. "Line: " .. Selected.FuncInfo.Line .. "\n"
            info = info .. "Name: " .. Selected.FuncInfo.Name .. "\n"
            info = info .. "Proto Count: " .. Selected.FuncInfo.ProtoCount
            updateCode(info)
        else
            updateCode("-- No function info available")
        end
    end)
    
    metaInfoBtn.MouseButton1Click:Connect(function()
        if Selected then
            local target = Selected.Remote or Selected.Instance or Selected.Sound
            if target then
                local meta = getMetaInfo(target)
                if meta then
                    local info = "-- Metatable Info\n"
                    info = info .. "-- ================\n\n"
                    info = info .. "ReadOnly: " .. tostring(meta.ReadOnly) .. "\n\n"
                    info = info .. "Metamethods:\n"
                    for k, v in pairs(meta.Methods) do
                        info = info .. "    " .. k .. ": " .. v .. "\n"
                    end
                    updateCode(info)
                else
                    updateCode("-- No metatable found")
                end
            end
        end
    end)
    
    upvaluesBtn.MouseButton1Click:Connect(function()
        if Selected and Selected.FuncInfo and Selected.FuncInfo.Upvalues then
            local info = "-- Upvalues\n"
            info = info .. "-- ================\n\n"
            local hasUpvalues = false
            for i, data in pairs(Selected.FuncInfo.Upvalues) do
                hasUpvalues = true
                info = info .. "[" .. i .. "] = " .. deepSerialize(data.Value) .. "  -- " .. data.Type .. "\n"
            end
            if not hasUpvalues then
                info = info .. "-- No upvalues found"
            end
            updateCode(info)
        else
            updateCode("-- No upvalues available")
        end
    end)
    
    constantsBtn.MouseButton1Click:Connect(function()
        if Selected and Selected.FuncInfo and Selected.FuncInfo.Constants then
            local info = "-- Constants\n"
            info = info .. "-- ================\n\n"
            local hasConstants = false
            for i, data in pairs(Selected.FuncInfo.Constants) do
                hasConstants = true
                local val = data.Value
                if type(val) == "string" then
                    val = string.format("%q", val)
                else
                    val = tostring(val)
                end
                info = info .. "[" .. i .. "] = " .. val .. "  -- " .. data.Type .. "\n"
            end
            if not hasConstants then
                info = info .. "-- No constants found"
            end
            updateCode(info)
        else
            updateCode("-- No constants available")
        end
    end)
    
    connectionsBtn.MouseButton1Click:Connect(function()
        if Selected and Selected.Instance and Selected.SignalName and getconnections then
            local sig = nil
            pcall(function() sig = Selected.Instance[Selected.SignalName] end)
            if sig then
                local conns = {}
                pcall(function() conns = getconnections(sig) end)
                local info = "-- Signal Connections: " .. #conns .. "\n"
                info = info .. "-- ================\n\n"
                for i, conn in ipairs(conns) do
                    info = info .. "[" .. i .. "] Enabled: " .. tostring(conn.Enabled) .. "\n"
                    if conn.Function then
                        local fInfo = "unknown"
                        pcall(function()
                            local s, l, n = debug.info(conn.Function, "sln")
                            fInfo = tostring(s or "?") .. ":" .. tostring(l or "?") .. " (" .. tostring(n or "anonymous") .. ")"
                        end)
                        info = info .. "    Function: " .. fInfo .. "\n"
                        
                        if conn.LuaClosureType then
                            info = info .. "    Closure: " .. tostring(conn.LuaClosureType) .. "\n"
                        end
                    end
                    info = info .. "\n"
                end
                updateCode(info)
            else
                updateCode("-- Could not access signal")
            end
        else
            updateCode("-- No signal selected or getconnections unavailable")
        end
    end)
    
    fireBtn.MouseButton1Click:Connect(function()
        if Selected then
            local success = false
            local result = nil
            
            if Selected.Remote then
                pcall(function()
                    if Selected.Type == "RemoteEvent" or Selected.Type == "UnreliableRemoteEvent" then
                        Selected.Remote:FireServer(unpack(Selected.Args or {}))
                        success = true
                    elseif Selected.Type == "RemoteFunction" then
                        result = Selected.Remote:InvokeServer(unpack(Selected.Args or {}))
                        success = true
                    elseif Selected.Type == "BindableEvent" then
                        Selected.Remote:Fire(unpack(Selected.Args or {}))
                        success = true
                    elseif Selected.Type == "BindableFunction" then
                        result = Selected.Remote:Invoke(unpack(Selected.Args or {}))
                        success = true
                    end
                end)
            elseif Selected.Instance and Selected.SignalName then
                if replicatesignal then
                    pcall(function()
                        replicatesignal(Selected.Instance[Selected.SignalName], unpack(Selected.Args or {}))
                        success = true
                    end)
                elseif firesignal then
                    pcall(function()
                        firesignal(Selected.Instance[Selected.SignalName], unpack(Selected.Args or {}))
                        success = true
                    end)
                end
            end
            
            if success then
                fireBtn.Text = "Fired!"
                fireBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
                if result ~= nil then
                    updateCode("-- Fire Result:\n\n" .. deepSerialize(result))
                end
            else
                fireBtn.Text = "Failed!"
                fireBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
            end
            
            task.delay(1.5, function()
                fireBtn.Text = "Fire/Replay"
                fireBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
            end)
        end
    end)
    
    decompileBtn.MouseButton1Click:Connect(function()
        if Selected then
            local scriptToDecompile = nil
            
            if Selected.Source and typeof(Selected.Source) == "Instance" then
                scriptToDecompile = Selected.Source
            elseif Selected.FuncInfo and Selected.FuncInfo.Source and Selected.FuncInfo.Source ~= "?" then
                local sourceName = Selected.FuncInfo.Source
                for _, inst in pairs(getgc(true)) do
                    if typeof(inst) == "Instance" and inst:IsA("LuaSourceContainer") then
                        if inst:GetFullName():find(sourceName) or inst.Name == sourceName then
                            scriptToDecompile = inst
                            break
                        end
                    end
                end
            end
            
            if scriptToDecompile then
                local decompiled = decompileScript(scriptToDecompile)
                updateCode(decompiled)
            else
                updateCode("-- No script found to decompile\n-- Source info: " .. (Selected.FuncInfo and Selected.FuncInfo.Source or "N/A"))
            end
        else
            updateCode("-- Select a log entry first")
        end
    end)
    
    exportBtn.MouseButton1Click:Connect(function()
        local fileName = exportLogs(tabName, "lua")
        updateCode("-- Exported to:\n-- " .. fileName)
        exportBtn.Text = "Exported!"
        task.delay(1.5, function() exportBtn.Text = "Export Lua" end)
    end)
    
    exportJsonBtn.MouseButton1Click:Connect(function()
        local fileName = exportLogs(tabName, "json")
        updateCode("-- Exported to:\n-- " .. fileName)
        exportJsonBtn.Text = "Exported!"
        task.delay(1.5, function() exportJsonBtn.Text = "Export JSON" end)
    end)
    
    statsBtn.MouseButton1Click:Connect(function()
        updateCode(getStatisticsReport())
    end)
    
    breakpointBtn.MouseButton1Click:Connect(function()
        if Selected then
            local bp = {
                Enabled = true,
                Type = "Name",
                Value = Selected.Name,
                CreatedAt = os.time(),
            }
            table.insert(Settings.Breakpoints, bp)
            saveSettings()
            updateCode("-- Breakpoint added!\n-- Type: Name Match\n-- Value: " .. Selected.Name .. "\n\n-- Total breakpoints: " .. #Settings.Breakpoints)
            breakpointBtn.Text = "Added!"
            task.delay(1, function() breakpointBtn.Text = "+ Breakpoint" end)
        else
            updateCode("-- Select a log entry to add breakpoint")
        end
    end)
    
    clearBpBtn.MouseButton1Click:Connect(function()
        local count = #Settings.Breakpoints
        Settings.Breakpoints = {}
        saveSettings()
        updateCode("-- Cleared " .. count .. " breakpoints")
        clearBpBtn.Text = "Cleared!"
        task.delay(1, function() clearBpBtn.Text = "Clear BPs" end)
    end)
    
    TabData[tabName] = {
        Content = content,
        LogScroll = logScroll,
        CountLabel = countLabel,
        UpdateCode = updateCode,
        Color = color,
    }
    
    return content
end

local function createSettingsTab()
    local content = Create("Frame", {
        Name = "Settings",
        Parent = MainPanel,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
    })
    
    local scroll = Create("ScrollingFrame", {
        Parent = content,
        BackgroundColor3 = Color3.fromRGB(28, 28, 36),
        Position = UDim2.new(0, 6, 0, 6),
        Size = UDim2.new(1, -12, 1, -12),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = getColor("SettingsTab"),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = scroll})
    Create("UIListLayout", {Parent = scroll, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})
    Create("UIPadding", {Parent = scroll, PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)})
    
    local function createSection(title, order)
        local section = Create("Frame", {
            Parent = scroll,
            BackgroundColor3 = Color3.fromRGB(35, 35, 45),
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = order,
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = section})
        Create("UIListLayout", {Parent = section, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        Create("UIPadding", {Parent = section, PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)})
        
        Create("TextLabel", {
            Parent = section,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 24),
            Font = Enum.Font.GothamBold,
            Text = title,
            TextColor3 = getColor("SettingsTab"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 0,
        })
        
        return section
    end
    
    local function createToggle(parent, name, settingPath, order)
        local container = Create("Frame", {
            Parent = parent,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 28),
            LayoutOrder = order,
        })
        
        Create("TextLabel", {
            Parent = container,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.7, 0, 1, 0),
            Font = Enum.Font.Gotham,
            Text = name,
            TextColor3 = getColor("Text"),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        
        local path = {}
        for part in settingPath:gmatch("[^%.]+") do
            table.insert(path, part)
        end
        
        local function getValue()
            local current = Settings
            for _, key in ipairs(path) do
                current = current[key]
            end
            return current
        end
        
        local function setValue(val)
            local current = Settings
            for i = 1, #path - 1 do
                current = current[path[i]]
            end
            current[path[#path]] = val
            saveSettings()
        end
        
        local isOn = getValue()
        
        local toggle = Create("TextButton", {
            Parent = container,
            BackgroundColor3 = isOn and Color3.fromRGB(50, 120, 50) or Color3.fromRGB(100, 50, 50),
            BorderSizePixel = 0,
            Position = UDim2.new(1, -55, 0, 2),
            Size = UDim2.new(0, 50, 0, 24),
            Font = Enum.Font.GothamBold,
            Text = isOn and "ON" or "OFF",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 11,
            AutoButtonColor = false,
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = toggle})
        
        toggle.MouseButton1Click:Connect(function()
            isOn = not isOn
            setValue(isOn)
            Tween(toggle, {BackgroundColor3 = isOn and Color3.fromRGB(50, 120, 50) or Color3.fromRGB(100, 50, 50)})
            toggle.Text = isOn and "ON" or "OFF"
        end)
        
        return toggle
    end
    
    local function createDropdown(parent, name, options, settingPath, order)
        local container = Create("Frame", {
            Parent = parent,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 28),
            LayoutOrder = order,
        })
        
        Create("TextLabel", {
            Parent = container,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, 0, 1, 0),
            Font = Enum.Font.Gotham,
            Text = name,
            TextColor3 = getColor("Text"),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        
        local path = {}
        for part in settingPath:gmatch("[^%.]+") do
            table.insert(path, part)
        end
        
        local function getValue()
            local current = Settings
            for _, key in ipairs(path) do
                current = current[key]
            end
            return current
        end
        
        local function setValue(val)
            local current = Settings
            for i = 1, #path - 1 do
                current = current[path[i]]
            end
            current[path[#path]] = val
            saveSettings()
        end
        
        local currentValue = getValue()
        local idx = 1
        for i, v in ipairs(options) do
            if v == currentValue then
                idx = i
                break
            end
        end
        
        local dropdown = Create("TextButton", {
            Parent = container,
            BackgroundColor3 = Color3.fromRGB(45, 45, 58),
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 0, 0, 2),
            Size = UDim2.new(0.5, -5, 0, 24),
            Font = Enum.Font.Gotham,
            Text = "◀ " .. options[idx] .. " ▶",
            TextColor3 = getColor("Text"),
            TextSize = 11,
            AutoButtonColor = false,
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = dropdown})
        
        dropdown.MouseButton1Click:Connect(function()
            idx = idx % #options + 1
            setValue(options[idx])
            dropdown.Text = "◀ " .. options[idx] .. " ▶"
        end)
        
        return dropdown
    end
    
    local function createSlider(parent, name, min, max, settingPath, order)
        local container = Create("Frame", {
            Parent = parent,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 40),
            LayoutOrder = order,
        })
        
        local path = {}
        for part in settingPath:gmatch("[^%.]+") do
            table.insert(path, part)
        end
        
        local function getValue()
            local current = Settings
            for _, key in ipairs(path) do
                current = current[key]
            end
            return current
        end
        
        local function setValue(val)
            local current = Settings
            for i = 1, #path - 1 do
                current = current[path[i]]
            end
            current[path[#path]] = val
            saveSettings()
        end
        
        local currentValue = getValue()
        
        local valueLabel = Create("TextLabel", {
            Parent = container,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 18),
            Font = Enum.Font.Gotham,
            Text = name .. ": " .. currentValue,
            TextColor3 = getColor("Text"),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        
        local sliderBg = Create("Frame", {
            Parent = container,
            BackgroundColor3 = Color3.fromRGB(40, 40, 50),
            Position = UDim2.new(0, 0, 0, 22),
            Size = UDim2.new(1, 0, 0, 14),
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = sliderBg})
        
        local sliderFill = Create("Frame", {
            Parent = sliderBg,
            BackgroundColor3 = getColor("Accent"),
            Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0),
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = sliderFill})
        
        local sliderBtn = Create("TextButton", {
            Parent = sliderBg,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = "",
        })
        
        local dragging = false
        
        sliderBtn.MouseButton1Down:Connect(function()
            dragging = true
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local relX = (input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
                relX = math.clamp(relX, 0, 1)
                local val = math.floor(min + (max - min) * relX)
                setValue(val)
                sliderFill.Size = UDim2.new(relX, 0, 1, 0)
                valueLabel.Text = name .. ": " .. val
            end
        end)
        
        return container
    end
    
    local function createColorPicker(parent, name, colorKey, order)
        local container = Create("Frame", {
            Parent = parent,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 28),
            LayoutOrder = order,
        })
        
        Create("TextLabel", {
            Parent = container,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.6, 0, 1, 0),
            Font = Enum.Font.Gotham,
            Text = name,
            TextColor3 = getColor("Text"),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        
        local colorPreview = Create("Frame", {
            Parent = container,
            BackgroundColor3 = getColor(colorKey),
            Position = UDim2.new(0.6, 0, 0, 4),
            Size = UDim2.new(0, 60, 0, 20),
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = colorPreview})
        Create("UIStroke", {Color = Color3.fromRGB(80, 80, 90), Thickness = 1, Parent = colorPreview})
        
        local rInput = Create("TextBox", {
            Parent = container,
            BackgroundColor3 = Color3.fromRGB(60, 40, 40),
            Position = UDim2.new(0.6, 70, 0, 4),
            Size = UDim2.new(0, 35, 0, 20),
            Font = Enum.Font.Code,
            Text = tostring(Settings.Colors[colorKey][1]),
            TextColor3 = Color3.fromRGB(255, 150, 150),
            TextSize = 10,
            ClearTextOnFocus = true,
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = rInput})
        
        local gInput = Create("TextBox", {
            Parent = container,
            BackgroundColor3 = Color3.fromRGB(40, 60, 40),
            Position = UDim2.new(0.6, 110, 0, 4),
            Size = UDim2.new(0, 35, 0, 20),
            Font = Enum.Font.Code,
            Text = tostring(Settings.Colors[colorKey][2]),
            TextColor3 = Color3.fromRGB(150, 255, 150),
            TextSize = 10,
            ClearTextOnFocus = true,
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = gInput})
        
        local bInput = Create("TextBox", {
            Parent = container,
            BackgroundColor3 = Color3.fromRGB(40, 40, 60),
            Position = UDim2.new(0.6, 150, 0, 4),
            Size = UDim2.new(0, 35, 0, 20),
            Font = Enum.Font.Code,
            Text = tostring(Settings.Colors[colorKey][3]),
            TextColor3 = Color3.fromRGB(150, 150, 255),
            TextSize = 10,
            ClearTextOnFocus = true,
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = bInput})
        
        local function updateColor()
            local r = math.clamp(tonumber(rInput.Text) or 0, 0, 255)
            local g = math.clamp(tonumber(gInput.Text) or 0, 0, 255)
            local b = math.clamp(tonumber(bInput.Text) or 0, 0, 255)
            setColor(colorKey, r, g, b)
            colorPreview.BackgroundColor3 = Color3.fromRGB(r, g, b)
        end
        
        rInput.FocusLost:Connect(updateColor)
        gInput.FocusLost:Connect(updateColor)
        bInput.FocusLost:Connect(updateColor)
        
        return container
    end
    
    local loggingSection = createSection("📝 Logging Options", 1)
    createToggle(loggingSection, "Enable Spy", "Logging.Enabled", 1)
    createToggle(loggingSection, "Log Remotes", "Logging.LogRemotes", 2)
    createToggle(loggingSection, "Log Signals", "Logging.LogSignals", 3)
    createToggle(loggingSection, "Log HTTP Requests", "Logging.LogRequests", 4)
    createToggle(loggingSection, "Log Audios", "Logging.LogAudios", 5)
    createToggle(loggingSection, "Log Animations", "Logging.LogAnimations", 6)
    createToggle(loggingSection, "Log Bindables", "Logging.LogBindables", 7)
    createToggle(loggingSection, "Log RobloxReplicatedStorage", "Logging.LogRobloxReplicatedStorage", 8)
    createToggle(loggingSection, "Log Checkcaller Calls", "Logging.LogCheckcaller", 9)
    createToggle(loggingSection, "LocalPlayer Only", "Logging.LogLocalPlayerOnly", 10)
    
    local filterSection = createSection("🔍 Filters", 2)
    createToggle(filterSection, "Filter Spammy", "Filters.FilterSpammy", 1)
    createToggle(filterSection, "Auto-Ignore Spam", "Filters.IgnoreSpammyLogs", 2)
    createSlider(filterSection, "Spam Threshold", 1, 20, "Filters.SpamThreshold", 3)
    createSlider(filterSection, "Spam Window (sec)", 1, 10, "Filters.SpamTimeWindow", 4)
    
    local displaySection = createSection("🖥️ Display", 3)
    createSlider(displaySection, "Max Logs", 100, 2000, "Display.MaxLogs", 1)
    createDropdown(displaySection, "Path Style", {"Auto", "WaitForChild", "FindFirstChild", "Index", "GetChildren"}, "Display.PathStyle", 2)
    createToggle(displaySection, "Enable Animations", "Display.EnableAnimations", 3)
    createToggle(displaySection, "Show Timestamps", "Display.ShowTimestamps", 4)
    createToggle(displaySection, "Group Similar Logs", "Display.GroupSimilarLogs", 5)
    
    local themeSection = createSection("🎨 Theme Colors", 4)
    createDropdown(themeSection, "Theme Preset", {"Dark", "Light", "Midnight", "Forest"}, "Theme", 1)
    createColorPicker(themeSection, "Background", "Background", 2)
    createColorPicker(themeSection, "Accent", "Accent", 3)
    createColorPicker(themeSection, "Text", "Text", 4)
    createColorPicker(themeSection, "Remotes", "Remotes", 5)
    createColorPicker(themeSection, "Signals", "Signals", 6)
    createColorPicker(themeSection, "Requests", "Requests", 7)
    
    local teleportSection = createSection("🚀 Teleport", 5)
    
    local teleportInput = Create("TextBox", {
        Parent = teleportSection,
        BackgroundColor3 = Color3.fromRGB(40, 40, 50),
        Size = UDim2.new(1, 0, 0, 60),
        Font = Enum.Font.Code,
        Text = Settings.TeleportScript,
        TextColor3 = getColor("Text"),
        PlaceholderText = "-- Script to queue on teleport...",
        PlaceholderColor3 = getColor("TextDim"),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ClearTextOnFocus = false,
        MultiLine = true,
        LayoutOrder = 1,
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = teleportInput})
    Create("UIPadding", {Parent = teleportInput, PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8)})
    
    teleportInput.FocusLost:Connect(function()
        Settings.TeleportScript = teleportInput.Text
        saveSettings()
    end)
    
    local queueBtn = Create("TextButton", {
        Parent = teleportSection,
        BackgroundColor3 = Color3.fromRGB(70, 50, 100),
        Size = UDim2.new(1, 0, 0, 32),
        Font = Enum.Font.GothamBold,
        Text = "Queue Teleport Script",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 12,
        AutoButtonColor = false,
        LayoutOrder = 2,
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = queueBtn})
    
    queueBtn.MouseButton1Click:Connect(function()
        if queueteleport and Settings.TeleportScript ~= "" then
            queueteleport(Settings.TeleportScript)
            queueBtn.Text = "✓ Queued!"
            queueBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
            task.delay(2, function()
                queueBtn.Text = "Queue Teleport Script"
                queueBtn.BackgroundColor3 = Color3.fromRGB(70, 50, 100)
            end)
        else
            queueBtn.Text = "Not Available"
            queueBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
            task.delay(2, function()
                queueBtn.Text = "Queue Teleport Script"
                queueBtn.BackgroundColor3 = Color3.fromRGB(70, 50, 100)
            end)
        end
    end)
    
    local actionsSection = createSection("⚡ Actions", 6)
    
    local clearAllBtn = Create("TextButton", {
        Parent = actionsSection,
        BackgroundColor3 = Color3.fromRGB(100, 50, 50),
        Size = UDim2.new(1, 0, 0, 32),
        Font = Enum.Font.GothamBold,
        Text = "Clear All Logs",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 12,
        AutoButtonColor = false,
        LayoutOrder = 1,
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = clearAllBtn})
    
    clearAllBtn.MouseButton1Click:Connect(function()
        for tabName in pairs(Logs) do
            Logs[tabName] = {}
            LogFrames[tabName] = {}
            LogGroups[tabName] = {}
            GroupFrames[tabName] = {}
            LayoutOrders[tabName] = 999999999
            
            if TabData[tabName] and TabData[tabName].LogScroll then
                for _, child in pairs(TabData[tabName].LogScroll:GetChildren()) do
                    if child:IsA("Frame") or child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
                if TabData[tabName].CountLabel then
                    TabData[tabName].CountLabel.Text = "0"
                end
            end
        end
        Statistics = {
            TotalCalls = 0,
            CallsByType = {},
            CallsByName = {},
            DataTransferred = 0,
            StartTime = tick(),
        }
        Selected = nil
        clearAllBtn.Text = "✓ Cleared!"
        task.delay(1.5, function() clearAllBtn.Text = "Clear All Logs" end)
    end)
    
    local resetSettingsBtn = Create("TextButton", {
        Parent = actionsSection,
        BackgroundColor3 = Color3.fromRGB(80, 60, 60),
        Size = UDim2.new(1, 0, 0, 32),
        Font = Enum.Font.GothamBold,
        Text = "Reset Settings to Default",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 12,
        AutoButtonColor = false,
        LayoutOrder = 2,
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = resetSettingsBtn})
    
    resetSettingsBtn.MouseButton1Click:Connect(function()
        Settings = deepCopy(DefaultSettings)
        saveSettings()
        resetSettingsBtn.Text = "✓ Reset! (Reload UI)"
        task.delay(2, function() resetSettingsBtn.Text = "Reset Settings to Default" end)
    end)
    
    local clearBlacklistBtn = Create("TextButton", {
        Parent = actionsSection,
        BackgroundColor3 = Color3.fromRGB(70, 70, 50),
        Size = UDim2.new(1, 0, 0, 32),
        Font = Enum.Font.GothamBold,
        Text = "Clear Blacklist/Blocklist",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 12,
        AutoButtonColor = false,
        LayoutOrder = 3,
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = clearBlacklistBtn})
    
    clearBlacklistBtn.MouseButton1Click:Connect(function()
        Settings.Blacklist = {}
        Settings.Blocklist = {}
        SpammySignals = {}
        saveSettings()
        clearBlacklistBtn.Text = "✓ Cleared!"
        task.delay(1.5, function() clearBlacklistBtn.Text = "Clear Blacklist/Blocklist" end)
    end)
    
    local infoSection = createSection("ℹ️ Info", 7)
    
    Create("TextLabel", {
        Parent = infoSection,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 80),
        Font = Enum.Font.Gotham,
        Text = "UnifiedSpy v3.0\n\nAdvanced Remote/Signal/Request Logger\nwith API Dump caching, Syntax Highlighting,\nBuilt-in Executor, and Debug Tools.\n\nSettings auto-save to: UnifiedSpy/Settings.json",
        TextColor3 = getColor("TextDim"),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        LayoutOrder = 1,
    })
    
    TabData["Settings"] = {
        Content = content,
        IsSettings = true,
    }
    
    return content
end

local function createTab(tabDef)
    local tabName = tabDef.Name
    local color = getColor(tabDef.ColorKey)
    local icon = tabDef.Icon
    
    local tabBtn = Create("TextButton", {
        Parent = TabListFrame,
        BackgroundColor3 = Color3.fromRGB(38, 38, 48),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 44),
        Font = Enum.Font.Gotham,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = tabDef.Order,
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = tabBtn})
    
    local indicator = Create("Frame", {
        Parent = tabBtn,
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.15, 0),
        Size = UDim2.new(0, 4, 0.7, 0),
        Visible = false,
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = indicator})
    
    Create("TextLabel", {
        Parent = tabBtn,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0, 24, 1, 0),
        Font = Enum.Font.GothamBlack,
        Text = icon,
        TextColor3 = color,
        TextSize = 16,
    })
    
    local nameLabel = Create("TextLabel", {
        Parent = tabBtn,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 44, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = tabName,
        TextColor3 = getColor("TextDim"),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local tabCount = Create("TextLabel", {
        Parent = tabBtn,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -38, 0, 0),
        Size = UDim2.new(0, 32, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = tabDef.IsSettings and "" or "0",
        TextColor3 = color,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    
    if tabDef.IsSettings then
        createSettingsTab()
    else
        createLogTab(tabDef)
    end
    
    if TabData[tabName] then
        TabData[tabName].Button = tabBtn
        TabData[tabName].Indicator = indicator
        TabData[tabName].NameLabel = nameLabel
        TabData[tabName].TabCount = tabCount
    end
    
    tabBtn.MouseEnter:Connect(function()
        if CurrentTab ~= tabName then
            Tween(tabBtn, {BackgroundColor3 = Color3.fromRGB(48, 48, 60)})
        end
    end)
    
    tabBtn.MouseLeave:Connect(function()
        if CurrentTab ~= tabName then
            Tween(tabBtn, {BackgroundColor3 = Color3.fromRGB(38, 38, 48)})
        end
    end)
    
    tabBtn.MouseButton1Click:Connect(function()
        switchTab(tabName)
    end)
end

function switchTab(tabName)
    if not TabData[tabName] then return end
    
    for name, data in pairs(TabData) do
        if data.Content and data.Button then
            if name == tabName then
                data.Content.Visible = true
                if data.Indicator then data.Indicator.Visible = true end
                Tween(data.Button, {BackgroundColor3 = Color3.fromRGB(55, 60, 85)})
                if data.NameLabel then
                    Tween(data.NameLabel, {TextColor3 = getColor("Text")})
                end
            else
                data.Content.Visible = false
                if data.Indicator then data.Indicator.Visible = false end
                Tween(data.Button, {BackgroundColor3 = Color3.fromRGB(38, 38, 48)})
                if data.NameLabel then
                    Tween(data.NameLabel, {TextColor3 = getColor("TextDim")})
                end
            end
        end
    end
    
    CurrentTab = tabName
end

for _, tabDef in ipairs(TabDefinitions) do
    createTab(tabDef)
end
switchTab("Remotes")

local function updateTabCount(tabName)
    if TabData[tabName] then
        local count = #Logs[tabName]
        if TabData[tabName].CountLabel then
            TabData[tabName].CountLabel.Text = tostring(count)
        end
        if TabData[tabName].TabCount then
            TabData[tabName].TabCount.Text = tostring(count)
        end
    end
end

local function matchesSearch(logData)
    if SearchQuery == "" then return true end
    local name = (logData.Name or ""):lower()
    local typeName = (logData.Type or ""):lower()
    return name:find(SearchQuery, 1, true) or typeName:find(SearchQuery, 1, true)
end

local function createLogEntry(tabName, logData)
    if not matchesSearch(logData) then return nil end
    
    if LayoutOrders[tabName] < 1 then LayoutOrders[tabName] = 999999999 end
    
    local data = TabData[tabName]
    if not data or not data.LogScroll then return nil end
    
    local color = data.Color or getColor("Accent")
    local groupKey = logData.Name .. "_" .. (logData.Type or "")
    
    if Settings.Display.GroupSimilarLogs and LogGroups[tabName][groupKey] then
        local group = LogGroups[tabName][groupKey]
        group.count = group.count + 1
        group.lastData = logData
        
        if GroupFrames[tabName][groupKey] then
            local countLabel = GroupFrames[tabName][groupKey]:FindFirstChild("GroupCount")
            if countLabel then
                countLabel.Text = "#" .. group.count
            end
        end
        
        table.insert(Logs[tabName], 1, logData)
        if #Logs[tabName] > Settings.Display.MaxLogs then
            table.remove(Logs[tabName])
        end
        updateTabCount(tabName)
        return nil
    end
    
    local entry = Create("Frame", {
        Parent = data.LogScroll,
        BackgroundColor3 = Color3.fromRGB(40, 40, 52),
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = LayoutOrders[tabName],
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = entry})
    
    local mainContent = Create("Frame", {
        Parent = entry,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 38),
    })
    
    Create("Frame", {
        Parent = mainContent,
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 0.75, 0),
        Position = UDim2.new(0, 0, 0.125, 0),
    })
    
    local icons = {
        RemoteEvent = "📡",
        RemoteFunction = "📞",
        UnreliableRemoteEvent = "📶",
        BindableEvent = "🔗",
        BindableFunction = "🔄",
        Signal = "⚡",
        Audio = "🔊",
        Animation = "🎬",
        HttpRequest = "🌐",
        SystemRemote = "⚙️",
    }
    
    Create("TextLabel", {
        Parent = mainContent,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0, 22, 1, 0),
        Font = Enum.Font.Gotham,
        Text = icons[logData.Type] or "•",
        TextColor3 = color,
        TextSize = 14,
    })
    
    Create("TextLabel", {
        Parent = mainContent,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 32, 0, 3),
        Size = UDim2.new(1, -70, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = logData.Name or "Unknown",
        TextColor3 = Color3.fromRGB(235, 235, 240),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    
    Create("TextLabel", {
        Parent = mainContent,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 32, 0, 19),
        Size = UDim2.new(1, -70, 0, 14),
        Font = Enum.Font.Gotham,
        Text = logData.SubText or logData.Type or "",
        TextColor3 = Color3.fromRGB(130, 130, 145),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    
    if Settings.Display.GroupSimilarLogs then
        local groupCountLabel = Create("TextLabel", {
            Name = "GroupCount",
            Parent = mainContent,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -38, 0, 0),
            Size = UDim2.new(0, 32, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = "#1",
            TextColor3 = color,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Right,
        })
        
        LogGroups[tabName][groupKey] = {count = 1, lastData = logData}
        GroupFrames[tabName][groupKey] = entry
    end
    
    if logData.IsLocalPlayer then
        Create("TextLabel", {
            Parent = mainContent,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -55, 0, 12),
            Size = UDim2.new(0, 20, 0, 14),
            Font = Enum.Font.GothamBold,
            Text = "LP",
            TextColor3 = Color3.fromRGB(100, 200, 255),
            TextSize = 9,
        })
    end
    
    if logData.Breakpoint then
        Create("TextLabel", {
            Parent = mainContent,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -75, 0, 12),
            Size = UDim2.new(0, 20, 0, 14),
            Font = Enum.Font.GothamBold,
            Text = "🔴",
            TextSize = 10,
        })
    end
    
    local btn = Create("TextButton", {
        Parent = mainContent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
    })
    
    btn.MouseEnter:Connect(function()
        if Selected ~= logData then
            Tween(entry, {BackgroundColor3 = Color3.fromRGB(50, 50, 65)})
        end
    end)
    
    btn.MouseLeave:Connect(function()
        if Selected ~= logData then
            Tween(entry, {BackgroundColor3 = Color3.fromRGB(40, 40, 52)})
        end
    end)
    
    btn.MouseButton1Click:Connect(function()
        if Selected and Selected.Entry then
            Tween(Selected.Entry, {BackgroundColor3 = Color3.fromRGB(40, 40, 52)})
        end
        
        Selected = logData
        Selected.Entry = entry
        Selected.TabName = tabName
        
        Tween(entry, {BackgroundColor3 = Color3.fromRGB(55, 70, 110)})
        
        logData.Script = logData.Script or generateScript(logData)
        if data.UpdateCode then
            data.UpdateCode(logData.Script)
        end
    end)
    
    logData.Entry = entry
    LayoutOrders[tabName] = LayoutOrders[tabName] - 1
    
    table.insert(Logs[tabName], 1, logData)
    table.insert(LogFrames[tabName], 1, {entry = entry, data = logData})
    
    while #Logs[tabName] > Settings.Display.MaxLogs do
        local oldest = table.remove(LogFrames[tabName])
        if oldest and oldest.entry then
            if oldest.data then
                local oldKey = oldest.data.Name .. "_" .. (oldest.data.Type or "")
                if LogGroups[tabName][oldKey] and LogGroups[tabName][oldKey].count <= 1 then
                    LogGroups[tabName][oldKey] = nil
                    GroupFrames[tabName][oldKey] = nil
                end
            end
            oldest.entry:Destroy()
        end
        table.remove(Logs[tabName])
    end
    
    updateTabCount(tabName)
    return entry
end

local function logRemote(remote, method, args, blocked)
    if not Settings.Logging.Enabled or not Settings.Logging.LogRemotes then return end
    if not Settings.Logging.LogCheckcaller and checkcaller() then return end
    
    local name = remote.Name
    local remoteType = remote.ClassName
    local key = name .. "_" .. remoteType
    
    if Settings.Blacklist[name] or Settings.Blacklist[tostring(remote)] then return end
    if SpammySignals[key] then return end
    if isSpammy(key) then return end
    
    local dataSize = estimateDataSize(args)
    
    local logData = {
        Type = remoteType,
        Name = name,
        SubText = method .. " | " .. #(args or {}) .. " args | ~" .. dataSize .. "B",
        Remote = remote,
        Args = deepClone(args or {}),
        Method = method,
        Blocked = blocked or Settings.Blocklist[name] or Settings.Blocklist[tostring(remote)],
        Timestamp = os.time(),
        IsLocalPlayer = true,
        DataSize = dataSize,
    }
    
    pcall(function() logData.Source = getcallingscript() end)
    
    local hit, bp = checkBreakpoint(logData)
    if hit then
        logData.Breakpoint = bp
        warn("[UnifiedSpy] Breakpoint hit:", name)
    end
    
    updateStatistics(logData)
    
    task.defer(function()
        createLogEntry("Remotes", logData)
    end)
    
    return logData.Blocked
end

local function logBindable(bindable, method, args)
    if not Settings.Logging.Enabled or not Settings.Logging.LogBindables then return end
    
    local name = bindable.Name
    local bindableType = bindable.ClassName
    local key = "bindable_" .. name .. "_" .. bindableType
    
    if Settings.Blacklist[name] then return end
    if SpammySignals[key] then return end
    if isSpammy(key) then return end
    
    local logData = {
        Type = bindableType,
        Name = name,
        SubText = method .. " | " .. #(args or {}) .. " args",
        Remote = bindable,
        Args = deepClone(args or {}),
        Method = method,
        Timestamp = os.time(),
        IsLocalPlayer = true,
    }
    
    updateStatistics(logData)
    
    task.defer(function()
        createLogEntry("Bindables", logData)
    end)
end

local function logSystemRemote(remote, method, args)
    if not Settings.Logging.Enabled or not Settings.Logging.LogRobloxReplicatedStorage then return end
    
    local name = remote.Name
    local remoteType = remote.ClassName
    local key = "system_" .. name
    
    if SpammySignals[key] then return end
    if isSpammy(key) then return end
    
    local logData = {
        Type = "SystemRemote",
        RemoteType = remoteType,
        Name = "[RRS] " .. name,
        SubText = method .. " | " .. remoteType,
        Remote = remote,
        Args = deepClone(args or {}),
        Method = method,
        Timestamp = os.time(),
        IsLocalPlayer = true,
    }
    
    updateStatistics(logData)
    
    task.defer(function()
        createLogEntry("System", logData)
    end)
end

local function logSignal(instance, signalName, args, connFunc)
    if not Settings.Logging.Enabled or not Settings.Logging.LogSignals then return end
    if Settings.Logging.LogLocalPlayerOnly and not isFromLocalPlayer(instance) then return end
    
    local key = tostring(instance) .. "." .. signalName
    
    if Settings.Blacklist[key] or Settings.Blacklist[signalName] then return end
    if SpammySignals[key] then return end
    if isSpammy(key) then return end
    
    local funcInfo = nil
    if connFunc then
        funcInfo = getFunctionInfo(connFunc)
    end
    
    local logData = {
        Type = "Signal",
        Name = signalName,
        SubText = instance.ClassName .. " | " .. (instance.Name or "?"),
        SignalName = signalName,
        Instance = instance,
        Args = deepClone(args or {}),
        FuncInfo = funcInfo,
        Blocked = Settings.Blocklist[key] or Settings.Blocklist[signalName],
        Timestamp = os.time(),
        IsLocalPlayer = isFromLocalPlayer(instance),
    }
    
    local hit, bp = checkBreakpoint(logData)
    if hit then
        logData.Breakpoint = bp
    end
    
    updateStatistics(logData)
    
    task.defer(function()
        createLogEntry("Signals", logData)
    end)
    
    return logData.Blocked
end

local function logHttpRequest(options)
    if not Settings.Logging.Enabled or not Settings.Logging.LogRequests then return end
    
    local url = type(options) == "table" and options.Url or tostring(options)
    local method = type(options) == "table" and options.Method or "GET"
    local key = "http_" .. url:sub(1, 50)
    
    if SpammySignals[key] then return end
    if isSpammy(key) then return end
    
    local dataSize = estimateDataSize(options)
    
    local logData = {
        Type = "HttpRequest",
        Name = url:sub(1, 50) .. (#url > 50 and "..." or ""),
        SubText = method .. " | ~" .. dataSize .. "B",
        Request = type(options) == "table" and deepClone(options) or {Url = url},
        Timestamp = os.time(),
        IsLocalPlayer = true,
        DataSize = dataSize,
    }
    
    updateStatistics(logData)
    
    task.defer(function()
        createLogEntry("Requests", logData)
    end)
end

local function logAudio(sound)
    if not Settings.Logging.Enabled or not Settings.Logging.LogAudios then return end
    if not sound:IsA("Sound") then return end
    if TrackedSounds[sound] then return end
    if Settings.Logging.LogLocalPlayerOnly and not isFromLocalPlayer(sound) then return end
    
    local soundId = sound.SoundId
    if soundId == "" then return end
    
    local ignoredSounds = {
        "rbxasset://sounds/action_get_up.mp3",
        "rbxasset://sounds/uuhhh.mp3",
        "rbxasset://sounds/action_falling.mp3",
        "rbxasset://sounds/action_jump.mp3",
        "rbxasset://sounds/action_jump_land.mp3",
        "rbxasset://sounds/impact_water.mp3",
        "rbxasset://sounds/action_swim.mp3",
        "rbxasset://sounds/action_footsteps_plastic.mp3",
    }
    for _, v in ipairs(ignoredSounds) do
        if soundId == v then return end
    end
    
    TrackedSounds[sound] = true
    
    local id = soundId:match("%d+") or soundId
    local name = sound.Name
    
    pcall(function()
        local info = MarketplaceService:GetProductInfo(tonumber(id))
        if info and info.Name then name = info.Name end
    end)
    
    local logData = {
        Type = "Audio",
        Name = name,
        SubText = "ID: " .. id .. " | Vol: " .. string.format("%.1f", sound.Volume),
        SoundId = soundId,
        Sound = sound,
        Volume = sound.Volume,
        Timestamp = os.time(),
        IsLocalPlayer = isFromLocalPlayer(sound),
    }
    
    updateStatistics(logData)
    
    task.defer(function()
        createLogEntry("Audios", logData)
    end)
end

local function logAnimation(animTrack)
    if not Settings.Logging.Enabled or not Settings.Logging.LogAnimations then return end
    if not animTrack or not animTrack.Animation then return end
    
    local anim = animTrack.Animation
    local animId = anim.AnimationId
    if animId == "" then return end
    
    local ignoredAnims = {"507768375", "180435571", "180435792"}
    for _, v in ipairs(ignoredAnims) do
        if animId:find(v) then return end
    end
    
    local key = animId
    if TrackedAnimations[key] and tick() - TrackedAnimations[key] < 0.5 then return end
    TrackedAnimations[key] = tick()
    
    local id = animId:match("%d+") or animId
    local name = anim.Name
    
    pcall(function()
        local info = MarketplaceService:GetProductInfo(tonumber(id))
        if info and info.Name then name = info.Name end
    end)
    
    local logData = {
        Type = "Animation",
        Name = name,
        SubText = "ID: " .. id,
        AnimationId = animId,
        Animation = anim,
        Timestamp = os.time(),
        IsLocalPlayer = true,
    }
    
    updateStatistics(logData)
    
    task.defer(function()
        createLogEntry("Animations", logData)
    end)
end

local function hookSignal(instance, signalName)
    if not getconnections then return end
    
    local key = tostring(instance) .. "." .. signalName
    if HookedSignals[key] then return end
    
    local ok, signal = pcall(function() return instance[signalName] end)
    if not ok or not signal or typeof(signal) ~= "RBXScriptSignal" then return end
    
    HookedSignals[key] = true
    
    local conns = {}
    pcall(function() conns = getconnections(signal) end)
    
    for _, conn in pairs(conns) do
        if conn and conn.Function then
            local origFunc = conn.Function
            local wasEnabled = conn.Enabled
            
            pcall(function() conn:Disable() end)
            
            local newConn = signal:Connect(function(...)
                local args = {...}
                local blocked = logSignal(instance, signalName, args, origFunc)
                if blocked then return end
                return origFunc(...)
            end)
            
            table.insert(HookedConnections, {
                Connection = newConn,
                Original = conn,
                WasEnabled = wasEnabled,
                Key = key,
            })
        end
    end
    
    local catchConn = signal:Connect(function(...)
        if #conns == 0 then
            logSignal(instance, signalName, {...}, nil)
        end
    end)
    table.insert(HookedConnections, {Connection = catchConn, Key = key})
end

local function hookRemotes()
    local testRE = Instance.new("RemoteEvent")
    local testRF = Instance.new("RemoteFunction")
    local testURE = nil
    pcall(function() testURE = Instance.new("UnreliableRemoteEvent") end)
    local testBE = Instance.new("BindableEvent")
    local testBF = Instance.new("BindableFunction")
    
    OriginalFunctions.FireServer = testRE.FireServer
    OriginalFunctions.InvokeServer = testRF.InvokeServer
    if testURE then OriginalFunctions.UnreliableFireServer = testURE.FireServer end
    OriginalFunctions.BindableFire = testBE.Fire
    OriginalFunctions.BindableInvoke = testBF.Invoke
    
    testRE:Destroy()
    testRF:Destroy()
    if testURE then testURE:Destroy() end
    testBE:Destroy()
    testBF:Destroy()
    
    if hookfunction then
        pcall(function()
            hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
                if typeof(self) == "Instance" and self:IsA("RemoteEvent") then
                    if logRemote(self, "FireServer", {...}) then return end
                end
                return OriginalFunctions.FireServer(self, ...)
            end))
        end)
        
        pcall(function()
            hookfunction(Instance.new("RemoteFunction").InvokeServer, newcclosure(function(self, ...)
                if typeof(self) == "Instance" and self:IsA("RemoteFunction") then
                    if logRemote(self, "InvokeServer", {...}) then return end
                end
                return OriginalFunctions.InvokeServer(self, ...)
            end))
        end)
        
        if OriginalFunctions.UnreliableFireServer then
            pcall(function()
                hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, newcclosure(function(self, ...)
                    if typeof(self) == "Instance" and self:IsA("UnreliableRemoteEvent") then
                        if logRemote(self, "FireServer", {...}) then return end
                    end
                    return OriginalFunctions.UnreliableFireServer(self, ...)
                end))
            end)
        end
        
        pcall(function()
            hookfunction(Instance.new("BindableEvent").Fire, newcclosure(function(self, ...)
                if typeof(self) == "Instance" and self:IsA("BindableEvent") then
                    logBindable(self, "Fire", {...})
                end
                return OriginalFunctions.BindableFire(self, ...)
            end))
        end)
        
        pcall(function()
            hookfunction(Instance.new("BindableFunction").Invoke, newcclosure(function(self, ...)
                if typeof(self) == "Instance" and self:IsA("BindableFunction") then
                    logBindable(self, "Invoke", {...})
                end
                return OriginalFunctions.BindableInvoke(self, ...)
            end))
        end)
    end
    
    if hookmetamethod and getnamecallmethod then
        pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if method and typeof(self) == "Instance" then
                    local lm = method:lower()
                    if lm == "fireserver" then
                        if self:IsA("RemoteEvent") or self:IsA("UnreliableRemoteEvent") then
                            if logRemote(self, method, {...}) then return end
                        end
                    elseif lm == "invokeserver" and self:IsA("RemoteFunction") then
                        if logRemote(self, method, {...}) then return end
                    elseif lm == "fire" and self:IsA("BindableEvent") then
                        logBindable(self, method, {...})
                    elseif lm == "invoke" and self:IsA("BindableFunction") then
                        logBindable(self, method, {...})
                    end
                end
                return oldNamecall(self, ...)
            end))
            OriginalFunctions.Namecall = oldNamecall
        end)
    end
end

local function hookHttp()
    if not request or not hookfunction then return end
    OriginalFunctions.Request = request
    pcall(function()
        hookfunction(request, newcclosure(function(opts)
            logHttpRequest(opts)
            return OriginalFunctions.Request(opts)
        end))
    end)
end

local function hookRobloxReplicatedStorage()
    if not RobloxReplicatedStorage then return end
    
    pcall(function()
        for _, child in pairs(RobloxReplicatedStorage:GetChildren()) do
            if child:IsA("RemoteEvent") then
                Connections["RRS_" .. child.Name] = child.OnClientEvent:Connect(function(...)
                    logSystemRemote(child, "OnClientEvent", {...})
                end)
            elseif child:IsA("RemoteFunction") then
                local oldCallback = child.OnClientInvoke
                child.OnClientInvoke = function(...)
                    logSystemRemote(child, "OnClientInvoke", {...})
                    if oldCallback then
                        return oldCallback(...)
                    end
                end
            end
        end
        
        Connections.RRSChildAdded = RobloxReplicatedStorage.ChildAdded:Connect(function(child)
            if child:IsA("RemoteEvent") then
                Connections["RRS_" .. child.Name] = child.OnClientEvent:Connect(function(...)
                    logSystemRemote(child, "OnClientEvent", {...})
                end)
            end
        end)
    end)
end

local function hookSignals()
    local function scanInstance(inst)
        if Settings.Logging.LogLocalPlayerOnly and not isFromLocalPlayer(inst) then return end
        
        pcall(function()
            local className = inst.ClassName
            local signals = ClassSignals[className]
            if signals then
                for _, sig in ipairs(signals) do
                    if sig.Security == "None" or sig.Security == nil then
                        hookSignal(inst, sig.Name)
                    end
                end
            end
            
            if inst:IsA("Humanoid") then
                hookSignal(inst, "Died")
                hookSignal(inst, "StateChanged")
                hookSignal(inst, "Running")
                hookSignal(inst, "Jumping")
                hookSignal(inst, "HealthChanged")
                hookSignal(inst, "MoveToFinished")
            elseif inst:IsA("ClickDetector") then
--                hookSignal
                hookSignal(inst, "MouseClick")
                hookSignal(inst, "MouseHoverEnter")
                hookSignal(inst, "MouseHoverLeave")
                hookSignal(inst, "RightMouseClick")
            elseif inst:IsA("ProximityPrompt") then
                hookSignal(inst, "Triggered")
                hookSignal(inst, "TriggerEnded")
                hookSignal(inst, "PromptShown")
                hookSignal(inst, "PromptHidden")
            elseif inst:IsA("Tool") then
                hookSignal(inst, "Activated")
                hookSignal(inst, "Deactivated")
                hookSignal(inst, "Equipped")
                hookSignal(inst, "Unequipped")
            elseif inst:IsA("GuiButton") then
                hookSignal(inst, "MouseButton1Click")
                hookSignal(inst, "MouseButton1Down")
                hookSignal(inst, "MouseButton1Up")
                hookSignal(inst, "MouseButton2Click")
                hookSignal(inst, "Activated")
            elseif inst:IsA("TextBox") then
                hookSignal(inst, "FocusLost")
                hookSignal(inst, "Focused")
            elseif inst:IsA("ValueBase") then
                hookSignal(inst, "Changed")
            elseif inst:IsA("BindableEvent") then
                hookSignal(inst, "Event")
            elseif inst:IsA("TouchTransmitter") or inst:IsA("BasePart") then
                hookSignal(inst, "Touched")
                hookSignal(inst, "TouchEnded")
            elseif inst:IsA("Player") then
                hookSignal(inst, "Chatted")
                hookSignal(inst, "CharacterAdded")
                hookSignal(inst, "CharacterRemoving")
            end
        end)
    end
    
    if Settings.Logging.LogLocalPlayerOnly then
        if Players.LocalPlayer and Players.LocalPlayer.Character then
            for _, desc in pairs(Players.LocalPlayer.Character:GetDescendants()) do
                task.defer(scanInstance, desc)
            end
        end
        if Players.LocalPlayer then
            for _, desc in pairs(Players.LocalPlayer:GetDescendants()) do
                task.defer(scanInstance, desc)
            end
        end
    else
        for _, desc in pairs(game:GetDescendants()) do
            task.defer(scanInstance, desc)
        end
    end
    
    Connections.DescendantAdded = game.DescendantAdded:Connect(function(desc)
        task.defer(scanInstance, desc)
    end)
    
    if Players.LocalPlayer then
        Connections.CharacterAdded = Players.LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            for _, desc in pairs(char:GetDescendants()) do
                task.defer(scanInstance, desc)
            end
            Connections.CharDescAdded = char.DescendantAdded:Connect(function(desc)
                task.defer(scanInstance, desc)
            end)
        end)
    end
end

local function hookAudios()
    local function onSoundAdded(sound)
        if sound:IsA("Sound") then
            local conn
            conn = sound:GetPropertyChangedSignal("Playing"):Connect(function()
                if sound.Playing then
                    task.defer(logAudio, sound)
                end
            end)
            table.insert(Connections, conn)
            
            if sound.Playing then
                task.defer(logAudio, sound)
            end
        end
    end
    
    Connections.AudioAdded = game.DescendantAdded:Connect(function(desc)
        if desc:IsA("Sound") then
            onSoundAdded(desc)
        end
    end)
    
    for _, snd in pairs(game:GetDescendants()) do
        if snd:IsA("Sound") then
            onSoundAdded(snd)
        end
    end
end

local function hookAnimations()
    local lp = Players.LocalPlayer
    if not lp then return end
    
    local function trackChar(char)
        if not char then return end
        
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then return end
        
        local animator = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 5)
        if animator then
            Connections.AnimatorPlayed = animator.AnimationPlayed:Connect(function(track)
                task.defer(logAnimation, track)
            end)
        end
        
        Connections.HumAnimPlayed = hum.AnimationPlayed:Connect(function(track)
            task.defer(logAnimation, track)
        end)
    end
    
    if lp.Character then
        trackChar(lp.Character)
    end
    
    Connections.CharAddedAnim = lp.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        trackChar(char)
    end)
end

local dragging, resizing = false, false
local dragStart, startPos, startSize

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = UserInputService:GetMouseLocation()
        local relX = mousePos.X - TopBar.AbsolutePosition.X
        if relX < TopBar.AbsoluteSize.X - 130 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end
end)

TopBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local ResizeHandle = Create("TextButton", {
    Parent = MainFrame,
    BackgroundColor3 = Color3.fromRGB(60, 60, 70),
    Position = UDim2.new(1, -18, 1, -18),
    Size = UDim2.new(0, 16, 0, 16),
    Text = "◢",
    TextColor3 = Color3.fromRGB(120, 120, 130),
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    ZIndex = 10,
})
Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = ResizeHandle})

ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = true
        dragStart = input.Position
        startSize = MainFrame.Size
    end
end)

ResizeHandle.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if dragging then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
            if Settings.Display.EnableAnimations then
                TweenService:Create(MainFrame, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
                    Position = newPos
                }):Play()
            else
                MainFrame.Position = newPos
            end
        elseif resizing then
            local delta = input.Position - dragStart
            local newWidth = math.max(800, startSize.X.Offset + delta.X)
            local newHeight = math.max(500, startSize.Y.Offset + delta.Y)
            MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
    end
end)

local minimized = false
local savedSize = MainFrame.Size

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        savedSize = MainFrame.Size
        Tween(MainFrame, {Size = UDim2.new(0, MainFrame.Size.X.Offset, 0, 42)}, 0.25)
        ContentFrame.Visible = false
        ResizeHandle.Visible = false
        MinBtn.Text = "+"
    else
        ContentFrame.Visible = true
        ResizeHandle.Visible = true
        Tween(MainFrame, {Size = savedSize}, 0.25)
        MinBtn.Text = "−"
    end
end)

local sidebarHidden = false

MaxBtn.MouseButton1Click:Connect(function()
    sidebarHidden = not sidebarHidden
    if sidebarHidden then
        Tween(Sidebar, {Size = UDim2.new(0, 0, 1, 0)}, 0.2)
        Tween(MainPanel, {Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0)}, 0.2)
        MaxBtn.Text = "◧"
    else
        Tween(Sidebar, {Size = UDim2.new(0, 175, 1, 0)}, 0.2)
        Tween(MainPanel, {Position = UDim2.new(0, 175, 0, 0), Size = UDim2.new(1, -175, 1, 0)}, 0.2)
        MaxBtn.Text = "□"
    end
end)

local spyEnabled = true

TitleBtn.MouseButton1Click:Connect(function()
    spyEnabled = not spyEnabled
    Settings.Logging.Enabled = spyEnabled
    saveSettings()
    
    if spyEnabled then
        Tween(TitleBtn, {TextColor3 = getColor("Accent")})
        StatusLabel.Text = "ACTIVE"
        StatusLabel.TextColor3 = getColor("Success")
    else
        Tween(TitleBtn, {TextColor3 = getColor("Error")})
        StatusLabel.Text = "PAUSED"
        StatusLabel.TextColor3 = getColor("Error")
    end
end)

local function shutdown()
    Running = false
    getgenv().UnifiedSpyExecuted = false
    
    for name, conn in pairs(Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end
    
    for _, data in pairs(HookedConnections) do
        if data.Connection then
            pcall(function() data.Connection:Disconnect() end)
        end
        if data.Original and data.WasEnabled then
            pcall(function() data.Original:Enable() end)
        end
    end
    
    Tween(MainFrame, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
    }, 0.25)
    
    task.delay(0.3, function()
        ScreenGui:Destroy()
    end)
    
    debugLog("Shutdown complete")
end

CloseBtn.MouseButton1Click:Connect(shutdown)
getgenv().UnifiedSpyShutdown = shutdown

task.spawn(function()
    local success = loadAPIDump()
    if success and CachedVersion then
        VersionLabel.Text = "v3.0 | " .. (CachedVersion.version or "?")
        debugLog("API Dump loaded successfully")
    else
        VersionLabel.Text = "v3.0 | No Cache"
        debugWarn("Failed to load API Dump")
    end
end)

task.spawn(function()
    hookRemotes()
    debugLog("Remotes hooked")
end)

task.spawn(function()
    hookHttp()
    debugLog("HTTP hooked")
end)

task.spawn(function()
    hookRobloxReplicatedStorage()
    debugLog("RobloxReplicatedStorage hooked")
end)

task.spawn(function()
    hookSignals()
    debugLog("Signals hooked")
end)

task.spawn(function()
    hookAudios()
    debugLog("Audios hooked")
end)

task.spawn(function()
    hookAnimations()
    debugLog("Animations hooked")
end)

getgenv().UnifiedSpyExecuted = true
getgenv().UnifiedSpy = {
    Settings = Settings,
    Logs = Logs,
    Statistics = Statistics,
    SignalDatabase = SignalDatabase,
    ClassSignals = ClassSignals,
    Version = CachedVersion,
    
    shutdown = shutdown,
    switchTab = switchTab,
    hookSignal = hookSignal,
    exportLogs = exportLogs,
    saveSettings = saveSettings,
    loadSettings = loadSettings,
    getStatisticsReport = getStatisticsReport,
    
    setEnabled = function(enabled)
        Settings.Logging.Enabled = enabled
        spyEnabled = enabled
        saveSettings()
        if enabled then
            TitleBtn.TextColor3 = getColor("Accent")
            StatusLabel.Text = "ACTIVE"
            StatusLabel.TextColor3 = getColor("Success")
        else
            TitleBtn.TextColor3 = getColor("Error")
            StatusLabel.Text = "PAUSED"
            StatusLabel.TextColor3 = getColor("Error")
        end
    end,
    
    setTeleportScript = function(script)
        Settings.TeleportScript = script
        saveSettings()
    end,
    
    addBreakpoint = function(bpType, value)
        table.insert(Settings.Breakpoints, {
            Enabled = true,
            Type = bpType,
            Value = value,
            CreatedAt = os.time(),
        })
        saveSettings()
    end,
    
    clearBreakpoints = function()
        Settings.Breakpoints = {}
        saveSettings()
    end,
    
    addToBlacklist = function(name)
        Settings.Blacklist[name] = true
        saveSettings()
    end,
    
    addToBlocklist = function(name)
        Settings.Blocklist[name] = true
        saveSettings()
    end,
    
    clearBlacklist = function()
        Settings.Blacklist = {}
        SpammySignals = {}
        saveSettings()
    end,
    
    clearBlocklist = function()
        Settings.Blocklist = {}
        saveSettings()
    end,
}

print("═══════════════════════════════════════════")
print("  UnifiedSpy v3.0 Loaded Successfully!")
print("═══════════════════════════════════════════")
print("  • Click title to toggle logging")
print("  • Drag top bar to move window")
print("  • Drag corner to resize")
print("  • Use search to filter logs")
print("═══════════════════════════════════════════")

local signalCount = 0
for _ in pairs(SignalDatabase) do signalCount = signalCount + 1 end
print("  • Signals in database: " .. signalCount)
print("  • Settings: UnifiedSpy/Settings.json")
print("  • Cache: UnifiedSpy/Cache/")
print("═══════════════════════════════════════════")

if DEBUG then
    print("[UnifiedSpy] Debug mode enabled")
    print("[UnifiedSpy] Access via getgenv().UnifiedSpy")
end