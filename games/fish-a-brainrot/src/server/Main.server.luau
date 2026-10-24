-- Fish a Brainrot server: casting, bites, catches, rods, selling, totems.
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
local CastRemote = remote("RemoteFunction", "Cast")
local BiteRemote = remote("RemoteEvent", "Bite")
local ReelRemote = remote("RemoteEvent", "Reel")
local SellRemote = remote("RemoteFunction", "Sell")
local BuyRodRemote = remote("RemoteFunction", "BuyRod")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

---------------------------------------------------------------- world

Lighting.ClockTime = 16.5
Lighting.Brightness = 2.5
workspace.Terrain:FillBlock(CFrame.new(0, -10, 0), Vector3.new(1000, 20, 1000), Enum.Material.Water)
workspace.Terrain.WaterColor = Color3.fromRGB(40, 140, 200)
workspace.Terrain.WaterWaveSize = 0.3

local world = Instance.new("Folder")
world.Name = "World"
world.Parent = workspace
local function part(props): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = world
	return p
end
local function billboard(adornee: BasePart, text: string, offset: number)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 50)
	gui.StudsOffset = Vector3.new(0, offset, 0)
	gui.MaxDistance = 80
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Parent = label
	label.Parent = gui
end

part({ Name = "Island", Shape = Enum.PartType.Cylinder, Size = Vector3.new(14, 140, 140), CFrame = CFrame.new(0, -5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(230, 210, 150), Material = Enum.Material.Sand })
part({ Name = "Grass", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 110, 110), CFrame = CFrame.new(0, 2.2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(100, 200, 90), Material = Enum.Material.Grass })
for i = 0, 3 do
	local angle = i * math.pi / 2
	local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
	part({
		Name = "Dock",
		Size = Vector3.new(10, 1, 50),
		CFrame = CFrame.lookAt(dir * 90 + Vector3.new(0, 2, 0), dir * 200 + Vector3.new(0, 2, 0)),
		Color = Color3.fromRGB(140, 95, 55),
		Material = Enum.Material.WoodPlanks,
	})
end
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = Vector3.new(0, 3, 0)
spawn.Neutral = true
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Parent = world

local function stand(name: string, position: Vector3, color: Color3, action: string): ProximityPrompt
	local counter = part({ Name = name, Size = Vector3.new(12, 4, 5), Position = position + Vector3.new(0, 2, 0), Color = color, Material = Enum.Material.WoodPlanks })
	part({ Size = Vector3.new(14, 1, 8), Position = position + Vector3.new(0, 9, 0), Color = color:Lerp(Color3.new(1, 1, 1), 0.3) })
	billboard(counter, name, 9)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name:gsub(" ", "") .. "Prompt"
	prompt.ActionText = action
	prompt.ObjectText = name
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter
	return prompt
end
local sellPrompt = stand("Fish Merchant", Vector3.new(20, 2.7, -15), Color3.fromRGB(230, 170, 40), "Sell All Fish")
stand("Rod Shop", Vector3.new(-20, 2.7, -15), Color3.fromRGB(80, 160, 255), "Browse Rods")
local merchantPos = Vector3.new(20, 2.7, -15)

---------------------------------------------------------------- data helpers

local casts: { [Player]: any } = {}

local function rodOf(data)
	return Config.RodById[data.Rod] or Config.Rods[1]
end

local function luck(player: Player, data): number
	local l = rodOf(data).Luck
	if MonetizationService.OwnsPass(player, "Lucky") then
		l *= 1.5
	end
	if (workspace:GetAttribute("TotemUntil") or 0) > os.time() then
		l *= 3
	end
	return l
end

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local value = 0
	for _, entry in data.Fish do
		value += Config.FishValue(entry)
	end
	if MonetizationService.OwnsPass(player, "DoubleSell") then
		value *= 2
	end
	player:SetAttribute("Cash", data.Cash)
	player:SetAttribute("FishCount", #data.Fish)
	player:SetAttribute("FishValue", value)
	player:SetAttribute("Rod", data.Rod)
	player:SetAttribute("Bait", data.Bait)
	player:SetAttribute("Luck", luck(player, data))
	local owned = {}
	for id in data.Rods do
		table.insert(owned, id)
	end
	player:SetAttribute("OwnedRods", table.concat(owned, ","))
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Cash.Value = Format.Cash(data.Cash)
		stats.Caught.Value = data.Caught
	end
end

local function giveRod(player: Player)
	local data = DataService.Get(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not data or not backpack then
		return
	end
	for _, container in { backpack, player.Character } do
		local old = container and container:FindFirstChild("Rod")
		if old then
			old:Destroy()
		end
	end
	local rod = rodOf(data)
	local tool = Instance.new("Tool")
	tool.Name = "Rod"
	tool.ToolTip = rod.Name
	tool.CanBeDropped = false
	tool.GripPos = Vector3.new(0, -2, 0)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.3, 6, 0.3)
	handle.Color = rod.Color
	handle.Material = if rod.Id == "golden" or rod.Id == "sigma" then Enum.Material.Neon else Enum.Material.Wood
	handle.CanCollide = false
	handle.Parent = tool
	local tip = Instance.new("Attachment")
	tip.Name = "Tip"
	tip.Position = Vector3.new(0, 3, 0)
	tip.Parent = handle
	tool.Parent = backpack
end

local function clearCast(player: Player)
	local c = casts[player]
	if c then
		if c.Bobber then
			c.Bobber:Destroy()
		end
		casts[player] = nil
	end
end

local function rollFish(l: number)
	local total = 0
	for i, r in Config.Rarities do
		total += r.Weight * (if i >= 3 then l else 1)
	end
	local roll = math.random() * total
	local rarity = Config.Rarities[1]
	for i, r in Config.Rarities do
		roll -= r.Weight * (if i >= 3 then l else 1)
		if roll <= 0 then
			rarity = r
			break
		end
	end
	local pool = Config.FishByRarity[rarity.Name]
	return pool[math.random(1, #pool)]
end

---------------------------------------------------------------- fishing

local waterParams = RaycastParams.new()
waterParams.IgnoreWater = false
waterParams.FilterType = Enum.RaycastFilterType.Exclude

CastRemote.OnServerInvoke = function(player, target)
	local data = DataService.Get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local tool = character and character:FindFirstChild("Rod")
	if not data or not root or not tool or typeof(target) ~= "Vector3" then
		return false, "Equip your rod!"
	end
	if (target - root.Position).Magnitude > Config.MaxCastDistance then
		return false, "Too far!"
	end
	if #data.Fish >= Config.InventoryCap then
		return false, "Your bag is full! Sell your fish."
	end
	-- First thing hit from above must be terrain water (the island sits on top of water terrain).
	waterParams.FilterDescendantsInstances = { character }
	local hit = workspace:Raycast(target + Vector3.new(0, 10, 0), Vector3.new(0, -30, 0), waterParams)
	if not hit or hit.Material ~= Enum.Material.Water then
		return false, "Cast into the water!"
	end
	clearCast(player)

	local bobber = Instance.new("Part")
	bobber.Name = "Bobber"
	bobber.Shape = Enum.PartType.Ball
	bobber.Size = Vector3.one * 0.8
	bobber.Color = Color3.fromRGB(255, 50, 50)
	bobber.Anchored = true
	bobber.CanCollide = false
	bobber.Position = hit.Position + Vector3.new(0, 0.2, 0)
	local a1 = Instance.new("Attachment")
	a1.Parent = bobber
	local tip = tool:FindFirstChild("Handle") and tool.Handle:FindFirstChild("Tip")
	if tip then
		local beam = Instance.new("Beam")
		beam.Attachment0 = tip
		beam.Attachment1 = a1
		beam.Width0 = 0.05
		beam.Width1 = 0.05
		beam.Color = ColorSequence.new(Color3.new(1, 1, 1))
		beam.FaceCamera = true
		beam.Parent = bobber
	end
	bobber.Parent = workspace

	local rod = rodOf(data)
	local baited = data.Bait > 0
	if baited then
		data.Bait -= 1
	end
	local wait = if baited then 0.8 else (2 + math.random() * 6) / rod.Speed
	local cast = { Bobber = bobber, Phase = "Waiting", Baited = baited }
	casts[player] = cast
	sync(player)
	task.delay(wait, function()
		if casts[player] ~= cast then
			return
		end
		local l = luck(player, data) * (if baited then 3 else 1)
		local fish = rollFish(l)
		cast.Fish = fish
		cast.Phase = "Bite"
		cast.BiteAt = os.clock()
		bobber.Position -= Vector3.new(0, 0.6, 0)
		local rarity = Config.RarityByName[fish.Rarity]
		BiteRemote:FireClient(player, rarity.Name, rarity.Difficulty, rod.Control)
	end)
	return true
end

ReelRemote.OnServerEvent:Connect(function(player, success)
	local cast = casts[player]
	local data = DataService.Get(player)
	if not cast or cast.Phase ~= "Bite" or not data then
		clearCast(player)
		return
	end
	local elapsed = os.clock() - cast.BiteAt
	local fish = cast.Fish
	clearCast(player)
	if success ~= true or elapsed < Config.MinCatchSeconds or elapsed > 60 then
		notify(player, "It got away...", Color3.fromRGB(255, 120, 120))
		return
	end
	local weight = math.floor((0.5 + math.random() ^ 2 * 2.5) * 100) / 100
	table.insert(data.Fish, { Id = fish.Id, W = weight })
	data.Caught += 1
	data.Index[fish.Id] = true
	local rarity = Config.RarityByName[fish.Rarity]
	notify(player, string.format("Caught %s (%.2fkg) — %s!", fish.Name, weight, Format.Cash(Config.FishValue({ Id = fish.Id, W = weight }))), rarity.Color)
	if fish.Rarity == "Mythic" or fish.Rarity == "Secret" then
		notify(nil, player.DisplayName .. " caught a " .. fish.Rarity .. " " .. fish.Name .. "!", rarity.Color)
	end
	sync(player)
end)

---------------------------------------------------------------- selling + rods

local function sellAll(player: Player): (boolean, string)
	local data = DataService.Get(player)
	if not data or #data.Fish == 0 then
		return false, "No fish to sell!"
	end
	local total = 0
	for _, entry in data.Fish do
		total += Config.FishValue(entry)
	end
	if MonetizationService.OwnsPass(player, "DoubleSell") then
		total *= 2
	end
	table.clear(data.Fish)
	data.Cash += total
	data.TotalEarned += total
	sync(player)
	return true, "Sold for " .. Format.Cash(total) .. "!"
end

sellPrompt.Triggered:Connect(function(player)
	local ok, msg = sellAll(player)
	notify(player, msg, if ok then Color3.fromRGB(90, 255, 90) else Color3.fromRGB(255, 90, 90))
end)

SellRemote.OnServerInvoke = function(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not MonetizationService.OwnsPass(player, "SellAnywhere") and not (root and (root.Position - merchantPos).Magnitude < 25) then
		return false, "NeedPass"
	end
	return sellAll(player)
end

BuyRodRemote.OnServerInvoke = function(player, rodId)
	local data = DataService.Get(player)
	local rod = type(rodId) == "string" and Config.RodById[rodId]
	if not data or not rod then
		return false, "Invalid rod"
	end
	if not data.Rods[rodId] then
		if rod.Price < 0 then
			return false, "RobuxOnly"
		end
		if data.Cash < rod.Price then
			return false, "Need " .. Format.Cash(rod.Price) .. "!"
		end
		data.Cash -= rod.Price
		data.Rods[rodId] = true
	end
	data.Rod = rodId
	clearCast(player)
	giveRod(player)
	sync(player)
	return true, "Equipped " .. rod.Name .. "!"
end

---------------------------------------------------------------- players

DataService.ProfileLoaded:Connect(function(player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = stats
	local caught = Instance.new("IntValue")
	caught.Name = "Caught"
	caught.Parent = stats
	stats.Parent = player
	sync(player)
	player.CharacterAdded:Connect(function()
		clearCast(player)
		task.wait()
		giveRod(player)
	end)
	if player.Character then
		giveRod(player)
	end
end)

Players.PlayerRemoving:Connect(clearCast)

task.spawn(function()
	while true do
		task.wait(5)
		for _, player in Players:GetPlayers() do
			sync(player)
		end
	end
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		LuckTotem = function(player)
			workspace:SetAttribute("TotemUntil", math.max(workspace:GetAttribute("TotemUntil") or 0, os.time()) + 600)
			notify(nil, player.DisplayName .. " placed a LUCK TOTEM! 3x luck for everyone!", Color3.fromRGB(0, 255, 200))
			return true
		end,
		BigBait = function(player, data)
			data.Bait += 20
			sync(player)
			notify(player, "+20 Mega Bait!", Color3.fromRGB(255, 200, 80))
			return true
		end,
		CashPack = function(player, data)
			local amount = math.max(5_000, math.floor(data.TotalEarned * 0.25))
			data.Cash += amount
			sync(player)
			notify(player, "+" .. Format.Cash(amount) .. "!", Color3.fromRGB(90, 255, 90))
			return true
		end,
		SigmaRod = function(player, data)
			data.Rods.sigma = true
			data.Rod = "sigma"
			giveRod(player)
			sync(player)
			notify(nil, player.DisplayName .. " got the SIGMA ROD!", Color3.fromRGB(255, 0, 170))
			return true
		end,
	},
	OnPassOwned = function(player, name)
		sync(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("FishABrainrot_v1", {
	Cash = 0,
	Fish = {},
	Rods = { stick = true },
	Rod = "stick",
	Bait = 0,
	Caught = 0,
	Index = {},
	TotalEarned = 0,
})
