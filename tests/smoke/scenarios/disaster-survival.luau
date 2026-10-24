-- Pick Lava as the next disaster, stand on the ground (should die), then the next round stand on a roof.
return function(R, game, player)
	local rs = game:GetService("ReplicatedStorage")
	local ws = game:GetService("Workspace")
	R.signalFor(rs.Remotes.Choose, "OnServerEvent"):Fire(player, "Lava")
	R.signalFor(rs.StudioTestPurchase, "OnServerEvent"):Fire(player, "Product", "ChooseDisaster")
	R.advance(16) -- intermission
	local inRound = player:GetAttribute("InRound")
	local char = player.Character
	local hum = char.Humanoid
	R.advance(9)
	local disaster = ws:GetAttribute("Disaster")
	char.HumanoidRootPart.CFrame = R.D.CFrame.new(10, 3, 10)
	R.advance(20)
	local diedOnLava = hum.Health <= 0 or player.Character ~= char
	R.advance(40)
	-- Round 2: whatever it is, stand on top of a tower.
	R.signalFor(rs.Remotes.Choose, "OnServerEvent"):Fire(player, "Flood")
	R.signalFor(rs.StudioTestPurchase, "OnServerEvent"):Fire(player, "Product", "ChooseDisaster")
	repeat
		R.advance(1)
	until ws:GetAttribute("Stage") == "Warning"
	R.advance(1)
	player.Character.HumanoidRootPart.CFrame = R.D.CFrame.new(75, 38, 0)
	R.advance(60)
	return string.format("disaster: inRound=%s first=%s diedOnLava=%s wins=%s coins=%s", tostring(inRound), tostring(disaster), tostring(diedOnLava), tostring(player:GetAttribute("Wins")), tostring(player:GetAttribute("Coins")))
end
