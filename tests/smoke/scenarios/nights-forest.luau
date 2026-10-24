-- Chop a tree, fuel the fire, then survive night 1 standing by the fire, then go stand in the dark on night 2.
return function(R, game, player)
	R.advance(3)
	local ws = game:GetService("Workspace")
	local root = player.Character.HumanoidRootPart
	local chop
	for _, d in ws.World:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Name == "ChopPrompt" then
			chop = d
			break
		end
	end
	R.signalFor(chop, "Triggered"):Fire(player)
	R.advance(0.2)
	local woodAfterChop = player:GetAttribute("Wood")
	local fuelBefore = ws:GetAttribute("Fuel")
	local fuelPrompt = ws.World.Campfire.Flame.FuelPrompt
	R.signalFor(fuelPrompt, "Triggered"):Fire(player)
	R.advance(0.2)
	local fuelAfter = ws:GetAttribute("Fuel")
	-- Stand by the fire through the first night.
	root.CFrame = R.D.CFrame.new(0, 3, 6)
	R.advance(60)
	-- Top the fire up just before dark the way a buyer would.
	R.signalFor(game:GetService("ReplicatedStorage").StudioTestPurchase, "OnServerEvent"):Fire(player, "Product", "FuelFire")
	R.advance(80)
	local diamonds = player:GetAttribute("Diamonds")
	local deadNight1 = player:GetAttribute("Dead")
	-- Night 2: stand far out in the dark and let Sahur find you.
	R.advance(10)
	local char = player.Character
	local hum = char.Humanoid
	char.HumanoidRootPart.CFrame = R.D.CFrame.new(150, 3, 150)
	R.advance(70)
	local caught = hum.Health <= 0 or player.Character ~= char
	return string.format("nights: wood=%s fuel %s->%s diamonds=%s deadN1=%s caughtN2=%s night=%s", tostring(woodAfterChop), tostring(fuelBefore), tostring(fuelAfter), tostring(diamonds), tostring(deadNight1), tostring(caught), tostring(ws:GetAttribute("Night")))
end
