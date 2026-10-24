-- Gain speed for a while, run through the first two finish lines, buy a trail, rebirth.
return function(R, game, player)
	R.advance(5)
	local ws = game:GetService("Workspace")
	local root = player.Character.HumanoidRootPart
	local speedBefore = player:GetAttribute("Speed")
	for _, name in { "Finish1", "Finish2", "Finish3" } do
		local line = ws.World:FindFirstChild(name)
		R.signalFor(line, "Touched"):Fire(root)
		R.advance(0.2)
	end
	local wins = player:GetAttribute("Wins")
	R.signalFor(ws.World.Finish1, "Touched"):Fire(root) -- already claimed this run: no wins
	R.advance(0.2)
	local again = player:GetAttribute("Wins")
	local remotes = game:GetService("ReplicatedStorage").Remotes
	local bought = remotes.BuyTrail.OnServerInvoke(player, "basic")
	return string.format("speed: speed=%s wins=%s again=%s trail=%s/%s walk=%s", tostring(speedBefore), tostring(wins), tostring(again), tostring(bought), tostring(player:GetAttribute("Trail")), tostring(player.Character.Humanoid.WalkSpeed))
end
