-- Walk through 5 doors, search a drawer, summon Sahur while hiding (survive), then summon it while standing (die).
return function(R, game, player)
	R.advance(3)
	local ws = game:GetService("Workspace")
	local rs = game:GetService("ReplicatedStorage")
	local root = player.Character.HumanoidRootPart
	for i = 0, 4 do
		root.CFrame = R.D.CFrame.new(0, 3, i * 60 + 55)
		R.advance(0.6)
	end
	local door = ws:GetAttribute("Door")
	local hidePrompt, searchPrompt
	for _, d in ws.Hotel:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Name == "HidePrompt" and not hidePrompt then
			hidePrompt = d
		elseif d:IsA("ProximityPrompt") and d.Name == "SearchPrompt" and not searchPrompt then
			searchPrompt = d
		end
	end
	R.signalFor(searchPrompt, "Triggered"):Fire(player)
	R.signalFor(hidePrompt, "Triggered"):Fire(player)
	R.advance(0.2)
	local hiding = player:GetAttribute("Hiding")
	R.signalFor(rs.StudioTestPurchase, "OnServerEvent"):Fire(player, "Product", "SummonSahur")
	R.advance(14)
	local char = player.Character
	local hum = char.Humanoid
	local survivedHiding = hum.Health > 0
	R.signalFor(hidePrompt, "Triggered"):Fire(player) -- leave closet
	R.advance(0.5)
	R.signalFor(rs.StudioTestPurchase, "OnServerEvent"):Fire(player, "Product", "SummonSahur")
	R.advance(14)
	local died = hum.Health <= 0 or player.Character ~= char
	return string.format("hotel: door=%s hiding=%s survivedHiding=%s diedInOpen=%s knobs=%s", tostring(door), tostring(hiding), tostring(survivedHiding), tostring(died), tostring(player:GetAttribute("Knobs")))
end
