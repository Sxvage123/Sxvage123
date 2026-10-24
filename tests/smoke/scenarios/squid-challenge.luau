-- Join a round, stand still through red lights and walk on green, cross the finish line.
return function(R, game, player)
	local ws = game:GetService("Workspace")
	R.advance(18) -- intermission + start
	local root = player.Character.HumanoidRootPart
	local z = root.Position.Z
	for _ = 1, 200 do
		if ws:GetAttribute("Light") == "Green" and z < 165 then
			z += 1.2
			root.CFrame = R.D.CFrame.new(0, 4, z)
		end
		R.advance(0.15)
		if not player:GetAttribute("InRound") then
			break
		end
	end
	local alive = player:GetAttribute("InRound")
	return string.format("squid: crossed z=%.0f inRound=%s stage=%s", z, tostring(alive), tostring(ws:GetAttribute("Stage")))
end
