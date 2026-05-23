-- put it inside StarterPlayer>StarterCharacterScripts
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local rootpart,head = char:WaitForChild("HumanoidRootPart"),char:WaitForChild("Head")
game:GetService("RunService"):BindToRenderStep("CameraOffset",Enum.RenderPriority.Camera.Value-1,function()
		game:GetService("TweenService"):Create(hum,TweenInfo.new(0.3),{CameraOffset = (rootpart.CFrame+Vector3.new(0,1.5,0)):pointToObjectSpace(head.CFrame.p)}):Play()
end)
