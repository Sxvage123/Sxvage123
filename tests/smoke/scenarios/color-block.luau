-- Each turn, stand on a tile of the called colour.
return function(R, game, player)
	local ws = game:GetService("Workspace")
	R.advance(16)
	local turns = 0
	for _ = 1, 300 do
		local called = ws:GetAttribute("Called")
		if called and player:GetAttribute("InRound") then
			for _, t in ws.World:GetChildren() do
				if t.Name == "Tile" and t:GetAttribute("ColorName") == called and t.CanCollide then
					player.Character.HumanoidRootPart.CFrame = R.D.CFrame.new(t.Position + R.D.Vector3.new(0, 3, 0))
					break
				end
			end
			turns += 1
		end
		R.advance(0.5)
	end
	return string.format("colorblock: inRound=%s coins=%s turnsAlive=%d", tostring(player:GetAttribute("InRound")), tostring(player:GetAttribute("Coins")), turns)
end
