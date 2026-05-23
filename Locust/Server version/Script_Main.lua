local tv=script.Parent
local tvscreen=tv:FindFirstChild("defaultMaterial2")
local spotlight=tvscreen:FindFirstChild("SpotLight")
local decal=tvscreen:FindFirstChild("Decal")
local dist=25
local owner=script.Owner.Value
local glass=script.Parent.glass
local frames=glass.LOCUST:GetChildren()
local decal2=glass.the
local function randomsound(folder)
	local get=folder:GetChildren()
	local git=get[math.random(1, #get)]
	return git
end
addsound=function(sound, parent, timeposition)
	local newsound = sound:Clone()
	newsound.Parent = parent
	if timeposition then
		newsound.TimePosition = timeposition
	end
	local newsound2

	newsound:Play()

	spawn(function()
		newsound.Ended:Wait()
		newsound:Destroy()
	end)
	return newsound
end


local statics={
	"rbxassetid://13928716599",
	"rbxassetid://13928725147",
	"rbxassetid://13928718527",
}


local change=1

local function changetvstatic()
	if change==1 then
		decal.Texture=statics[1]
		change=2
	elseif change==2 then
		decal.Texture=statics[2]
		change=3
	elseif change==3 then
		decal.Texture=statics[3]
		change=1
	end
end

local hitb = Instance.new("Part", workspace)
hitb.Transparency = 1
hitb.CanCollide = false
hitb.Size = Vector3.new(dist, dist, dist)
hitb.Massless = true
hitb.CFrame = tvscreen.CFrame
hitb.CanTouch = false
hitb.CanQuery = false
local weld = Instance.new("WeldConstraint", hitb)
weld.Part0 = hitb
weld.Part1 = tvscreen
	
local function detectPlayer()
	local cancelled = false
	local hitted = {}
	local find = false
	if cancelled then return end
	for _, target in pairs(workspace:GetPartsInPart(hitb)) do
		if target and target.Parent and target.Parent:FindFirstChildWhichIsA("Humanoid") and target.Parent ~= owner and target.Parent:FindFirstChild("HumanoidRootPart") and not table.find(hitted, target.Parent) then
			find = true
		end
	end
	return find
end

while true do
	task.wait(0.2)
	if detectPlayer() then
		tvscreen.static1:Play()
		local staticing=true
		spawn(function()
			while staticing do
				task.wait(0.1)
				if not staticing then return end
				changetvstatic()
			end
		end)
		task.wait(Random.new():NextNumber(1, 3))
		tvscreen.static1:Stop()
		decal.Transparency=1
		glass.the.Transparency=0
		glass.static:Play()
		local dones=false
		spawn(function()
			local loop=math.random(2,3)
			local looped=0
			local random=math.random(1,2)
			if random==1 then
				local frames2=glass.static1:GetChildren()
				while true do
					looped+=1
					local fmes=#frames2
					for frame=0,fmes-1 do
						task.wait(0.02)
						decal2.Texture=glass.static1[frame].Texture
					end
					if looped>=loop then
						dones=true
						break
					end
				end
			elseif random==2 then
				loop=1
				local frames2=glass.static2:GetChildren()
				glass.heart1:Play()
				glass.heart1.PlaybackSpeed=0.8
				while true do
					looped+=1
					local fmes=#frames2
					for frame=0,fmes-1 do
						task.wait(0.02)
						decal2.Texture=glass.static2[frame].Texture
						if frame==150 then
							addsound(randomsound(glass.doorsounds), glass).PlaybackSpeed=Random.new():NextNumber(0.8,1)
                            game:GetService("TweenService"):Create(glass.heart1, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {PlaybackSpeed=1.5}):Play()
						elseif frame==275 then
							glass.heart1:Stop()
						end
					end
					if looped>=loop then
						dones=true
						break
					end
				end
			end
		end)
		repeat task.wait() until dones
		local glass1=1
		local ret=false
		spawn(function()
		while true do
			local fmes=#frames
			for frame=0,fmes-1 do
				task.wait(0.02)
				decal2.Texture=glass.LOCUST[frame].Texture
				if frame==0 or frame==50 or frame==137 or frame==201 then
					addsound(randomsound(glass.groan), glass).PlaybackSpeed=Random.new():NextNumber(0.7,1.1)

				end
				if frame==35 or frame==104 or frame==178 or frame==263 then
					print("thump")
					addsound(randomsound(glass.thump), glass).PlaybackSpeed=Random.new():NextNumber(0.66,0.85)
					if not glass:FindFirstChild("glass"..glass1) then
						print("BREAK")
						addsound(randomsound(glass.glass), glass).PlaybackSpeed=Random.new():NextNumber(0.8,1)
						for i,v in pairs(glass:GetChildren()) do
							if v:FindFirstChildWhichIsA("Decal") then
								v:Destroy()
							end
						end
						ret=true
						glass.GlassShatter:Emit(165)
						decal2.Transparency=1
						break
					else
						glass["glass"..glass1].Decal.Transparency=0
						glass1+=1
					end
				end
			end
		end
		end)
		repeat task.wait() until ret
		
		print("broken")
		script.Alert.Value=true
		staticing=false
		decal.Transparency=1
		task.wait(Random.new():NextNumber(10,15))
		local vfx=script.vfx
		local sound=script["exp"..math.random(1,3)]
		sound.Parent=vfx
		sound:Play()
		for i,v in pairs(vfx:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				if v:GetAttribute("EmitCount") then
					v:Emit(v:GetAttribute("EmitCount"))
				else
					v:Emit(35)
				end
			end
		end
		for i,v in pairs(tv:GetChildren()) do
			if v:IsA("Part") or v:IsA("MeshPart") then
				v:Destroy()
			end
		end
		game.Debris:AddItem(tv, 4)
		break
	end
end
