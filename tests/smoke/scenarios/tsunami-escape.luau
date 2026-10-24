-- Walk out, grab a brainrot, bring it home, then get caught by the tsunami while out on the beach.
return function(R, game, player)
	R.advance(4)
	local ws = game:GetService("Workspace")
	local root = player.Character.HumanoidRootPart
	local prompt
	for _, d in ws.BeachBrainrots:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Name == "GrabPrompt" then
			prompt = d
			break
		end
	end
	root.CFrame = prompt.Parent.CFrame
	R.signalFor(prompt, "Triggered"):Fire(player)
	R.advance(0.2)
	local carried = player:GetAttribute("Carrying")
	root.CFrame = R.D.CFrame.new(0, 4, -30)
	R.advance(1.5)
	local income = player:GetAttribute("Income")
	-- Stand out on the beach and wait for the wave.
	root.CFrame = R.D.CFrame.new(0, 4, 600)
	local char = player.Character
	local hum = char.Humanoid
	R.advance(70)
	-- Next wave: hide in a shelter and survive.
	R.advance(3)
	local shelter = ws.World:FindFirstChild("Shelter")
	local char2 = player.Character
	char2.HumanoidRootPart.CFrame = R.D.CFrame.new(shelter.Position.X, 3, shelter.Position.Z)
	R.advance(50)
	local survived = player.Character == char2 and char2.Humanoid.Health > 0
	return string.format("tsunami: carried=%s income=%s waveIn=%s health=%s respawned=%s shelterSurvived=%s", tostring(carried), tostring(income), tostring(ws:GetAttribute("WaveIn")), tostring(hum.Health), tostring(player.Character ~= char), tostring(survived))
end
