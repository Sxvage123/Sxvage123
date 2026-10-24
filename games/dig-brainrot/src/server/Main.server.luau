-- Dig to the Brainrot Core server: a shared pit that reveals blocks as they're mined, ores, fossils, shops.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)

Lighting.ClockTime = 14
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
local MineRemote = remote("RemoteEvent", "Mine")
local DynamiteRemote = remote("RemoteEvent", "Dynamite")
local SellRemote = remote("RemoteFunction", "Sell")
local BuyRemote = remote("RemoteFunction", "BuyTool")
local SurfaceRemote = remote("RemoteEvent", "Surface")
local FossilRemote = remote("RemoteEvent", "Fossils")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

---------------------------------------------------------------- surface

local B = Config.BlockSize
local W = Config.PitWidth
local D = Config.PitDepth
local HALF = W * B / 2
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
-- Grass around the pit (four slabs leave the hole open)
for _, s in { { 0, -HALF - 60, 200, 120 }, { 0, HALF + 60, 200, 120 }, { -HALF - 38, 0, 76, W * B }, { HALF + 38, 0, 76, W * B } } do
	part({ Size = Vector3.new(s[3], 4, s[4]), Position = Vector3.new(s[1], -2, s[2]), Color = Color3.fromRGB(100, 190, 90), Material = Enum.Material.Grass })
end
-- Bedrock walls + floor so nobody falls out of the pit
local depthStuds = D * B
for _, s in { { 0, -HALF - 2, W * B + 8, 4 }, { 0, HALF + 2, W * B + 8, 4 }, { -HALF - 2, 0, 4, W * B }, { HALF + 2, 0, 4, W * B } } do
	part({ Size = Vector3.new(s[3], depthStuds, s[4]), Position = Vector3.new(s[1], -4 - depthStuds / 2, s[2]), Color = Color3.fromRGB(35, 30, 35), Material = Enum.Material.Basalt })
end
part({ Size = Vector3.new(W * B + 8, 4, W * B + 8), Position = Vector3.new(0, -4 - depthStuds - 2, 0), Color = Color3.fromRGB(35, 30, 35), Material = Enum.Material.Basalt })
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = Vector3.new(0, 0.5, -HALF - 20)
spawn.Neutral = true
spawn.Color = Color3.fromRGB(255, 200, 40)
spawn.Material = Enum.Material.Neon
spawn.Parent = world

local function billboard(adornee: BasePart, text: string)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 50)
	gui.StudsOffset = Vector3.new(0, 4, 0)
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
local sellPad = part({ Name = "SellPad", Size = Vector3.new(10, 1, 10), Position = Vector3.new(22, 0.5, -HALF - 20), Color = Color3.fromRGB(40, 220, 80), Material = Enum.Material.Neon })
billboard(sellPad, "SELL ORES")
local shopCounter = part({ Name = "ToolShop", Size = Vector3.new(12, 4, 5), Position = Vector3.new(-22, 2, -HALF - 22), Color = Color3.fromRGB(120, 80, 45), Material = Enum.Material.WoodPlanks })
billboard(shopCounter, "TOOL SHOP")
local shopPrompt = Instance.new("ProximityPrompt")
shopPrompt.Name = "ToolShopPrompt"
shopPrompt.ActionText = "Upgrade Tools"
shopPrompt.ObjectText = "Tool Shop"
shopPrompt.RequiresLineOfSight = false
shopPrompt.MaxActivationDistance = 14
shopPrompt.Parent = shopCounter

---------------------------------------------------------------- pit

local pitFolder = Instance.new("Folder")
pitFolder.Name = "Pit"
pitFolder.Parent = workspace
local blocks: { [number]: BasePart } = {}
local mined: { [number]: boolean } = {}

local function key(i: number, j: number, k: number): number
	return i + j * 100 + k * 100000
end

local function rollOre(depth: number, luck: number)
	local total = 0
	local pool = {}
	for _, ore in Config.Ores do
		if depth >= ore.MinDepth and depth <= (ore.MaxDepth or math.huge) then
			local w = ore.Weight * (if Config.LuckyOres[ore.Id] then luck else 1)
			total += w
			table.insert(pool, { ore, w })
		end
	end
	local r = math.random() * total
	for _, entry in pool do
		r -= entry[2]
		if r <= 0 then
			return entry[1]
		end
	end
	return pool[1][1]
end

local function reveal(i: number, j: number, k: number)
	if i < 0 or i >= W or k < 0 or k >= W or j < 0 or j >= D then
		return
	end
	local id = key(i, j, k)
	if mined[id] or blocks[id] then
		return
	end
	local ore = rollOre(j, 1)
	local p = Instance.new("Part")
	p.Name = ore.Id
	p.Anchored = true
	p.Size = Vector3.new(B, B, B)
	p.Position = Vector3.new((i - (W - 1) / 2) * B, -B / 2 - j * B, (k - (W - 1) / 2) * B)
	p.Color = ore.Color
	p.Material = (Enum.Material :: any)[ore.Material]
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p:SetAttribute("Key", id)
	p:SetAttribute("Depth", j)
	p:SetAttribute("HP", ore.Health)
	p:SetAttribute("Ore", ore.Id)
	p.Parent = pitFolder
	blocks[id] = p
end

local function resetPit()
	pitFolder:ClearAllChildren()
	table.clear(blocks)
	table.clear(mined)
	for i = 0, W - 1 do
		for k = 0, W - 1 do
			reveal(i, 0, k)
		end
	end
	workspace:SetAttribute("PitResetAt", os.time() + Config.ResetEvery)
end
resetPit()

---------------------------------------------------------------- players

local lastHit: { [Player]: number } = {}

local function capacity(player: Player, data): number
	local cap = (Config.BackpackById[data.Backpack] or Config.Backpacks[1]).Capacity
	if MonetizationService.OwnsPass(player, "BigBackpack") then
		cap *= 3
	end
	return cap
end

local function fossilCount(data): number
	local n = 0
	for _ in data.Fossils do
		n += 1
	end
	return n
end

local function coinMult(player: Player, data): number
	local m = 1 + fossilCount(data) * Config.FossilBonus + data.Rebirths
	if MonetizationService.OwnsPass(player, "DoubleCoins") then
		m *= 2
	end
	return m
end

local function bagValue(player: Player, data): number
	local total = 0
	for oreId, count in data.Bag do
		local ore = Config.OreById[oreId]
		total += (if ore then ore.Value else 0) * count
	end
	return math.floor(total * coinMult(player, data))
end

local function bagCount(data): number
	local n = 0
	for _, c in data.Bag do
		n += c
	end
	return n
end

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("BagCount", bagCount(data))
	player:SetAttribute("BagCap", capacity(player, data))
	player:SetAttribute("BagValue", bagValue(player, data))
	player:SetAttribute("Pickaxe", data.Pickaxe)
	player:SetAttribute("Backpack", data.Backpack)
	player:SetAttribute("Dynamite", data.Dynamite)
	player:SetAttribute("DrillUntil", data.DrillUntil)
	player:SetAttribute("FossilCount", fossilCount(data))
	local owned = {}
	for id in data.Owned do
		table.insert(owned, id)
	end
	player:SetAttribute("OwnedTools", table.concat(owned, ","))
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Coins.Value = Format.Abbreviate(data.Coins)
		stats["Max Depth"].Value = data.MaxDepth
	end
end

local function givePickaxe(player: Player)
	local data = DataService.Get(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not data or not backpack then
		return
	end
	for _, container in { backpack, player.Character } do
		local old = container and container:FindFirstChild("Pickaxe")
		if old then
			old:Destroy()
		end
	end
	local pick = Config.PickaxeById[data.Pickaxe] or Config.Pickaxes[1]
	local tool = Instance.new("Tool")
	tool.Name = "Pickaxe"
	tool.ToolTip = pick.Name
	tool.CanBeDropped = false
	tool.GripPos = Vector3.new(0, -1.2, 0)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.3, 3.2, 0.3)
	handle.Color = Color3.fromRGB(120, 85, 50)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Parent = tool
	local head = Instance.new("Part")
	head.Size = Vector3.new(2.4, 0.4, 0.4)
	head.Color = pick.Color
	head.Material = if pick.Index >= 5 then Enum.Material.Neon else Enum.Material.Metal
	head.CanCollide = false
	head.Massless = true
	head.CFrame = handle.CFrame * CFrame.new(0, 1.5, 0)
	local w = Instance.new("WeldConstraint")
	w.Part0 = handle
	w.Part1 = head
	w.Parent = head
	head.Parent = tool
	tool.Parent = backpack
end

local function rollFossil(player: Player, depth: number)
	local pool = {}
	for _, f in Config.Fossils do
		if depth >= f.MinDepth then
			table.insert(pool, f)
		end
	end
	-- Favour the deepest unlocked fossils a little (and more with the Lucky pass).
	local bias = if MonetizationService.OwnsPass(player, "Lucky") then 2 else 1.3
	local idx = math.clamp(math.ceil((math.random() ^ (1 / bias)) * #pool), 1, #pool)
	return pool[idx]
end

local function breakBlock(player: Player, p: BasePart, data, free: boolean?)
	local id = p:GetAttribute("Key") :: number
	local depth = p:GetAttribute("Depth") :: number
	local oreId = p:GetAttribute("Ore") :: string
	local i = id % 100
	local j = math.floor(id / 100) % 1000
	local k = math.floor(id / 100000)
	blocks[id] = nil
	mined[id] = true
	p:Destroy()
	for _, d in { { 1, 0, 0 }, { -1, 0, 0 }, { 0, 1, 0 }, { 0, -1, 0 }, { 0, 0, 1 }, { 0, 0, -1 } } do
		reveal(i + d[1], j + d[2], k + d[3])
	end
	data.Mined += 1
	data.MaxDepth = math.max(data.MaxDepth, depth + 1)
	if oreId == "fossil" then
		local fossil = rollFossil(player, depth)
		local isNew = not data.Fossils[fossil.Id]
		data.Fossils[fossil.Id] = (data.Fossils[fossil.Id] or 0) + 1
		notify(player, (if isNew then "NEW FOSSIL: " else "Fossil: ") .. fossil.Name .. (if isNew then "  (+10% coins forever!)" else ""), Color3.fromRGB(255, 230, 150))
		if isNew and fossil.MinDepth >= 65 then
			notify(nil, player.DisplayName .. " dug up " .. fossil.Name .. "!", Color3.fromRGB(255, 215, 0))
		end
		FossilRemote:FireClient(player, data.Fossils)
	elseif bagCount(data) < capacity(player, data) then
		data.Bag[oreId] = (data.Bag[oreId] or 0) + 1
		local ore = Config.OreById[oreId]
		if ore.Value >= 800 then
			notify(nil, player.DisplayName .. " found " .. ore.Name .. "!", ore.Color)
		end
	elseif not free then
		notify(player, "Backpack full! Sell your ores or get a bigger bag.", Color3.fromRGB(255, 90, 90))
	end
end

MineRemote.OnServerEvent:Connect(function(player, target)
	local data = DataService.Get(player)
	if not data or typeof(target) ~= "Instance" or not target:IsA("BasePart") or target.Parent ~= pitFolder then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or (root.Position - target.Position).Magnitude > Config.ReachDistance then
		return
	end
	local pick = Config.PickaxeById[data.Pickaxe] or Config.Pickaxes[1]
	local now = os.clock()
	if now - (lastHit[player] or 0) < 1 / pick.Speed - 0.02 then
		return
	end
	lastHit[player] = now
	local power = pick.Power * (if data.DrillUntil > os.time() then 5 else 1)
	local hp = (target:GetAttribute("HP") :: number) - power
	if hp <= 0 then
		breakBlock(player, target, data)
	else
		target:SetAttribute("HP", hp)
	end
	sync(player)
end)

DynamiteRemote.OnServerEvent:Connect(function(player, target)
	local data = DataService.Get(player)
	if not data or data.Dynamite <= 0 or typeof(target) ~= "Instance" or not target:IsA("BasePart") or target.Parent ~= pitFolder then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or (root.Position - target.Position).Magnitude > Config.ReachDistance * 2 then
		return
	end
	data.Dynamite -= 1
	local center = target.Position
	local boom = Instance.new("Explosion")
	boom.Position = center
	boom.BlastPressure = 0
	boom.DestroyJointRadiusPercent = 0
	boom.Parent = workspace
	for _, p in pitFolder:GetChildren() do
		if p:IsA("BasePart") and (p.Position - center).Magnitude <= B * 1.8 then
			breakBlock(player, p, data, true)
		end
	end
	sync(player)
end)

local function sellAll(player: Player): (boolean, string)
	local data = DataService.Get(player)
	if not data or bagCount(data) == 0 then
		return false, "Nothing to sell! Go mine some ores."
	end
	local value = bagValue(player, data)
	table.clear(data.Bag)
	data.Coins += value
	data.TotalEarned += value
	sync(player)
	return true, "Sold for " .. Format.Abbreviate(value) .. " coins!"
end

local sellBusy: { [Player]: boolean } = {}
sellPad.Touched:Connect(function(hit)
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if player and not sellBusy[player] then
		sellBusy[player] = true
		local ok, msg = sellAll(player)
		if ok then
			notify(player, msg, Color3.fromRGB(90, 255, 90))
		end
		task.wait(1)
		sellBusy[player] = nil
	end
end)

SellRemote.OnServerInvoke = function(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not MonetizationService.OwnsPass(player, "SellAnywhere") and not (root and (root.Position - sellPad.Position).Magnitude < 25) then
		return false, "NeedPass"
	end
	return sellAll(player)
end

BuyRemote.OnServerInvoke = function(player, kind, id)
	local data = DataService.Get(player)
	local item = if kind == "Pickaxe" then Config.PickaxeById[id] elseif kind == "Backpack" then Config.BackpackById[id] else nil
	if not data or not item then
		return false, "Invalid"
	end
	if not data.Owned[id .. kind] then
		if data.Coins < item.Cost then
			return false, "Need " .. Format.Abbreviate(item.Cost) .. " coins!"
		end
		data.Coins -= item.Cost
		data.Owned[id .. kind] = true
	end
	if kind == "Pickaxe" then
		data.Pickaxe = id
		givePickaxe(player)
	else
		data.Backpack = id
	end
	sync(player)
	return true, "Equipped " .. item.Name .. "!"
end

SurfaceRemote.OnServerEvent:Connect(function(player)
	if player.Character then
		player.Character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
	end
end)

-- Pit reset + depth tracking
task.spawn(function()
	while true do
		task.wait(1)
		if os.time() >= (workspace:GetAttribute("PitResetAt") or 0) then
			notify(nil, "The pit is refilling! Back to the surface!", Color3.fromRGB(255, 200, 80))
			for _, player in Players:GetPlayers() do
				if player.Character then
					player.Character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
				end
			end
			resetPit()
		end
		for _, player in Players:GetPlayers() do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				player:SetAttribute("Depth", math.max(0, math.floor(-root.Position.Y / B)))
			end
		end
	end
end)

DataService.ProfileLoaded:Connect(function(player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local coins = Instance.new("StringValue")
	coins.Name = "Coins"
	coins.Parent = stats
	local depth = Instance.new("IntValue")
	depth.Name = "Max Depth"
	depth.Parent = stats
	stats.Parent = player
	sync(player)
	FossilRemote:FireClient(player, data.Fossils)
	player.CharacterAdded:Connect(function()
		task.wait()
		givePickaxe(player)
	end)
	if player.Character then
		givePickaxe(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastHit[player] = nil
	sellBusy[player] = nil
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		Dynamite = function(player, data)
			data.Dynamite += 5
			sync(player)
			notify(player, "+5 Dynamite! Use the DYNAMITE button, then click a block.", Color3.fromRGB(255, 120, 60))
			return true
		end,
		CoinPack = function(player, data)
			local amount = math.max(2000, math.floor(data.TotalEarned * 0.2))
			data.Coins += amount
			sync(player)
			notify(player, "+" .. Format.Abbreviate(amount) .. " coins!", Color3.fromRGB(255, 215, 0))
			return true
		end,
		MegaDrill = function(player, data)
			data.DrillUntil = math.max(data.DrillUntil, os.time()) + 600
			sync(player)
			notify(player, "MEGA DRILL! 5x mining power for 10 minutes!", Color3.fromRGB(0, 255, 200))
			return true
		end,
	},
	OnPassOwned = function(player, name)
		sync(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("DigBrainrot_v1", {
	Coins = 0,
	Bag = {},
	Pickaxe = "wood",
	Backpack = "pouch",
	Owned = { woodPickaxe = true, pouchBackpack = true },
	Fossils = {},
	Dynamite = 3,
	DrillUntil = 0,
	MaxDepth = 0,
	Mined = 0,
	Rebirths = 0,
	TotalEarned = 0,
})
