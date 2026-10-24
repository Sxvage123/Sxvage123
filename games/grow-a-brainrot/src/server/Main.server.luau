-- Grow a Brainrot server: gardens, rotating seed shop, harvesting, mutations, weather, selling.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local function remote(className: string, name: string): any
	local r = Instance.new(className)
	r.Name = name
	r.Parent = remotes
	return r
end
local NotifyRemote = remote("RemoteEvent", "Notify")
local SeedsRemote = remote("RemoteEvent", "Seeds")
local SelectSeedRemote = remote("RemoteEvent", "SelectSeed")
local GetShopRemote = remote("RemoteFunction", "GetShop")
local BuySeedRemote = remote("RemoteFunction", "BuySeed")
local SellRemote = remote("RemoteFunction", "SellAll")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

---------------------------------------------------------------- world

local world = Instance.new("Folder")
world.Name = "World"
world.Parent = workspace

local function part(props, parent: Instance?): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent or world
	return p
end

local function billboard(adornee: BasePart, text: string, color: Color3, offset: number): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 50)
	gui.StudsOffset = Vector3.new(0, offset, 0)
	gui.MaxDistance = 60
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Parent = label
	label.Parent = gui
	return label
end

Lighting.ClockTime = 13
Lighting.Brightness = 2.5
part({ Name = "Ground", Size = Vector3.new(500, 2, 400), Position = Vector3.new(0, -1, 0), Color = Color3.fromRGB(100, 200, 90), Material = Enum.Material.Grass })
part({ Name = "Path", Size = Vector3.new(400, 0.2, 24), Position = Vector3.new(0, 0.1, 0), Color = Color3.fromRGB(210, 180, 130), Material = Enum.Material.Sand })

local function stand(name: string, position: Vector3, color: Color3, actionText: string): (BasePart, ProximityPrompt)
	local counter = part({ Name = name, Size = Vector3.new(14, 4, 6), Position = position + Vector3.new(0, 2, 0), Color = color, Material = Enum.Material.WoodPlanks })
	part({ Name = "Roof", Size = Vector3.new(16, 1, 10), Position = position + Vector3.new(0, 10, 0), Color = color:Lerp(Color3.new(1, 1, 1), 0.3) })
	for _, x in { -6.5, 6.5 } do
		part({ Size = Vector3.new(1, 8, 1), Position = position + Vector3.new(x, 5, 0), Color = Color3.fromRGB(120, 80, 40) })
	end
	billboard(counter, name, Color3.new(1, 1, 1), 10)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = name
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter
	return counter, prompt
end
local seedStand, seedPrompt = stand("Seed Shop", Vector3.new(-25, 0, 0), Color3.fromRGB(80, 170, 60), "Open Shop")
local sellStand, sellPrompt = stand("Sell Stand", Vector3.new(25, 0, 0), Color3.fromRGB(230, 170, 40), "Sell All Fruit")
seedPrompt.Name = "SeedShopPrompt"

local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = Vector3.new(0, 0.5, 0)
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Neutral = true
spawn.Parent = world

local TOTAL_SPOTS = Config.BaseSpots + Config.ExtraSpots
local plots = {}
do
	local i = 0
	for _, z in { 75, -75 } do
		for _, x in { -100, 0, 100 } do
			i += 1
			local cf = CFrame.lookAt(Vector3.new(x, 0, z), Vector3.new(x, 0, 0))
			local model = Instance.new("Model")
			model.Name = "Garden" .. i
			model.Parent = world
			part({ Name = "Grass", Size = Vector3.new(72, 1, 58), CFrame = cf * CFrame.new(0, 0.5, 0), Color = Color3.fromRGB(80, 170, 70), Material = Enum.Material.Grass }, model)
			for _, sx in { -1, 1 } do
				part({ Name = "Fence", Size = Vector3.new(1, 3, 58), CFrame = cf * CFrame.new(sx * 36, 2, 0), Color = Color3.fromRGB(240, 240, 240) }, model)
			end
			part({ Name = "Fence", Size = Vector3.new(72, 3, 1), CFrame = cf * CFrame.new(0, 2, 29), Color = Color3.fromRGB(240, 240, 240) }, model)
			local signPart = part({ Name = "Sign", Size = Vector3.new(16, 4, 1), CFrame = cf * CFrame.new(0, 4, -31), Color = Color3.fromRGB(150, 100, 50) }, model)
			local signLabel = billboard(signPart, "Empty Garden", Color3.new(1, 1, 1), 4)

			local spots = {}
			for index = 1, TOTAL_SPOTS do
				local row = math.floor((index - 1) / 6)
				local col = (index - 1) % 6
				local spotCF = cf * CFrame.new((col - 2.5) * 10, 1.1, -20 + row * 8)
				local soil = part({
					Name = "Spot" .. index,
					Size = Vector3.new(7, 0.4, 6),
					CFrame = spotCF,
					Color = if index > Config.BaseSpots then Color3.fromRGB(150, 110, 40) else Color3.fromRGB(110, 70, 40),
					Material = Enum.Material.Ground,
				}, model)
				soil:SetAttribute("Spot", index)
				CollectionService:AddTag(soil, "Soil")
				soil:SetAttribute("Locked", index > Config.BaseSpots)
				local function prompt(name, action, key, hold)
					local p = Instance.new("ProximityPrompt")
					p.Name = name
					p.ActionText = action
					p.KeyboardKeyCode = key
					p.HoldDuration = hold
					p.MaxActivationDistance = 9
					p.RequiresLineOfSight = false
					p.Parent = soil
					return p
				end
				spots[index] = {
					Soil = soil,
					PlantPrompt = prompt("PlantPrompt", "Plant", Enum.KeyCode.E, 0),
					HarvestPrompt = prompt("HarvestPrompt", "Harvest", Enum.KeyCode.E, 0),
					ShovelPrompt = prompt("ShovelPrompt", "Dig Up", Enum.KeyCode.X, 1.5),
					Label = billboard(soil, "", Color3.new(1, 1, 1), 6),
					Visual = nil,
				}
			end
			table.insert(plots, { Index = i, CFrame = cf, Spots = spots, SignLabel = signLabel, Owner = nil, SpawnCFrame = cf * CFrame.new(0, 4, -26) })
		end
	end
end

---------------------------------------------------------------- shop stock

local stock: { [string]: number } = {}
local rotation = 0
-- Saved per player so stock limits reset each rotation; includes JobId so another server's
-- rotation 1 is never confused with this one.
local rotationKey = ""

local function restock()
	rotation += 1
	rotationKey = game.JobId .. ":" .. rotation
	table.clear(stock)
	for _, seed in Config.Seeds do
		if math.random() <= seed.StockChance then
			stock[seed.Id] = math.random(math.max(1, math.ceil(seed.Stock / 2)), seed.Stock)
		end
	end
	workspace:SetAttribute("Rotation", rotation)
	workspace:SetAttribute("NextRestock", os.time() + Config.RestockEvery)
	for id, count in stock do
		local seed = Config.SeedById[id]
		if seed.Rarity == "Mythic" or seed.Rarity == "Secret" then
			notify(nil, seed.Name .. " x" .. count .. " is in the Seed Shop!", Config.Rarities[seed.Rarity])
		end
	end
end
restock()

local function remaining(data, seedId: string): number
	local bought = if data.Bought.R == rotationKey then (data.Bought.C[seedId] or 0) else 0
	return math.max(0, (stock[seedId] or 0) - bought)
end

---------------------------------------------------------------- player helpers

local playerPlot: { [Player]: any } = {}

local function sendSeeds(player: Player)
	local data = DataService.Get(player)
	if data then
		SeedsRemote:FireClient(player, data.Seeds)
	end
end

local function syncStats(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local total = 0
	for _, fruit in data.Fruits do
		total += Config.FruitValue(fruit)
	end
	if MonetizationService.OwnsPass(player, "DoubleSell") then
		total *= 2
	end
	player:SetAttribute("Cash", data.Cash)
	player:SetAttribute("FruitCount", #data.Fruits)
	player:SetAttribute("FruitValue", total)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Cash.Value = Format.Cash(data.Cash)
	end
end

local function spotLimit(player: Player): number
	return Config.BaseSpots + (if MonetizationService.OwnsPass(player, "MoreSpots") then Config.ExtraSpots else 0)
end

---------------------------------------------------------------- plants

local function clearVisual(spot)
	if spot.Visual then
		spot.Visual:Destroy()
		spot.Visual = nil
	end
end

local function renderSpot(plot, index: number, plant)
	local spot = plot.Spots[index]
	local soil = spot.Soil
	if not plant then
		clearVisual(spot)
		spot.Label.Text = ""
		soil:SetAttribute("State", "Empty")
		return
	end
	local seed = Config.SeedById[plant.S]
	local now = os.time()
	local progress = math.clamp((now - plant.T) / plant.G, 0, 1)
	local ready = progress >= 1
	soil:SetAttribute("State", if ready then "Ready" else "Growing")

	if not spot.Visual then
		local model = Instance.new("Model")
		model.Name = "Plant"
		local stem = part({ Name = "Stem", Size = Vector3.new(0.6, 1, 0.6), Color = Color3.fromRGB(60, 160, 50), CanCollide = false, CanQuery = false }, model)
		local fruit = part({ Name = "Fruit", Shape = Enum.PartType.Ball, Size = Vector3.one * 2, Color = seed.Color, CanCollide = false, CanQuery = false, Transparency = 1 }, model)
		model.Parent = soil
		spot.Visual = model
		spot.Stem = stem
		spot.Fruit = fruit
	end
	local height = 0.5 + progress * 3.5
	spot.Stem.Size = Vector3.new(0.6, height, 0.6)
	spot.Stem.CFrame = soil.CFrame * CFrame.new(0, 0.2 + height / 2, 0)
	local fruitSize = 0.6 + progress * 1.6
	spot.Fruit.Size = Vector3.one * fruitSize
	spot.Fruit.CFrame = soil.CFrame * CFrame.new(0, 0.2 + height + fruitSize / 2 - 0.2, 0)
	spot.Fruit.Transparency = if progress > 0.3 then 0 else 1
	spot.Fruit.Material = if ready then Enum.Material.Neon else Enum.Material.SmoothPlastic

	if ready then
		spot.Label.Text = seed.Name .. "\nREADY!"
		spot.Label.TextColor3 = Color3.fromRGB(120, 255, 120)
	else
		spot.Label.Text = seed.Name .. "\n" .. Format.Time(plant.T + plant.G - now)
		spot.Label.TextColor3 = Config.Rarities[seed.Rarity]
	end
end

local function renderPlot(player: Player)
	local plot = playerPlot[player]
	local data = DataService.Get(player)
	if not plot or not data then
		return
	end
	local limit = spotLimit(player)
	for index, spot in plot.Spots do
		spot.Soil:SetAttribute("Locked", index > limit)
		renderSpot(plot, index, data.Plants[tostring(index)])
	end
end

local function growTime(player: Player, seconds: number): number
	if MonetizationService.OwnsPass(player, "FastGrow") then
		return math.ceil(seconds / Config.FastGrowFactor)
	end
	return seconds
end

local function rollMutation(player: Player): string?
	local luck = if MonetizationService.OwnsPass(player, "LuckyHarvest") then 2 else 1
	local weather = Config.Weathers[workspace:GetAttribute("Weather") or ""]
	local active = weather and (workspace:GetAttribute("WeatherUntil") or 0) > os.time()
	-- Rarest first so the best mutation wins.
	local order = { "Shocked", "Rainbow", "Brainrotted", "Gold", "Wet" }
	for _, id in order do
		local m = Config.MutationById[id]
		local chance = m.Chance
		if active and weather.Boosts[id] then
			chance += weather.Boosts[id]
		end
		if math.random() < chance * luck then
			return id
		end
	end
	return nil
end

local function rollWeight(): number
	local w = 0.7 + math.random() * 0.8
	if math.random() < 0.03 then
		w *= 3 -- huge fruit!
	end
	return math.floor(w * 100) / 100
end

for _, plot in plots do
	for index, spot in plot.Spots do
		spot.PlantPrompt.Triggered:Connect(function(player)
			if plot.Owner ~= player then
				return
			end
			local data = DataService.Get(player)
			local key = tostring(index)
			if not data or data.Plants[key] then
				return
			end
			if index > spotLimit(player) then
				notify(player, "Unlock this spot with +12 Garden Spots!", Color3.fromRGB(255, 200, 0))
				return
			end
			local seedId = player:GetAttribute("SelectedSeed")
			if not seedId or (data.Seeds[seedId] or 0) <= 0 then
				notify(player, "Pick a seed from your hotbar first! Buy seeds at the Seed Shop.", Color3.fromRGB(255, 90, 90))
				return
			end
			local seed = Config.SeedById[seedId]
			data.Seeds[seedId] -= 1
			if data.Seeds[seedId] <= 0 then
				data.Seeds[seedId] = nil
			end
			data.Plants[key] = { S = seedId, T = os.time(), G = growTime(player, seed.Grow), H = 0 }
			renderSpot(plot, index, data.Plants[key])
			sendSeeds(player)
		end)

		spot.HarvestPrompt.Triggered:Connect(function(player)
			if plot.Owner ~= player then
				return
			end
			local data = DataService.Get(player)
			local key = tostring(index)
			local plant = data and data.Plants[key]
			if not plant or os.time() < plant.T + plant.G then
				return
			end
			if #data.Fruits >= Config.FruitCap then
				notify(player, "Your basket is full! Go sell your fruit.", Color3.fromRGB(255, 90, 90))
				return
			end
			local seed = Config.SeedById[plant.S]
			local fruit = { S = plant.S, M = rollMutation(player), W = rollWeight() }
			table.insert(data.Fruits, fruit)
			data.Harvests += 1
			if fruit.M then
				local m = Config.MutationById[fruit.M]
				local message = fruit.M .. " " .. seed.Name .. "! (" .. Format.Cash(Config.FruitValue(fruit)) .. ")"
				notify(player, message, m.Color)
				if m.Mult >= 30 then
					notify(nil, player.DisplayName .. " harvested a " .. message, m.Color)
				end
			end
			if seed.Regrow then
				plant.T = os.time()
				plant.G = growTime(player, seed.Regrow)
				plant.H += 1
			else
				data.Plants[key] = nil
			end
			renderSpot(plot, index, data.Plants[key])
			syncStats(player)
		end)

		spot.ShovelPrompt.Triggered:Connect(function(player)
			if plot.Owner ~= player then
				return
			end
			local data = DataService.Get(player)
			if data and data.Plants[tostring(index)] then
				data.Plants[tostring(index)] = nil
				renderSpot(plot, index, nil)
			end
		end)
	end
end

---------------------------------------------------------------- shop + selling

GetShopRemote.OnServerInvoke = function(player)
	local data = DataService.Get(player)
	if not data then
		return {}
	end
	local result = {}
	for id in stock do
		result[id] = remaining(data, id)
	end
	return result
end

BuySeedRemote.OnServerInvoke = function(player, seedId)
	local data = DataService.Get(player)
	local seed = type(seedId) == "string" and Config.SeedById[seedId]
	if not data or not seed then
		return false, "Invalid seed"
	end
	if (seedStand.Position - (player.Character and player.Character:GetPivot().Position or Vector3.zero)).Magnitude > 30 then
		return false, "Walk to the Seed Shop!"
	end
	if remaining(data, seedId) <= 0 then
		return false, "Out of stock! Restock in " .. Format.Time((workspace:GetAttribute("NextRestock") or 0) - os.time())
	end
	if data.Cash < seed.Price then
		return false, "Need " .. Format.Cash(seed.Price) .. "!"
	end
	if data.Bought.R ~= rotationKey then
		data.Bought = { R = rotationKey, C = {} }
	end
	data.Bought.C[seedId] = (data.Bought.C[seedId] or 0) + 1
	data.Cash -= seed.Price
	data.Seeds[seedId] = (data.Seeds[seedId] or 0) + 1
	if not player:GetAttribute("SelectedSeed") then
		player:SetAttribute("SelectedSeed", seedId)
	end
	syncStats(player)
	sendSeeds(player)
	return true, "Bought " .. seed.Name .. "!"
end

local function sellAll(player: Player): (boolean, string)
	local data = DataService.Get(player)
	if not data or #data.Fruits == 0 then
		return false, "No fruit to sell! Harvest your plants first."
	end
	local total = 0
	for _, fruit in data.Fruits do
		total += Config.FruitValue(fruit)
	end
	if MonetizationService.OwnsPass(player, "DoubleSell") then
		total *= 2
	end
	table.clear(data.Fruits)
	data.Cash += total
	data.TotalEarned += total
	syncStats(player)
	return true, "Sold for " .. Format.Cash(total) .. "!"
end

sellPrompt.Triggered:Connect(function(player)
	local ok, message = sellAll(player)
	notify(player, message, if ok then Color3.fromRGB(90, 255, 90) else Color3.fromRGB(255, 90, 90))
end)

SellRemote.OnServerInvoke = function(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local near = root and (root.Position - sellStand.Position).Magnitude < 25
	if not near and not MonetizationService.OwnsPass(player, "SellAnywhere") then
		return false, "NeedPass"
	end
	return sellAll(player)
end

SelectSeedRemote.OnServerEvent:Connect(function(player, seedId)
	if type(seedId) == "string" and Config.SeedById[seedId] then
		player:SetAttribute("SelectedSeed", seedId)
	end
end)

---------------------------------------------------------------- weather

local function startWeather(key: string)
	workspace:SetAttribute("Weather", key)
	workspace:SetAttribute("WeatherUntil", os.time() + Config.WeatherDuration)
	notify(nil, Config.Weathers[key].Name .. " started! Harvest now for mutations!", Color3.fromRGB(150, 200, 255))
end

task.spawn(function()
	while true do
		task.wait(Config.WeatherEvery)
		local roll = math.random()
		startWeather(if roll < 0.6 then "Rain" elseif roll < 0.9 then "Thunder" else "Brainrot")
	end
end)

task.spawn(function()
	while true do
		local now = os.time()
		if now >= (workspace:GetAttribute("NextRestock") or 0) then
			restock()
			notify(nil, "Seed Shop restocked!", Color3.fromRGB(120, 255, 120))
		end
		local active = (workspace:GetAttribute("WeatherUntil") or 0) > now
		local weather = workspace:GetAttribute("Weather")
		Lighting.ClockTime = if active then 18.2 else 13
		Lighting.Ambient = if active and weather == "Brainrot" then Color3.fromRGB(120, 0, 160) else Color3.fromRGB(70, 70, 70)
		for player in playerPlot do
			renderPlot(player)
			local data = DataService.Get(player)
			if data then
				data.PlaySeconds += 1
			end
		end
		task.wait(1)
	end
end)

---------------------------------------------------------------- players

local function claimPlot(player: Player)
	for _, plot in plots do
		if not plot.Owner then
			plot.Owner = player
			plot.SignLabel.Text = player.DisplayName .. "'s Garden"
			playerPlot[player] = plot
			for _, spot in plot.Spots do
				spot.Soil:SetAttribute("OwnerId", player.UserId)
			end
			return plot
		end
	end
	return nil
end

local function releasePlot(player: Player)
	local plot = playerPlot[player]
	if not plot then
		return
	end
	playerPlot[player] = nil
	plot.Owner = nil
	plot.SignLabel.Text = "Empty Garden"
	for index, spot in plot.Spots do
		spot.Soil:SetAttribute("OwnerId", 0)
		renderSpot(plot, index, nil)
	end
end

DataService.ProfileLoaded:Connect(function(player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = stats
	stats.Parent = player
	if data.LoginCount == 1 then
		for id, count in Config.StartingSeeds do
			data.Seeds[id] = (data.Seeds[id] or 0) + count
		end
	end
	for key, plant in data.Plants do
		if not Config.SeedById[plant.S] then
			data.Plants[key] = nil
		end
	end
	local plot = claimPlot(player)
	if not plot then
		notify(player, "All gardens are taken! Try another server.", Color3.fromRGB(255, 90, 90))
	end
	local first = next(data.Seeds)
	if first then
		player:SetAttribute("SelectedSeed", first)
	end
	syncStats(player)
	sendSeeds(player)
	renderPlot(player)
	local function onCharacter(character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait()
		if playerPlot[player] then
			character:PivotTo(playerPlot[player].SpawnCFrame)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	task.defer(releasePlot, player)
end)

---------------------------------------------------------------- monetization

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		Restock = function(player)
			restock()
			notify(nil, player.DisplayName .. " RESTOCKED the Seed Shop for everyone!", Color3.fromRGB(120, 255, 120))
			return true
		end,
		GrowAll = function(player, data)
			local now = os.time()
			for _, plant in data.Plants do
				plant.T = now - plant.G
			end
			renderPlot(player)
			notify(player, "Everything grew instantly!", Color3.fromRGB(120, 255, 120))
			return true
		end,
		MythicSeed = function(player, data)
			local pool = {}
			for _, seed in Config.Seeds do
				if seed.Rarity == "Mythic" then
					table.insert(pool, seed.Id)
				end
			end
			local id = if math.random() < 0.1 then "sigma_bean" else pool[math.random(1, #pool)]
			data.Seeds[id] = (data.Seeds[id] or 0) + 1
			sendSeeds(player)
			notify(player, "You got a " .. Config.SeedById[id].Name .. " seed!", Config.Rarities[Config.SeedById[id].Rarity])
			return true
		end,
		Weather = function(player)
			startWeather("Brainrot")
			notify(nil, player.DisplayName .. " summoned a BRAINROT STORM!", Color3.fromRGB(180, 0, 255))
			return true
		end,
		CashPack = function(player, data)
			local rate = if data.PlaySeconds > 60 then data.TotalEarned / data.PlaySeconds else 0
			local amount = math.max(10_000, math.floor(rate * 1800))
			data.Cash += amount
			syncStats(player)
			notify(player, "+" .. Format.Cash(amount) .. "!", Color3.fromRGB(90, 255, 90))
			return true
		end,
	},
	OnPassOwned = function(player, name)
		renderPlot(player)
		syncStats(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("GrowABrainrot_v1", {
	Cash = Config.StartingCash,
	Seeds = {},
	Plants = {},
	Fruits = {},
	Bought = { R = "", C = {} },
	TotalEarned = 0,
	Harvests = 0,
	PlaySeconds = 0,
})
