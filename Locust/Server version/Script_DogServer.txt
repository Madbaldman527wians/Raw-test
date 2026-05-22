local Character = script.Parent
local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
local Hrp = Character:FindFirstChild("HumanoidRootPart")
local Event = Character:WaitForChild("RemoteEvent")

local Reference = Character:FindFirstChild("RootPart")

local Animator = require(script.Animator)
local AnimationFolder = script.Animations
AnimationFolder.Parent = nil
spawn(function()
	local parent = Character.Parent
	repeat task.wait() until Character.Parent ~= parent
	AnimationFolder:Destroy()
end)

cooldownList = {}

new=function(Animation)
	local NEW = Animator:LoadAnimation(Character, Animation)
	return NEW
end

getCool=function(n)
	if table.find(cooldownList, n) then return true end
	return false
end

addCooldown=function(te)
	if not table.find(cooldownList, te) then
		table.insert(cooldownList, te)
	end
end



removeCooldown=function(te) 
	if table.find(cooldownList, te) then
		local function removeindex(array, index)
			for i,v in pairs(array) do
				if tostring(v) == tostring(index) then
					table.remove(array, i)
				end
			end
		end
		removeindex(cooldownList, te)
	end
end

local Animations = {
	CrouchIdle = new(AnimationFolder.crouchidle),
	CrouchWalk = new(AnimationFolder.crouchwalk),
	Sit = new(AnimationFolder.sit),
	Eat2 = new(AnimationFolder.jumpscare),
	Idle = new(AnimationFolder.idle),
	Walk = new(AnimationFolder.walk),
	Run = new(AnimationFolder.run),
	TV = new(AnimationFolder.spawn),
}

Animations.Run:AdjustSpeed(4)
Animations.Walk:AdjustSpeed(2.5)
Animations.CrouchWalk:AdjustSpeed(2.5)
Animations.CrouchIdle:AdjustSpeed(2.5)
Animations.TV:AdjustSpeed(2.5)
Animations.Eat2:AdjustSpeed(2.5)

StopAnimation=function()
	for i,v in pairs(Animations) do
		if v.IsPlaying then
			v:Stop()
		end
	end
end

local RunType = 1




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

FollowVelocity=function(startingSpeed, direction, useCamera, Up)
	local bodyVelocity = Instance.new("BodyVelocity", Hrp)
	bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
	local Speed = Instance.new("NumberValue", bodyVelocity)
	Speed.Name = "Speed"
	Speed.Value = startingSpeed
	local Follow = script.Follow:Clone()
	Follow.BodyVelocity.Value = bodyVelocity
	Follow.Count.Value = Speed
	Follow.Character.Value = Character
	Follow.Direction.Value = direction or "Front"
	Follow.UseCamera.Value = useCamera or false
	Follow.Up.Value = Up or 0
	Follow.Remote.Value = Follow.RemoteEvent
	Follow.Enabled = true
	Follow.Parent = Character

	return Speed, Follow, bodyVelocity, Follow.RemoteEvent.OnServerEvent
end

chargehitbox=function(hitbox)
	local hitb = script.HitBoxCallback:Clone()
	hitb.Parent = Character
	hitb.Ignore.Value = Character
	hitb.Hitbox.Value = hitbox
	hitb.Enabled = true
	return hitb.Event.OnServerEvent
end
vfx=function(parent, var:Instance, emitC:number, cframe:CFrame)
	local check=function(txt)
		local succ, err = pcall(function()
			if txt:IsA("Part") or txt:IsA("MeshPart") or txt:IsA("Model") or txt:IsA("UnionOperation") then return nil end
		end)
		if succ then
			if txt:IsA("Part") or txt:IsA("MeshPart") or txt:IsA("Model") or txt:IsA("UnionOperation") then
				return nil
			end
		else
			--Print(err, "- ignore this")
		end
		if parent:FindFirstChild(txt) then
			local ret = parent:FindFirstChild(txt)
			return ret
		else
			return nil
		end
	end
	local instanc
	local c = check(var)
	if c then
		instanc = c
	else
		instanc = var
	end
	local instance = instanc:Clone()
	instance.CFrame = cframe
	instance.Parent = workspace
	for _, particle in pairs(instance:GetDescendants()) do
		if particle:IsA("ParticleEmitter") then
			if particle:GetAttribute("EmitCount") then
				particle:Emit(particle:GetAttribute("EmitCount"))
			else
				if emitC then
					particle:Emit(emitC)
				else
					particle:Emit(15)
				end
			end
		end
	end
	game.Debris:AddItem(instance, 10)
	return instance
end

anglevfx=function(from, to, parent, var:Instance, emitC:number)
	local cf = CFrame.new(to.Position, from.Position)
	local v = vfx(parent, var, emitC, cf)
end

vfxground=function(parent, var:Instance, emitC:number, origin:Vector3, checkDist:number)
	local check=function(txt)
		local succ, err = pcall(function()
			if txt:IsA("Part") or txt:IsA("MeshPart") or txt:IsA("Model") or txt:IsA("UnionOperation") then return nil end
		end)
		if succ then
			if txt:IsA("Part") or txt:IsA("MeshPart") or txt:IsA("Model") or txt:IsA("UnionOperation") then
				return nil
			end
		else
			--Print(err, "- ignore this")
		end
		if parent:FindFirstChild(txt) then
			local ret = parent:FindFirstChild(txt)
			return ret
		else
			return nil
		end
	end
	local instanc
	local c = check(var)
	if c then
		instanc = c
	else
		instanc = var
	end
	local instance = instanc:Clone()
	instance.Parent = workspace
	local _1 = {}
	for i,v in pairs(workspace:GetChildren()) do
		if v:IsA("Model") and v:FindFirstChildWhichIsA("Humanoid") then
			table.insert(_1, v)
		end
	end
	local avparams = RaycastParams.new()
	avparams.FilterType = Enum.RaycastFilterType.Exclude
	avparams.FilterDescendantsInstances = _1
	local r=workspace:Raycast(origin, Vector3.new(0, checkDist or -5, 0), avparams)
	if r then
		local po=r.Position
		instance.Position = po
		for _, particle in pairs(instance:GetDescendants()) do
			if particle:IsA("ParticleEmitter") then
				if particle:GetAttribute("EmitCount") then
					particle:Emit(particle:GetAttribute("EmitCount"))
				else
					if emitC then
						particle:Emit(emitC)
					else
						particle:Emit(15)
					end
				end
			end
		end
	else
		instance:Remove()
	end
	game.Debris:AddItem(instance, 10)
end

local Mover = true
local idling = false
local Stunned = false

local OriginalSpeed = 13
local Speed = OriginalSpeed
spawn(function()
	
	local hum = script.Parent:FindFirstChildWhichIsA("Humanoid")
	while true do
		task.wait()
		hum.WalkSpeed = Speed
		if not Mover then continue end
		if hum.MoveDirection == Vector3.new(0, 0, 0) then
			if not idling then
				idling = true
				StopAnimation()
				if RunType == 3 then
					Animations.CrouchIdle:Play()
				elseif RunType == 4 then
					Animations.CrawlIdle:Play()
				else
					Animations.Idle:Play()
				end
			end
			if RunType == 3 then
				if idling and not Animations.CrouchIdle.IsPlaying then
					StopAnimation()
					Animations.CrouchIdle:Play()
				end
			elseif RunType == 4 then
				if idling and not Animations.CrawlIdle.IsPlaying then
					StopAnimation()
					Animations.CrouchIdle:Play()
				end
			else
				if idling and not Animations.Idle.IsPlaying then
					StopAnimation()
					Animations.Idle:Play()
				end
			end
		else
			if idling then
				idling = false
				StopAnimation()
				if RunType == 1 then
					Animations.Walk:Play()
				elseif RunType == 2 then
					Animations.Run:Play()
				elseif RunType == 3 then
					Animations.CrouchWalk:Play()
				elseif RunType == 4 then
					Animations.CrawlWalk:Play()
				end
			end
			if RunType == 1 then
				if not idling and not Animations.Walk.IsPlaying then
					StopAnimation()
					Animations.Walk:Play()
				end
			elseif RunType == 2 then
				if not idling and not Animations.Run.IsPlaying then
					StopAnimation()
					Animations.Run:Play()
				end
			elseif RunType == 3 then
				if not idling and not Animations.CrouchWalk.IsPlaying then
					StopAnimation()
					Animations.CrouchWalk:Play()
				end
			elseif RunType == 4 then
				if not idling and not Animations.CrawlWalk.IsPlaying then
					StopAnimation()
					Animations.CrawlWalk:Play()
				end
			end
		end
	end
end)

local HardDamage = 70
local ContinualDamage = 0
local ResetTick = 0.05
local CanStun = true

local check=function(c, txt)
	local succ, err = pcall(function()
		if txt:IsA("Part") or txt:IsA("MeshPart") or txt:IsA("Model") or txt:IsA("UnionOperation") or txt:IsA("Sound") then return nil end
	end)
	if succ then
		if txt:IsA("Part") or txt:IsA("MeshPart") or txt:IsA("Model") or txt:IsA("UnionOperation") or txt:IsA("Sound") then
			return nil
		end
	else
		--Print(err, "- ignore this")
	end
	if c:FindFirstChild(txt) then
		local ret = c:FindFirstChild(txt)
		return ret
	else
		return nil
	end
end

bodysound=function(check2, str)
	for i,v in pairs(Hrp:GetChildren()) do
		if v:IsA("Sound") and v.Name == "bodysound" then
			v:Destroy()
		end
	end
	local instanc
	local c = check(check2, str)
	if c then
		instanc = c
	else
		instanc = str
	end
	if not instanc then return end
	local sound = instanc:Clone()
	sound.Name = "bodysound"
	sound:Play()
	spawn(function()
		sound.Ended:Wait()
		sound:Destroy()
	end)
	return sound
end

folder=function()
	if Character:FindFirstChild("damaged") then Character:FindFirstChild("damaged"):Destroy() end
	local accessory = Instance.new("Accessory", Character)
	accessory.Name = "damaged"
	return accessory
end

finded=function(look,check)
	for i,v in pairs(look:GetChildren()) do
		if v == check then
			return true
		end
	end
	return false
end
--[[
local lasthealth = Humanoid.Health

Humanoid.HealthChanged:Connect(function(health)
	if health < lasthealth then
		
		print("damage")
		
		local instance=folder()
		task.delay(ResetTick, function()
			if finded(Character, instance) then
				instance:Destroy()
				ContinualDamage = 0
			end
		end)
		
		ContinualDamage = ContinualDamage + lasthealth - health
		print(ContinualDamage)
		
		if ContinualDamage >= HardDamage and not Stunned and CanStun then
			print("flinch")
			local s = addsound(script.painsounds:FindFirstChild("pain"), Hrp)
			s.PlaybackSpeed = Random.new():NextNumber(0.8, 1)
			Stunned = true
		    Mover = false
			local flinch
			local r = math.random(1,3)
			if r == 1 then
				flinch = Animations.Flinch1
			elseif r == 2 then
				flinch = Animations.Flinch2
			elseif r == 3 then
				flinch = Animations.Flinch3
			end
			StopAnimation()
			Speed = 0
			flinch:Play()
			flinch.Completed:Wait()
			Stunned = false
			Speed = OriginalSpeed
			Mover = true
		end
	end
	lasthealth = health
end)
--]]

local function Weld(part, char : Model, target : Model)

	function tranquilize(player, e)
		if e == "on" then
			if player:FindFirstChildWhichIsA("Humanoid") then
				player:FindFirstChildWhichIsA("Humanoid").PlatformStand = true
			end
			wait(0.1)
			if player:FindFirstChild("Torso") then
				player:FindFirstChild("Torso").CanCollide = false
			end
			if player:FindFirstChild("HumanoidRootPart") then
				player:FindFirstChild("HumanoidRootPart").CanCollide = false
			end
			for i,v in pairs(player:GetDescendants()) do
				if v:IsA("Part") or v:IsA("BasePart") or v:IsA("UnionOperation") or v:IsA("Meshpart") then
					if v.Massless == true then continue end
					v.Massless = true
				end
			end
		elseif e == "off" then
			if player:FindFirstChildWhichIsA("Humanoid") then
				player:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
			end
			wait(0.1)
			if player:FindFirstChild("Torso") then
				player:FindFirstChild("Torso").CanCollide = true
			end
			if player:FindFirstChild("HumanoidRootPart") then
				player:FindFirstChild("HumanoidRootPart").CanCollide = true
			end
			for i,v in pairs(player:GetDescendants()) do
				if v:IsA("Part") or v:IsA("BasePart") or v:IsA("UnionOperation") or v:IsA("Meshpart") then
					if v.Massless == false then continue end
					v.Massless = false
				end
			end
		end
	end

	local alreadygavehealth = false
	local hum2 = target:FindFirstChildWhichIsA("Humanoid")
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	local thrp = target:FindFirstChild("HumanoidRootPart")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	tranquilize(target, "on")
	local stopped = Instance.new("BoolValue", thrp)
	stopped.Name = "stopped"
	local weld = Instance.new("Weld", thrp)
	weld.Name = "tempweld"
	weld.Part0 = part
	weld.Part1 = thrp


	spawn(function()
		local connection2 = hum2.HealthChanged:Connect(function(health)
			if health <= 1 then
				hum2.Health += 1
				alreadygavehealth = true
			end
		end)
		repeat task.wait()	until stopped.Value == true or hum.Health == 0
		tranquilize(target, "off")
		weld:Destroy()
		stopped:Destroy()
		connection2:Disconnect()
		if hum.Health == 0 then
		else
			if target:FindFirstChild("Downed") then
				if target:FindFirstChild("Downed").Value == true then
					return
				else
					if alreadygavehealth then
						wait(0.1)
						hum2.Health = 0
						wait(0.1)
						hum2.Health = 0
						wait(0.1)
						hum2.Health = 0
						wait(0.1)
						hum2.Health = 0
					end
				end
			else
				if alreadygavehealth then
					wait(0.1)
					hum2.Health = 0
					wait(0.1)
					hum2.Health = 0
					wait(0.1)
					hum2.Health = 0
					wait(0.1)
					hum2.Health = 0
				end
			end
		end
	end)
	return stopped, weld
end
local function randomsound(folder)
	local get=folder:GetChildren()
	local git=get[math.random(1, #get)]
	return git
end
local function invis(bool)
	if bool == true then
		Character.Body.Transparency=1
		Character.Body2.Transparency=1
		Character.Body3.Transparency=1
		Character.NursePath.Transparency=1
		Character.NursePath2.Transparency=1
		Character.face.Transparency=1
		Character.face2.Transparency=1
		Character.face3.Transparency=1
		Character.invis.Value=true
		Hrp.ambience:Stop()
		Hrp["close ambience"]:Stop()
	else
		Character.Body.Transparency=0
		Character.Body2.Transparency=0
		Character.Body3.Transparency=0
		Character.NursePath.Transparency=0
		Character.NursePath2.Transparency=0
		Character.face.Transparency=0
		Character.face2.Transparency=0
		Character.face3.Transparency=0
		Character.invis.Value=false
		Hrp.ambience:Play()
		Hrp["close ambience"]:Play()
	end
end

local buff=false
local Dead = false

local crouchthe=1
local sprint=false
local sounds=script.sounds
Event.OnServerEvent:Connect(function(plr, args)
	if not args then return end
	local goal = args.g or args.goal
	if not goal then return end
	if goal == "attack2" and not Stunned and not getCool("Attacking") and not getCool("crouching") and not getCool("crawling") and not getCool("sit") and Character.invis.Value==false then
		Mover = false
		StopAnimation()
		Speed = 2
		addCooldown("Attacking")
		local hitb = Instance.new("Part", workspace)
		hitb.Transparency = 1
		hitb.CanCollide = false
		hitb.Size = Vector3.new(15, 20, 15)
		hitb.Massless = true
		hitb.CFrame = Hrp.CFrame * CFrame.new(0, -3, -8)

		local weld = Instance.new("WeldConstraint", hitb)
		weld.Part0 = hitb
		weld.Part1 = Hrp

		local getgot = false
		local hitted = {}
		local hitboxClient = script.hitb2:Clone()
		hitboxClient.Parent = Character
		hitboxClient.Value.Value = hitb
		hitboxClient.ignore.Value = Character
		hitboxClient.Enabled = true
		local loaded=false
		local this=false
		local GOT = false
		local connect = hitboxClient.RemoteEvent.OnServerEvent:Connect(function(plr, target)
			if target then
				print("get")
				Hrp.Anchored=true
				Humanoid.AutoRotate=false
				local targethrp = target:FindFirstChild("HumanoidRootPart")
				local targethum = target:FindFirstChildWhichIsA("Humanoid")
				addsound(script.sounds:FindFirstChild("hit"..math.random(1,7)), targethrp)
				addsound(script.pick, targethrp)
				addsound(randomsound(sounds.stab), targethrp)
				getgot=true
				local pullP=targethrp
				targethum.PlatformStand=true
				task.delay(1.5, function()
					targethum.PlatformStand=false
				end)

				local bv = Instance.new("BodyPosition")
				bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				bv.D=900
				bv.P=20000
				local av=Instance.new("BodyGyro", targethrp)
				av.CFrame =pullP.CFrame
				av.MaxTorque=Vector3.new(math.huge, math.huge, math.huge)
				av.P=15000
				av.D=250
				bv.Position=Character.head2.Position
				bv.Parent=pullP
				local function changy()
					av.CFrame =Character.head2.CFrame
					bv.Position=Character.head2.Position
				end
				local er=Animations.Eat2.KeyframeReached:Connect(function(kf)
					if kf == "hitreg" then
						if targethrp:FindFirstChild("Pull") then
							targethrp:FindFirstChild("Pull"):Destroy()
						end

						for count = 1,math.random(25,35) do
							spawn(function()
								local part = Instance.new("Part", workspace)
								part.Anchored = false
								part.Size = Vector3.new(Random.new():NextNumber(0.5,0.9),Random.new():NextNumber(0.5,0.9),Random.new():NextNumber(0.5,0.9))
								part.Position = targethrp.Position
								part.Color = Color3.fromRGB(66, 0, 1)
								part.Material = Enum.Material.Mud
								local partY = part.Size.Y / 2

								local att1 = Instance.new("Attachment", part)
								local att2 = Instance.new("Attachment", part)

								att1.CFrame = CFrame.new(0, partY, 0)
								att2.CFrame = CFrame.new(0, -partY, 0)
								local trail = script.Trail:Clone()
								trail.Parent = part
								trail.Attachment1 = att1
								trail.Attachment0 = att2

								local bv = Instance.new("BodyVelocity", part)
								bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
								bv.Velocity = Vector3.new(math.random(-45,45),math.random(25,70),math.random(-45,45))
								game:GetService("Debris"):AddItem(bv, 0.05)
								game:GetService("Debris"):AddItem(part, math.random(10, 12.1))
							end)
						end
						anglevfx(Hrp,targethrp, script, script.hit, 20)
						if targethum.Health <=3887 then
							local bv = Instance.new("BodyVelocity", targethrp)
							bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
							bv.Velocity = Hrp.CFrame.LookVector *20 + Vector3.new(0, 60, 0)
							game.Debris:AddItem(bv, 0.2)
							targethum.Health=0

							local function intestinelaucnh(intestine)
								local intestine1=intestine:Clone()
								intestine1.Parent=workspace.Terrain
								intestine1:SetPrimaryPartCFrame(targethrp.CFrame)
								game.Debris:AddItem(intestine1, math.random(7, 20))
								for i,v in pairs(intestine1:GetChildren()) do
									if v:IsA("Part") then
										v.Anchored=false
									end
								end
								local bv = Instance.new("BodyVelocity", intestine1.PrimaryPart)
								bv.MaxForce=Vector3.new(math.huge, math.huge, math.huge)
								bv.Velocity= Vector3.new(0, math.random(45, 65), 0)+Vector3.new(math.random(-15, 15), 0, math.random(-15, 15))
								game.Debris:AddItem(bv, 0.2)
							end
							intestinelaucnh(script.intestine1)
							intestinelaucnh(script.intestine2)

						else
							local bv = Instance.new("BodyVelocity", targethrp)
							bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
							bv.Velocity = Hrp.CFrame.LookVector *10 + Vector3.new(0, 55, 0)
							game.Debris:AddItem(bv, 0.2)
						end
						addsound(randomsound(sounds.Hitsounds), targethrp)
						addsound(randomsound(sounds["break"]), targethrp)
						addsound(randomsound(sounds.tear), targethrp)
						targethum:TakeDamage(3887)
					end
				end)
				changy()
				bv.Name = "Pull"
				spawn(function()
					while bv.Parent == pullP do
						changy()
						task.wait()
					end
				end)
				spawn(function()
					repeat task.wait() until Animations.Eat2.IsPlaying or Humanoid.Health<=0
					repeat task.wait() until this or Humanoid.Health <= 0
					er:Disconnect()
					bv:Destroy()
					av:Destroy()
				end)
			end
		end)
		hitboxClient.RemoteEvent.OnServerEvent:Wait()
		wait(0.05)
		connect:Disconnect()
		hitboxClient:Destroy()

		if getgot then
			StopAnimation()
			loaded=true
			local chosenAnim = Animations.Eat2
			chosenAnim:Play()
			local e, cf = script.Parent.RemoteFunction:InvokeClient(plr)
			Hrp.CFrame=cf
			addsound(script.attack2, Hrp)
			local fired = false
			repeat task.wait() until chosenAnim.IsPlaying == false
			Hrp.Anchored=false
			Humanoid.AutoRotate=true
            this=true
			if not Dead then
				Speed = OriginalSpeed
				Mover = true
				removeCooldown("Attacking")
			end
		else
			Speed = OriginalSpeed
			Mover = true
			removeCooldown("Attacking")
		end
	elseif goal == "sprint" and not Stunned and not getCool("crouching") and not getCool("crawling") and not getCool("sit") then
		if not sprint then
			sprint=true
			OriginalSpeed = 45
			Speed = OriginalSpeed
			RunType = 2
		else
			sprint=false
			RunType = 1
			OriginalSpeed = 13
			Speed = OriginalSpeed
		end
	elseif goal == "placetv" and not Stunned and not getCool("Attacking")  then
		addCooldown("Attacking")
		Mover=false
		Speed=0
		StopAnimation()
        invis(true)
		local tv = script.tv:Clone()
		tv.Parent=Character.TV
		Hrp.Anchored=true
		Humanoid.AutoRotate=false
		local e, cf = script.Parent.RemoteFunction:InvokeClient(plr)
		Hrp.CFrame=cf
		local x, y, z=Hrp.CFrame:ToEulerAnglesXYZ()
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local _l = {}
		for i,v in pairs(workspace:GetChildren()) do
			if v:IsA("Model") and v:FindFirstChildWhichIsA("Humanoid") then
				table.insert(_l,v)
			end
		end
		local function git2(paras, st)

			local avPos = st

			local maxRange = 85

			local startPosition = avPos

			local function ray(origin)
				local newRay = workspace:Raycast(origin, Vector3.new(0, -maxRange, 0), paras)
				if newRay and newRay.Instance then
					local part = newRay.Instance
					local CurrRange = (startPosition - newRay.Position).Magnitude
					return newRay, CurrRange
				else
					return false
				end
			end
			local result
			local p
			local nr
			local cr
			local r
			while true do
				task.wait()
				nr,cr = ray(avPos)
				if nr and nr.Instance then
					p = nr.Instance
					r = nr.Position
					if not p then
						result = false
						break
					end
					if cr >= maxRange then
						result = false
						break
					end
					if p.CanCollide == false or p.Transparency > 0.7 then
						avPos = r + Vector3.new(0, -0.01, 0)						
					else
						result = true
						break
					end
				else
					result = false
					break
				end
			end
			return result, nr, r
		end
		local result,ray,rayposition=git2(params, Hrp.Position)
		if result then
			tv:SetPrimaryPartCFrame(CFrame.new(rayposition+Vector3.new(0, 4.425, 0))*CFrame.Angles(x,y,z))
			tv.Main.Owner.Value=Character


			task.wait(1)
			tv.Main.Enabled=true
			repeat task.wait() until tv.Main.Alert.Value==true
            invis(false)
			addsound(script.tv1, Hrp)
			Animations.TV:Play()
			Animations.TV.Completed:Wait()
			game:GetService("TweenService"):Create(Hrp, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {CFrame = Hrp.CFrame*CFrame.new(0, 0, -7)}):Play()

			Humanoid.AutoRotate=true
			Mover=true
			Hrp.Anchored=false
			Speed=OriginalSpeed
			removeCooldown("Attacking")
		else
			Hrp.Anchored=false
			Humanoid.AutoRotate=true
			task.wait(1)
			Mover=true
			Speed=OriginalSpeed
			removeCooldown("Attacking")
		end
	elseif goal == "crouch" and not Stunned and not getCool("Attacking") and not getCool("crawling") and not getCool("sit") then
		Mover=false
		Speed=0
		StopAnimation()
		
		if getCool("crouching") then
			addCooldown("Attacking")
			removeCooldown("crouching")
			Animations.Idle:Play(0.5, 1)
			game:GetService("TweenService"):Create(Humanoid, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {HipHeight=12.1}):Play()
			task.wait(0.5)
			Mover=true
			RunType=1
			Speed=13
			OriginalSpeed=Speed
			sprint=false
			removeCooldown("Attacking")
		else
			addCooldown("crouching")
			addCooldown("Attacking")
			Animations.CrouchIdle:Play(0.5, 1)
			game:GetService("TweenService"):Create(Humanoid, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {HipHeight=4.5}):Play()
			task.wait(0.5)
			Mover=true
			Speed=13
			OriginalSpeed=Speed
			removeCooldown("Attacking")
			sprint=false
			RunType=3
		end
	elseif goal == "sit" and not Stunned and not getCool("Attacking") then
		Mover=false
		Speed=0
		StopAnimation()
		removeCooldown("crouching")
		removeCooldown("crawling")
		if getCool("sit") then
			addCooldown("Attacking")
			removeCooldown("sit")
			Animations.Idle:Play(0.5, 1)
			game:GetService("TweenService"):Create(Humanoid, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {HipHeight=12.1}):Play()
			task.wait(0.5)
			Mover=true
			RunType=1
			Speed=13
			OriginalSpeed=Speed
			sprint=false
			removeCooldown("Attacking")
		else
			addCooldown("sit")
			addCooldown("Attacking")
			Animations.Sit:Play(0.5, 1)
			game:GetService("TweenService"):Create(Humanoid, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {HipHeight=0.07}):Play()
			task.wait(0.5)
			removeCooldown("Attacking")
		end
	elseif goal == "manual" then
		if not Hrp:FindFirstChild("roar") then
			addsound(randomsound(script.speech), Hrp).Name = "roar"
		end
	elseif goal == "manual2" then
		if not Hrp:FindFirstChild("theme") then
			addsound(script.theme, Hrp)
		end
	end
end)

spawn(function()
	while true do
		local vocals=script.vocals:GetChildren()
		if #vocals==0 then task.wait(10) continue end
		if Character.invis.Value==true then repeat task.wait() until Character.invis.Value==false end
		local vocal=vocals[math.random(1,#vocals)]:Clone()
		if vocal then
			vocal.Parent=Hrp
			vocal.PlaybackSpeed+=Random.new():NextNumber(-0.1, 0.2)
			vocal:Play()
			vocal.Ended:Wait()
			vocal:Destroy()
		end
		task.wait(math.random(6,15))
	end
end)
