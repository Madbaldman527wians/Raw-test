local model = script.Parent


for _, desc in ipairs(model:GetDescendants()) do
	if desc.Name == "HumanoidRootPart" and desc:IsA("BasePart") then
		desc.Anchored = false
	end
end

