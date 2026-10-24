-- Bake at the first oven, wait for a customer to sit, serve them.
return function(R, game, player)
	R.advance(10) -- customers arrive and sit
	local ovenPrompt, servePrompt
	for _, d in game:GetService("Workspace"):GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Name == "OvenPrompt" and not ovenPrompt then
			ovenPrompt = d
		end
	end
	R.signalFor(ovenPrompt, "Triggered"):Fire(player)
	R.advance(8)
	for _, d in game:GetService("Workspace"):GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Name == "ServePrompt" and d.Enabled then
			servePrompt = d
			break
		end
	end
	if servePrompt then
		R.signalFor(servePrompt, "Triggered"):Fire(player)
	end
	R.advance(1)
	return string.format("pizza: servePrompt=%s served=%s cash=%s", tostring(servePrompt ~= nil), tostring(player:GetAttribute("Served")), tostring(player:GetAttribute("Cash")))
end
