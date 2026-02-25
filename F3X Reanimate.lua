
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
if not game:IsLoaded() then game.Loaded:Wait() end
if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end

local realChar = LocalPlayer.Character
local humanoid = realChar:FindFirstChildOfClass("Humanoid")
local rigType = humanoid.RigType

local realAnimate = realChar:FindFirstChild("Animate")
if realAnimate then realAnimate.Enabled = false end

local ServerEndpoint = LocalPlayer.Backpack:WaitForChild("Building Tools")
:WaitForChild("SyncAPI")
:WaitForChild("ServerEndpoint")

realChar.Archivable = true
local fakeChar = realChar:Clone()
fakeChar.Name = "FakeChar"
fakeChar.Parent = workspace

-- deixar clone invisível
for _,v in ipairs(fakeChar:GetDescendants()) do
if v:IsA("BasePart") or v:IsA("Decal") then
v.Transparency = transparency_level
end
end

LocalPlayer.Character = fakeChar
workspace.CurrentCamera.CameraSubject = fakeChar:WaitForChild("Humanoid")

local fakeAnimate = fakeChar:FindFirstChild("Animate")
if fakeAnimate then fakeAnimate.Enabled = true end

-- nomes do corpo
local PartNames =
rigType == Enum.HumanoidRigType.R6 and
{"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}
or
{
"Head","UpperTorso","LowerTorso",
"LeftUpperArm","LeftLowerArm","LeftHand",
"RightUpperArm","RightLowerArm","RightHand",
"LeftUpperLeg","LeftLowerLeg","LeftFoot",
"RightUpperLeg","RightLowerLeg","RightFoot"
}

-- Meshes R6
local R6_MESHES = {

Torso = "rbxassetid://489667862",
["Left Arm"] = "rbxassetid://488154609",
["Right Arm"] = "rbxassetid://488154609",
["Left Leg"] = "rbxassetid://488154609",
["Right Leg"] = "rbxassetid://488155216",

}

-- CRÍTICO (faltava no primeiro script)
local BodyPartNamesSet = {}
for _,name in ipairs(PartNames) do
BodyPartNamesSet[name] = true
end
BodyPartNamesSet["HumanoidRootPart"] = true

-- criar serverpart
local function CreateServerPart(cf)

local before = {}

for _,v in ipairs(workspace:GetChildren()) do
if v.Name == "Part" then
before[v] = true
end
end

ServerEndpoint:InvokeServer("CreatePart","Normal",cf,workspace)

local newPart

repeat

RunService.Heartbeat:Wait()

for _,v in ipairs(workspace:GetChildren()) do

if v.Name == "Part" and not before[v] then

newPart = v
break

end
end

until newPart

return newPart

end

local ServerParts = {}
local ExpectedSizes = {}
local AccessoryMap = {}
local MeshPartMap = {}

--================ BODY =================

local function SetupServerPart(name,fakePart)

local realPart = realChar:FindFirstChild(name,true)

local transparency = 0

if realPart and realPart:IsA("BasePart") then
transparency = realPart.Transparency
end

local serverPart = CreateServerPart(fakePart.CFrame)

ServerEndpoint:InvokeServer("SyncResize",{{
Part = serverPart,
CFrame = fakePart.CFrame,
Size = fakePart.Size
}})

-- MESH REALISTA R6

if RealisticBodyParts and rigType == Enum.HumanoidRigType.R6 then

local meshId = R6_MESHES[name]

if meshId then

ServerEndpoint:InvokeServer("CreateMeshes",{{Part = serverPart}})

ServerEndpoint:InvokeServer("SyncMesh",{{Part = serverPart,MeshId = meshId}})

ServerEndpoint:InvokeServer("SyncMesh",{{Part = serverPart,Scale = Vector3.new(0.01,0.01,0.01)}})

end
end

-- Cabeça

if name == "Head" then

ServerEndpoint:InvokeServer("CreateMeshes",{{Part = serverPart}})

ServerEndpoint:InvokeServer("SyncMesh",{{Part = serverPart,Scale = Vector3.new(1.25,1.25,1.25)}})

end

ServerEndpoint:InvokeServer("SyncColor",{{
Part = serverPart,
Color = fakePart.Color,
UnionColoring = true
}})

ServerEndpoint:InvokeServer("SyncMaterial",{{
Part = serverPart,
Material = fakePart.Material,
Transparency = transparency
}})

serverPart.Anchored = true
serverPart.CanCollide = false
serverPart.CanTouch = false
serverPart.Name = "Server_"..name

ServerEndpoint:InvokeServer("SetLocked",{serverPart},true)

ServerParts[name] = serverPart
ExpectedSizes[name] = fakePart.Size

return serverPart

end

-- criar corpo

for _,name in ipairs(PartNames) do

local fakePart = fakeChar:FindFirstChild(name,true)

if fakePart then

SetupServerPart(name,fakePart)

end
end

-- HRP

local fakeHRP = fakeChar:FindFirstChild("HumanoidRootPart",true)

if fakeHRP then

SetupServerPart("HumanoidRootPart",fakeHRP)

end

--================ ACCESSORIES =================

if RECREATE_ACCESSORIES then

local function RecreateAccessory(realAccessory)

local realHandle = realAccessory:FindFirstChild("Handle",true)

if not realHandle then return end

local cloneHandle = fakeChar:FindFirstChild(realAccessory.Name,true)

if cloneHandle then
cloneHandle = cloneHandle:FindFirstChild("Handle",true)
end

if not cloneHandle then return end

local serverPart = CreateServerPart(cloneHandle.CFrame)

ServerEndpoint:InvokeServer("SyncResize",{{
Part = serverPart,
CFrame = cloneHandle.CFrame,
Size = cloneHandle.Size
}})

ServerEndpoint:InvokeServer("CreateMeshes",{{Part = serverPart}})

if rigType == Enum.HumanoidRigType.R6 and realHandle:FindFirstChildOfClass("SpecialMesh") then

local mesh = realHandle:FindFirstChildOfClass("SpecialMesh")

ServerEndpoint:InvokeServer("SyncMesh",{{Part = serverPart,MeshId = mesh.MeshId}})
ServerEndpoint:InvokeServer("SyncMesh",{{Part = serverPart,TextureId = mesh.TextureId}})
ServerEndpoint:InvokeServer("SyncMesh",{{Part = serverPart,Scale = mesh.Scale}})

else

ServerEndpoint:InvokeServer("SyncMesh",{{Part = serverPart,MeshId = realHandle.MeshId}})
ServerEndpoint:InvokeServer("SyncMesh",{{Part = serverPart,TextureId = realHandle.TextureID}})

local scale = Vector3.new(1,1,1)

if realHandle:IsA("MeshPart") and realHandle.MeshSize.Magnitude > 0 then

scale =
Vector3.new(
realHandle.Size.X/realHandle.MeshSize.X,
realHandle.Size.Y/realHandle.MeshSize.Y,
realHandle.Size.Z/realHandle.MeshSize.Z
)

end

ServerEndpoint:InvokeServer("SyncMesh",{{Part = serverPart,Scale = scale}})

end

ServerEndpoint:InvokeServer("SyncColor",{{
Part = serverPart,
Color = cloneHandle.Color,
UnionColoring = true
}})

local transparency = realHandle and realHandle.Transparency or 0

ServerEndpoint:InvokeServer("SyncMaterial",{{
Part = serverPart,
Material = cloneHandle.Material,
Transparency = transparency
}})

serverPart.Anchored = true
serverPart.CanCollide = false
serverPart.CanTouch = false
serverPart.Name = "Server_Accessory_"..realAccessory.Name

ServerEndpoint:InvokeServer("SetLocked",{serverPart},true)

AccessoryMap[serverPart] = cloneHandle

end

for _,accessory in ipairs(realChar:GetChildren()) do

if accessory:IsA("Accessory") then

RecreateAccessory(accessory)

end
end
end

--================ MESH PARTS =================

local function RecreateMeshPart(meshPart)

-- ADICIONADO DO SEGUNDO SCRIPT (CRÍTICO)

if BodyPartNamesSet[meshPart.Name] then return end

local specialMesh = meshPart:FindFirstChildOfClass("SpecialMesh")

if not meshPart:IsA("MeshPart") and not specialMesh then return end

-- lógica original preservada

if meshPart:IsA("MeshPart") then

while meshPart.MeshId == "" or meshPart.MeshSize.Magnitude == 0 do
RunService.Heartbeat:Wait()
end

end

local serverPart = CreateServerPart(meshPart.CFrame)

ServerEndpoint:InvokeServer("SyncResize",{{
Part = serverPart,
CFrame = meshPart.CFrame,
Size = meshPart.Size
}})

ServerEndpoint:InvokeServer("CreateMeshes",{{Part = serverPart}})

local meshId,textureId,scale

if meshPart:IsA("MeshPart") then

meshId = meshPart.MeshId
textureId = meshPart.TextureID

scale =
Vector3.new(
meshPart.Size.X/meshPart.MeshSize.X,
meshPart.Size.Y/meshPart.MeshSize.Y,
meshPart.Size.Z/meshPart.MeshSize.Z
)

else

meshId = specialMesh.MeshId
textureId = specialMesh.TextureId
scale = specialMesh.Scale

end

ServerEndpoint:InvokeServer("SyncMesh",{{Part = serverPart,MeshId = meshId}})
ServerEndpoint:InvokeServer("SyncMesh",{{Part = serverPart,TextureId = textureId}})
ServerEndpoint:InvokeServer("SyncMesh",{{Part = serverPart,Scale = scale}})

ServerEndpoint:InvokeServer("SyncColor",{{
Part = serverPart,
Color = meshPart.Color,
UnionColoring = true
}})

local realMeshPart = realChar:FindFirstChild(meshPart.Name,true)
local transparency = meshPart.Transparency

if realMeshPart and realMeshPart:IsA("BasePart") then
transparency = realMeshPart.Transparency
end

ServerEndpoint:InvokeServer("SyncMaterial",{{
Part = serverPart,
Material = meshPart.Material,
Transparency = transparency
}})

serverPart.Anchored = true
serverPart.CanCollide = false
serverPart.CanTouch = false
serverPart.Name = "Server_MeshPart_"..meshPart.Name

ServerEndpoint:InvokeServer("SetLocked",{serverPart},true)

MeshPartMap[serverPart] = meshPart

end

for _,desc in ipairs(fakeChar:GetDescendants()) do

if desc:IsA("MeshPart") and not desc.Parent:IsA("Accessory") then

RecreateMeshPart(desc)

elseif desc:IsA("BasePart") then

if desc:FindFirstChildOfClass("SpecialMesh") then

RecreateMeshPart(desc)

end
end
end

--================ R6 SHIRT / TSHIRT / PANTS =================

local function ApplyR6Clothing()

if rigType ~= Enum.HumanoidRigType.R6 then return end

local shirt = realChar:FindFirstChildOfClass("Shirt")
local tshirt = realChar:FindFirstChildOfClass("ShirtGraphic")
local pants = realChar:FindFirstChildOfClass("Pants")

local function ApplyTextureToParts(textureId, parts)

for _, partName in ipairs(parts) do

local serverPart = ServerParts[partName]

if serverPart then

for _, face in ipairs(Enum.NormalId:GetEnumItems()) do

ServerEndpoint:InvokeServer("CreateTextures", {{
Part = serverPart,
Face = face,
TextureType = "Decal"
}})

ServerEndpoint:InvokeServer("SyncTexture", {{
Part = serverPart,
Face = face,
TextureType = "Decal",
Texture = textureId
}})

task.wait(0.03)

end
end
end
end

if shirt then
ApplyTextureToParts("rbxassetid://"..shirt.ShirtTemplate:match("%d+"), {"Torso","Left Arm","Right Arm"})
end

if tshirt then
ApplyTextureToParts("rbxassetid://"..tshirt.Graphic:match("%d+"), {"Torso"})
end

if pants then
ApplyTextureToParts("rbxassetid://"..pants.PantsTemplate:match("%d+"), {"Left Leg","Right Leg"})
end

end

ApplyR6Clothing()

--================ MOVEMENT =================

local ACCUM = 0
local RATE = 1/60

RunService.PreSimulation:Connect(function(dt)

ACCUM += dt

if ACCUM < RATE then return end

ACCUM = 0

for name, serverPart in pairs(ServerParts) do

local fakePart = fakeChar:FindFirstChild(name,true)

if fakePart then

ServerEndpoint:InvokeServer("SyncMove", {{
Part = serverPart,
CFrame = fakePart.CFrame
}})

ServerEndpoint:InvokeServer("SetLocked", {serverPart}, true)

end
end

for serverPart, handle in pairs(AccessoryMap) do

ServerEndpoint:InvokeServer("SyncMove", {{
Part = serverPart,
CFrame = handle.CFrame
}})

end

for serverPart, meshPart in pairs(MeshPartMap) do

ServerEndpoint:InvokeServer("SyncMove", {{
Part = serverPart,
CFrame = meshPart.CFrame
}})

end

end)

task.wait()

ServerEndpoint:InvokeServer("Remove", {realChar})
