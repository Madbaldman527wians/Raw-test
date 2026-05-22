local plr = game.Players.LocalPlayer
repeat task.wait() until plr.Character

local char = plr.Character
local event = script.Parent:WaitForChild("RemoteEvent")
local Camera = workspace.CurrentCamera

local mouse = plr:GetMouse()

char:FindFirstChildWhichIsA("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

char:FindFirstChildWhichIsA("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)

char:FindFirstChildWhichIsA("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Physics, false)

local holding=false
mouse.Button1Down:Connect(function()
	event:FireServer({
		g = "attack",
	})
	holding = true
	repeat task.wait() 
		event:FireServer({
			g = "attack",
		}) 
	until not holding
end)
mouse.Button1Up:Connect(function()
	holding=false
end)

script.Parent:WaitForChild("RemoteFunction").OnClientInvoke = function()
	return plr:GetMouse().Hit.p, char:FindFirstChild("HumanoidRootPart").CFrame
end
local uis = game:GetService("UserInputService")
local tr = false

uis.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	
	if input.KeyCode == Enum.KeyCode.E then
		if tr == false then
			tr = true
			event:FireServer({
				g = "sprint",
				on = true
			})
		else
			tr = false
			event:FireServer({
				g = "sprint",
				on = false
			})
		end
	elseif input.KeyCode == Enum.KeyCode.R then
		event:FireServer({
			g = "attack3",
			
		})
	elseif input.KeyCode == Enum.KeyCode.T then
		event:FireServer({
			g = "placetv",

		})
	elseif input.KeyCode == Enum.KeyCode.Q then
		event:FireServer({
			g = "attack2",
		})
	elseif input.KeyCode == Enum.KeyCode.C then
		event:FireServer({
			g = "crouch",
		})
	elseif input.KeyCode == Enum.KeyCode.V then
		event:FireServer({
			g = "crawl",
		})
	elseif input.KeyCode == Enum.KeyCode.F then
		event:FireServer({
			g = "sit",
		})
	elseif input.KeyCode == Enum.KeyCode.G then
		event:FireServer({
			g = "manual",
		})
	elseif input.KeyCode == Enum.KeyCode.H then
		event:FireServer({
			g = "manual2",
		})
	end
end)


