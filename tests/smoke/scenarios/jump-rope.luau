-- Hover above the rope (as if jumping) for a while, then stand still and get tripped.
return function(R, game, player)
	R.advance(16)
	local root = player.Character.HumanoidRootPart
	for _ = 1, 40 do
		root.CFrame = R.D.CFrame.new(0, 8, 0)
		R.advance(0.25)
	end
	local jumps = player:GetAttribute("Jumps")
	root.CFrame = R.D.CFrame.new(0, 3, 0)
	R.advance(8)
	return string.format("rope: jumps=%s inRound=%s coins=%s", tostring(jumps), tostring(player:GetAttribute("InRound")), tostring(player:GetAttribute("Coins")))
end
