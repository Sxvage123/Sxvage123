-- Eat the Brainrot World server: chunky city, eat chunks to grow, upgrades, rebirths, eat smaller players.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotModels = require(ReplicatedStorage.Common.BrainrotModels)
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
local EatRemote = remote("RemoteEvent", "Eat")
local UpgradeRemote = remote("RemoteFunction", "Upgrade")
local RebirthRemote = remote("RemoteFunction", "Rebirth")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

---------------------------------------------------------------- city

local world = Instance.new("Folder")
world.Name = "World"
world.Parent = workspace
local city = Instance.new("Folder")
city.Name = "City"
city.Parent = workspace
local function part(props, parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

part({ Name = "Ground", Size = Vector3.new(760, 2, 760), Position = Vector3.new(0, -1, 0), Color = Color3.fromRGB(90, 150, 80), Material = Enum.Material.Grass }, world)
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(14, 1, 14)
spawn.Position = Vector3.new(0, 0.5, 0)
spawn.Neutral = true
spawn.Color = Color3.fromRGB(255, 200, 0)
spawn.Parent = world

local edible: { BasePart } = {}
local function addEdible(p: BasePart, minSize: number, food: number)
	p:SetAttribute("MinSize", minSize)
	p:SetAttribute("Food", food)
	table.insert(edible, p)
end

local COLORS = { Color3.fromRGB(240, 200, 160), Color3.fromRGB(170, 200, 240), Color3.fromRGB(240, 170, 190), Color3.fromRGB(200, 240, 170), Color3.fromRGB(230, 230, 230), Color3.fromRGB(250, 220, 120) }
local rng = Random.new(42)
local inner = 30
for _, d in Config.Districts do
	for i = 1, d.Count do
		local a = (i + rng:NextNumber(-0.3, 0.3)) / d.Count * math.pi * 2
		local r = rng:NextNumber(inner + 15, d.Radius - 15)
		local base = Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local b = d.Block
		local floors = rng:NextInteger(d.Floors[1], d.Floors[2])
		local color = COLORS[rng:NextInteger(1, #COLORS)]
		for fx = 0, 2 do
			for fz = 0, 2 do
				for fy = 0, floors - 1 do
					local window = (fx ~= 1 or fz ~= 1) and fy % 2 == 1
					local p = part({ Name = "Chunk", Size = Vector3.one * b, Position = base + Vector3.new((fx - 1) * b, b / 2 + fy * b, (fz - 1) * b), Color = if window then Color3.fromRGB(120, 180, 230) else color, Material = if window then Enum.Material.Glass else Enum.Material.SmoothPlastic }, city)
					addEdible(p, d.MinSize, d.Food * (if window then 2 else 1))
				end
			end
		end
	end
	-- Trees between buildings
	for _ = 1, d.Count do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(inner, d.Radius)
		local pos = Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		addEdible(part({ Name = "Trunk", Size = Vector3.new(1.5, 6, 1.5) * (d.Block / 5), Position = pos + Vector3.new(0, 3 * d.Block / 5, 0), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.Wood }, city), d.MinSize, d.Food)
		addEdible(part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.one * 6 * (d.Block / 5), Position = pos + Vector3.new(0, 7 * d.Block / 5, 0), Color = Color3.fromRGB(60, 150, 60), Material = Enum.Material.Grass }, city), d.MinSize, d.Food * 2)
	end
	inner = d.Radius
end

-- Brainrot titans standing at the edge: the biggest meals in the game.
for i, id in { "tung", "tralalero", "bombardiro", "cappuccino", "garama", "skibidi" } do
	local model, _ = BrainrotModels.Build(id, { Scale = 8 })
	local a = i / 6 * math.pi * 2
	local h = (model:GetAttribute("RootHeight") :: number?) or 20
	model:PivotTo(CFrame.new(math.cos(a) * 340, h, math.sin(a) * 340) * CFrame.Angles(0, -a - math.pi / 2, 0))
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "Root" then
			p.CanQuery = true
			addEdible(p, Config.TitanMinSize, Config.TitanFood)
		end
	end
	model.Parent = city
end

---------------------------------------------------------------- players

local lastBite: { [Player]: number } = {}

local function level(data, id: string): number
	return data.Levels[id] or 0
end

local function sizeMult(player: Player, data): number
	local m = (1 + data.Rebirths * Config.RebirthBonus) * (1 + level(data, "Stomach") * 0.2)
	if MonetizationService.OwnsPass(player, "DoubleSize") then
		m *= 2
	end
	if MonetizationService.OwnsPass(player, "VIP") then
		m *= 1.5
	end
	return m
end

local function applyScale(player: Player)
	local data = DataService.Get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not data or not character or not humanoid then
		return
	end
	local scale = Config.ScaleFor(data.Size)
	if math.abs(character:GetScale() - scale) > 0.02 then
		character:ScaleTo(scale)
	end
	humanoid.WalkSpeed = (16 + level(data, "Speed") * 2) * math.sqrt(scale)
end

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Size", data.Size)
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("Rebirths", data.Rebirths)
	for _, u in Config.Upgrades do
		player:SetAttribute("Lv_" .. u.Id, level(data, u.Id))
	end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		(ls :: any).Size.Value = math.floor(data.Size);
		(ls :: any).Rebirths.Value = data.Rebirths
	end
	applyScale(player)
end

local function grow(player: Player, data, food: number)
	local gain = food * sizeMult(player, data)
	data.Size += gain
	data.Coins += math.floor(food * (1 + data.Rebirths * Config.RebirthBonus) * (if MonetizationService.OwnsPass(player, "VIP") then 1.5 else 1))
end

local function bite(player: Player)
	local data = DataService.Get(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local now = os.clock()
	if not data or not root or now - (lastBite[player] or 0) < Config.BiteCooldown then
		return
	end
	lastBite[player] = now
	local scale = Config.ScaleFor(data.Size)
	local reach = (7 + scale * 4) * (1 + level(data, "Reach") * 0.15)
	local count = 1 + level(data, "Bite")
	if MonetizationService.OwnsPass(player, "MegaBite") then
		count *= 3
	end
	-- Nearest edible chunks within reach that we're big enough for.
	local found = {}
	for i, p in edible do
		if p.Parent and (p:GetAttribute("MinSize") :: number) <= data.Size then
			local d = (p.Position - root.Position).Magnitude - p.Size.Magnitude / 2
			if d <= reach then
				table.insert(found, { i, d })
			end
		end
	end
	table.sort(found, function(a, b)
		return a[2] < b[2]
	end)
	local food = 0
	for k = 1, math.min(count, #found) do
		local p = edible[found[k][1]]
		food += p:GetAttribute("Food") :: number
		local parent = p.Parent
		p.Parent = nil
		task.delay(Config.RespawnTime, function()
			p.Parent = parent
		end)
	end
	-- Eat smaller players in reach.
	for _, other in Players:GetPlayers() do
		local od = DataService.Get(other)
		local oroot = other.Character and other.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local ohum = other.Character and other.Character:FindFirstChildOfClass("Humanoid")
		if other ~= player and od and oroot and ohum and ohum.Health > 0 and data.Size >= (od.Size + 10) * Config.EatPlayerRatio and (oroot.Position - root.Position).Magnitude <= reach then
			local stolen = math.floor(od.Size * 0.3)
			od.Size -= stolen
			food += stolen
			ohum.Health = 0
			sync(other)
			notify(nil, player.DisplayName .. " ATE " .. other.DisplayName .. "!", Color3.fromRGB(255, 80, 80))
		end
	end
	if food > 0 then
		grow(player, data, food)
		sync(player)
	end
end
EatRemote.OnServerEvent:Connect(bite)

task.spawn(function()
	while true do
		task.wait(0.5)
		for _, p in Players:GetPlayers() do
			if MonetizationService.OwnsPass(p, "AutoEat") and p:GetAttribute("AutoEat") ~= false then
				bite(p)
			end
		end
	end
end)

UpgradeRemote.OnServerInvoke = function(player, id)
	local data = DataService.Get(player)
	if not data then
		return false
	end
	for _, u in Config.Upgrades do
		if u.Id == id then
			local lv = level(data, id)
			local cost = Config.UpgradeCost(u, lv)
			if lv >= u.Max or data.Coins < cost then
				return false
			end
			data.Coins -= cost
			data.Levels[id] = lv + 1
			sync(player)
			return true
		end
	end
	return false
end

RebirthRemote.OnServerInvoke = function(player)
	local data = DataService.Get(player)
	if not data then
		return false
	end
	local need = Config.RebirthCost(data.Rebirths)
	if data.Size < need then
		notify(player, "Reach size " .. Format.Abbreviate(need) .. " to rebirth!", Color3.fromRGB(255, 90, 90))
		return false
	end
	data.Size = 0
	data.Rebirths += 1
	sync(player)
	notify(nil, player.DisplayName .. " REBIRTHED! (x" .. (1 + data.Rebirths * Config.RebirthBonus) .. " growth)", Color3.fromRGB(255, 120, 255))
	return true
end

DataService.ProfileLoaded:Connect(function(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, name in { "Size", "Rebirths" } do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = ls
	end
	ls.Parent = player
	sync(player)
	local function onCharacter(character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait()
		applyScale(player)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastBite[player] = nil
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		Size1 = function(player, data)
			data.Size += math.max(200, data.Size * 0.25)
			sync(player)
			return true
		end,
		Size2 = function(player, data)
			data.Size += math.max(2000, data.Size * 1.5)
			sync(player)
			notify(nil, player.DisplayName .. " bought a GIANT FEAST!", Color3.fromRGB(255, 215, 0))
			return true
		end,
		ShrinkRay = function(player, data)
			local target, best = nil, -1
			for _, other in Players:GetPlayers() do
				local od = DataService.Get(other)
				if other ~= player and od and od.Size > best then
					target, best = other, od.Size
				end
			end
			local od = target and DataService.Get(target)
			if target and od then
				od.Size = math.floor(od.Size / 2)
				sync(target)
				notify(nil, player.DisplayName .. " used a SHRINK RAY on " .. target.DisplayName .. "!", Color3.fromRGB(120, 200, 255))
			else
				data.Size += 300
				sync(player)
				notify(player, "Nobody to shrink, so you grew +300!", Color3.fromRGB(255, 215, 0))
			end
			return true
		end,
		Coins = function(player, data)
			data.Coins += 2000 * (1 + data.Rebirths)
			sync(player)
			return true
		end,
	},
	OnPassOwned = function(player, name)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("EatTheBrainrotWorld_v1", {
	Size = 0,
	Coins = 0,
	Rebirths = 0,
	Levels = {},
})
