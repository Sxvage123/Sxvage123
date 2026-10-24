-- Walk to a suburb house and eat for a while, then buy a bite upgrade.
return function(R, game, player)
	R.advance(3)
	local ws = game:GetService("Workspace")
	local rs = game:GetService("ReplicatedStorage")
	local chunk
	for _, p in ws.City:GetChildren() do
		if p:IsA("BasePart") and p:GetAttribute("MinSize") == 0 then
			chunk = p
			break
		end
	end
	player.Character.HumanoidRootPart.CFrame = R.D.CFrame.new(chunk.Position + R.D.Vector3.new(0, 0, 6))
	for _ = 1, 20 do
		R.signalFor(rs.Remotes.Eat, "OnServerEvent"):Fire(player)
		R.advance(0.35)
	end
	local size = player:GetAttribute("Size")
	local up = rs.Remotes.Upgrade.OnServerInvoke(player, "Bite")
	return string.format("eat: size=%s coins=%s upgrade=%s scale=%.2f", tostring(size), tostring(player:GetAttribute("Coins")), tostring(up), player.Character:GetScale())
end
