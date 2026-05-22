local Hitbox = script:WaitForChild("Hitbox").Value
local Ignore = script:WaitForChild("Ignore").Value
local hit = false


local hitbox = game:GetService("RunService").Heartbeat:Connect(function()
	for _, target in pairs(workspace:GetPartsInPart(Hitbox)) do
		if target and target.Parent and target.Parent:FindFirstChildWhichIsA("Humanoid") and target.Parent:FindFirstChild("HumanoidRootPart") and target.Parent ~= Ignore and not hit then
			hit = true
			local targetH = target.Parent
            script.Event:FireServer(targetH)
		end
	end
end)
