-- Solo: you're the seeker with nobody to find, so the round ends right away with a seeker win.
return function(R, game, player)
	local ws = game:GetService("Workspace")
	R.advance(17)
	local role = player:GetAttribute("Role")
	R.advance(25)
	return string.format("hideseek: role=%s stage=%s wins=%s", tostring(role), tostring(ws:GetAttribute("Stage")), tostring(player:GetAttribute("Wins")))
end
