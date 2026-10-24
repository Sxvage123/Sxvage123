-- Brainrot Card Clash server: card packs (gacha with mutations), auto-built deck, boss ladder battles,
-- passive gems, selling cards.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotModels = require(ReplicatedStorage.Common.BrainrotModels)
local Format = require(ReplicatedStorage.Common.Format)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)

Lighting.ClockTime = 16
Lighting.Brightness = 2.5

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
local OpenedRemote = remote("RemoteEvent", "Opened") -- (cards: {{Id, Mut}})
local BattleRemote = remote("RemoteEvent", "Battle") -- (bossIndex, log, won)
local CardsRemote = remote("RemoteEvent", "Cards") -- (cards, deckIndices)
local OpenRemote = remote("RemoteFunction", "OpenPack")
local FightRemote = remote("RemoteFunction", "Fight")
local SellRemote = remote("RemoteFunction", "Sell")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

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
local function sign(adornee: BasePart, face: Enum.NormalId, text: string, color: Color3)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.CanvasSize = Vector2.new(400, 120)
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = color
	label.Parent = gui
end

---------------------------------------------------------------- state

local luckUntil = 0

local function deckSize(player: Player): number
	return if MonetizationService.OwnsPass(player, "VIP") then Config.VIPDeckSize else Config.DeckSize
end

local function power(card): number
	local p, _ = Config.Stats(card.Id, card.Mut)
	return p
end

-- The deck is always your strongest cards.
local function deckOf(player: Player, data): { number }
	local order = {}
	for i in data.Cards do
		table.insert(order, i)
	end
	table.sort(order, function(a, b)
		return power(data.Cards[a]) > power(data.Cards[b])
	end)
	local deck = {}
	for i = 1, math.min(deckSize(player), #order) do
		table.insert(deck, order[i])
	end
	return deck
end

local function gemMult(player: Player): number
	local m = 1
	if MonetizationService.OwnsPass(player, "DoubleGems") then
		m *= 2
	end
	if MonetizationService.OwnsPass(player, "VIP") then
		m *= 1.5
	end
	return m
end

local function sync(player: Player, sendCards: boolean?)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Gems", data.Gems)
	player:SetAttribute("Stage", data.Stage)
	player:SetAttribute("CardCount", #data.Cards)
	local deck = deckOf(player, data)
	local total = 0
	for _, i in deck do
		total += power(data.Cards[i])
	end
	player:SetAttribute("DeckPower", total)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		(ls :: any).Stage.Value = data.Stage;
		(ls :: any).Gems.Value = math.min(data.Gems, 2 ^ 53)
	end
	if sendCards then
		CardsRemote:FireClient(player, data.Cards, deck)
	end
end

---------------------------------------------------------------- packs

local function rollRarity(weights: { [string]: number }, lucky: boolean): string
	local entries = {}
	local total = 0
	for name, w in weights do
		local idx = Config.RarityIndex[name]
		-- Luck doubles the weight of anything rarer than the pack's most common rarity.
		local weight = if lucky and idx >= 3 then w * 2 else w
		table.insert(entries, { name, weight, idx })
		total += weight
	end
	table.sort(entries, function(a, b)
		return a[3] < b[3]
	end)
	local roll = math.random() * total
	for _, e in entries do
		roll -= e[2]
		if roll <= 0 then
			return e[1]
		end
	end
	return entries[#entries][1]
end

local function rollCard(weights: { [string]: number }, player: Player): { Id: string, Mut: string? }
	local lucky = MonetizationService.OwnsPass(player, "LuckyPacks") or os.clock() < luckUntil
	local rarity = rollRarity(weights, lucky)
	local pool = Config.ByRarity[rarity]
	local card = pool[math.random(1, #pool)]
	local mut: string? = nil
	for i = #Config.Mutations, 1, -1 do
		local m = Config.Mutations[i]
		if math.random() < m.Chance * (if lucky then 2 else 1) then
			mut = m.Name
			break
		end
	end
	return { Id = card.Id, Mut = mut }
end

local function addCards(player: Player, data, cards)
	for _, c in cards do
		if #data.Cards >= Config.MaxCards then
			-- Inventory full: auto-sell the new card.
			local r = Config.RarityByName[Config.ById[c.Id].Rarity]
			data.Gems += math.floor(r.Sell * Config.MutationMult(c.Mut))
		else
			table.insert(data.Cards, c)
		end
		local info = Config.ById[c.Id]
		if Config.RarityIndex[info.Rarity] >= 5 or c.Mut == "Rainbow" then
			notify(nil, player.DisplayName .. " pulled " .. (if c.Mut then c.Mut .. " " else "") .. info.Name .. " (" .. info.Rarity .. ")!", Config.RarityByName[info.Rarity].Color)
		end
	end
	data.Opened += #cards
end

local function packById(id: string)
	for _, p in Config.Packs do
		if p.Id == id then
			return p
		end
	end
	return nil
end

local function openPack(player: Player, packId: string): boolean
	local data = DataService.Get(player)
	local pack = packById(packId)
	if not data or not pack then
		return false
	end
	local count = if MonetizationService.OwnsPass(player, "FastOpen") then 5 else 1
	count = math.min(count, math.floor(data.Gems / pack.Cost))
	if count < 1 then
		notify(player, "You need " .. Format.Abbreviate(pack.Cost) .. " gems for a " .. pack.Name .. "!", Color3.fromRGB(255, 90, 90))
		return false
	end
	data.Gems -= pack.Cost * count
	local cards = {}
	for _ = 1, count * 3 do
		table.insert(cards, rollCard(pack.Weights, player))
	end
	addCards(player, data, cards)
	OpenedRemote:FireClient(player, cards)
	sync(player, true)
	return true
end
OpenRemote.OnServerInvoke = function(player, packId)
	return openPack(player, tostring(packId))
end

---------------------------------------------------------------- battles

local fighting: { [Player]: boolean } = {}

local function simulate(player: Player, data, boss)
	local deck = deckOf(player, data)
	local cards = {}
	for _, i in deck do
		local c = data.Cards[i]
		local p, hp = Config.Stats(c.Id, c.Mut)
		table.insert(cards, { Id = c.Id, Mut = c.Mut, Power = p, HP = hp, MaxHP = hp })
	end
	local bossHp = boss.HP
	local log = {}
	for _ = 1, 15 do
		local dmg = 0
		for _, c in cards do
			if c.HP > 0 then
				dmg += c.Power
			end
		end
		bossHp = math.max(0, bossHp - dmg)
		local target = 0
		if bossHp > 0 then
			for i, c in cards do
				if c.HP > 0 then
					c.HP = math.max(0, c.HP - boss.Power)
					target = i
					break
				end
			end
		end
		local hps = {}
		for i, c in cards do
			hps[i] = c.HP
		end
		table.insert(log, { BossHP = bossHp, Damage = dmg, Target = target, HPs = hps })
		local alive = false
		for _, c in cards do
			if c.HP > 0 then
				alive = true
			end
		end
		if bossHp <= 0 or not alive then
			break
		end
	end
	return cards, log, bossHp <= 0
end

local function fight(player: Player, stage: number?): boolean
	local data = DataService.Get(player)
	if not data or fighting[player] then
		return false
	end
	local index = stage or (data.Stage + 1)
	index = math.clamp(index, 1, math.min(data.Stage + 1, #Config.Bosses))
	local boss = Config.Bosses[index]
	if #data.Cards == 0 then
		notify(player, "Open a pack first to get some cards!", Color3.fromRGB(255, 200, 0))
		return false
	end
	fighting[player] = true
	local cards, log, won = simulate(player, data, boss)
	BattleRemote:FireClient(player, index, cards, log, won)
	task.delay(math.min(#log * 0.6 + 1, 10), function()
		fighting[player] = nil
	end)
	if won then
		local first = index > data.Stage
		local reward = math.floor(boss.Reward * gemMult(player) * (if first then 3 else 1))
		data.Gems += reward
		if first then
			data.Stage = index
			notify(nil, player.DisplayName .. " defeated " .. boss.Name .. "!", Color3.fromRGB(255, 215, 0))
		end
		notify(player, "Victory! +" .. Format.Abbreviate(reward) .. " gems" .. (if first then " (first clear x3!)" else ""), Color3.fromRGB(90, 255, 90))
	else
		notify(player, boss.Name .. " was too strong! Open better packs.", Color3.fromRGB(255, 90, 90))
	end
	sync(player)
	return won
end
FightRemote.OnServerInvoke = function(player, stage)
	return fight(player, if type(stage) == "number" then stage else nil)
end

SellRemote.OnServerInvoke = function(player, index)
	local data = DataService.Get(player)
	if not data or type(index) ~= "number" or not data.Cards[index] then
		return false
	end
	-- Never sell your deck by accident.
	if table.find(deckOf(player, data), index) then
		notify(player, "That card is in your deck!", Color3.fromRGB(255, 200, 0))
		return false
	end
	local c = table.remove(data.Cards, index)
	local r = Config.RarityByName[Config.ById[c.Id].Rarity]
	data.Gems += math.floor(r.Sell * Config.MutationMult(c.Mut))
	sync(player, true)
	return true
end

---------------------------------------------------------------- world: pack shop + boss arena

part({ Name = "Floor", Size = Vector3.new(200, 2, 200), Position = Vector3.new(0, -1, 0), Color = Color3.fromRGB(60, 50, 80), Material = Enum.Material.SmoothPlastic })
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = Vector3.new(0, 0.5, 0)
spawn.Neutral = true
spawn.Color = Color3.fromRGB(255, 200, 0)
spawn.Material = Enum.Material.Neon
spawn.Parent = world

for i, pack in Config.Packs do
	local x = (i - (#Config.Packs + 1) / 2) * 16
	local stand = part({ Name = "PackStand", Size = Vector3.new(8, 3, 8), Position = Vector3.new(x, 1.5, -30), Color = Color3.fromRGB(40, 35, 55), Material = Enum.Material.Marble })
	local card = part({ Name = pack.Id .. "Pack", Size = Vector3.new(5, 7, 0.6), Position = Vector3.new(x, 7.5, -30), Color = pack.Color, Material = Enum.Material.Neon })
	sign(card, Enum.NormalId.Back, pack.Name .. "\n" .. Format.Abbreviate(pack.Cost) .. " 💎", Color3.new(1, 1, 1))
	sign(card, Enum.NormalId.Front, pack.Name, Color3.new(1, 1, 1))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenPrompt"
	prompt.ActionText = "Open (" .. Format.Abbreviate(pack.Cost) .. " 💎)"
	prompt.ObjectText = pack.Name
	prompt.HoldDuration = 0.3
	prompt.RequiresLineOfSight = false
	prompt.Parent = stand
	prompt.Triggered:Connect(function(player)
		openPack(player, pack.Id)
	end)
end

-- Arena with a giant figure of the next boss.
part({ Name = "Arena", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 60, 60), CFrame = CFrame.new(0, 0.5, 50) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(150, 40, 60), Material = Enum.Material.Slate })
local arenaPad = part({ Name = "FightPad", Size = Vector3.new(14, 1, 14), Position = Vector3.new(0, 1.2, 32), Color = Color3.fromRGB(255, 70, 70), Material = Enum.Material.Neon })
local fightPrompt = Instance.new("ProximityPrompt")
fightPrompt.Name = "FightPrompt"
fightPrompt.ActionText = "Fight next boss"
fightPrompt.HoldDuration = 0.3
fightPrompt.RequiresLineOfSight = false
fightPrompt.Parent = arenaPad
fightPrompt.Triggered:Connect(function(player)
	fight(player, nil)
end)
do
	local boss, _ = BrainrotModels.Build(Config.Bosses[#Config.Bosses].Id, { Scale = 4 })
	local h = (boss:GetAttribute("RootHeight") :: number?) or 10
	boss:PivotTo(CFrame.new(0, h + 1, 62) * CFrame.Angles(0, math.pi, 0))
	boss.Name = "ArenaBoss"
	boss.Parent = world
end

---------------------------------------------------------------- passive gems + players

task.spawn(function()
	while true do
		task.wait(10)
		for _, player in Players:GetPlayers() do
			local data = DataService.Get(player)
			if data then
				data.Gems += math.floor(Config.PassiveGems * (1 + data.Stage) * gemMult(player))
				sync(player)
			end
		end
		workspace:SetAttribute("LuckLeft", math.max(0, math.ceil(luckUntil - os.clock())))
	end
end)

DataService.ProfileLoaded:Connect(function(player, data)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, name in { "Stage", "Gems" } do
		local v = Instance.new(if name == "Gems" then "NumberValue" else "IntValue")
		v.Name = name
		v.Parent = ls
	end
	ls.Parent = player
	if data.Opened == 0 and #data.Cards == 0 then
		-- Free starter pack so new players can fight right away.
		local starter = {}
		for _ = 1, 3 do
			table.insert(starter, rollCard(Config.Packs[1].Weights, player))
		end
		addCards(player, data, starter)
		task.delay(2, function()
			OpenedRemote:FireClient(player, starter)
			notify(player, "Here's a free starter pack! Walk to the red pad to fight your first boss.", Color3.fromRGB(255, 215, 0))
		end)
	end
	sync(player, true)
end)

Players.PlayerRemoving:Connect(function(player)
	fighting[player] = nil
end)

local function gemPack(player: Player, data, base: number)
	local amount = math.floor(base * (1 + data.Stage * 0.5) ^ 1.5)
	data.Gems += amount
	sync(player)
	notify(player, "+" .. Format.Abbreviate(amount) .. " gems!", Color3.fromRGB(120, 220, 255))
	return true
end

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		Gems = function(player, data)
			return gemPack(player, data, 500)
		end,
		GemsBig = function(player, data)
			return gemPack(player, data, 4000)
		end,
		MegaPack = function(player, data)
			local cards = { rollCard({ Mythic = 80, ["Brainrot God"] = 18, Secret = 2 }, player) }
			addCards(player, data, cards)
			OpenedRemote:FireClient(player, cards)
			sync(player, true)
			return true
		end,
		ServerLuck = function(player)
			luckUntil = math.max(luckUntil, os.clock()) + Config.ServerLuckTime
			notify(nil, player.DisplayName .. " activated 2x SERVER LUCK for packs!", Color3.fromRGB(255, 215, 0))
			return true
		end,
	},
	OnPassOwned = function(player, name)
		sync(player, true)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("BrainrotCardClash_v1", {
	Gems = 60,
	Stage = 0,
	Opened = 0,
	Cards = {},
})
