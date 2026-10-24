-- 99 Nights with Sahur server: day/night loop, campfire fuel, trees, berries, hunger, the Sahur monster,
-- deaths until morning, diamonds per night survived and diamond classes.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotModels = require(ReplicatedStorage.Common.BrainrotModels)
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
local ClassRemote = remote("RemoteFunction", "Class")

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
local function prompt(parent: Instance, name: string, action: string, hold: number): ProximityPrompt
	local pp = Instance.new("ProximityPrompt")
	pp.Name = name
	pp.ActionText = action
	pp.HoldDuration = hold
	pp.RequiresLineOfSight = false
	pp.MaxActivationDistance = 10
	pp.Parent = parent
	return pp
end

---------------------------------------------------------------- map

local rng = Random.new(99)
part({ Name = "Ground", Size = Vector3.new(520, 2, 520), Position = Vector3.new(0, -1, 0), Color = Color3.fromRGB(70, 120, 55), Material = Enum.Material.Grass })
part({ Name = "Clearing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 60, 60), CFrame = CFrame.new(0, 0.05, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(120, 100, 70), Material = Enum.Material.Ground })
for _, d in { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) } do
	part({ Name = "Border", Size = Vector3.new(if d.X ~= 0 then 4 else 520, 60, if d.Z ~= 0 then 4 else 520), Position = d * 262 + Vector3.new(0, 30, 0), Transparency = 1 })
end

-- Campfire: stone ring, logs, flame.
local fire = Instance.new("Model")
fire.Name = "Campfire"
for i = 0, 9 do
	local a = i / 10 * math.pi * 2
	part({ Name = "Stone", Size = Vector3.new(1.6, 1.2, 1.6), Position = Vector3.new(math.cos(a) * 4, 0.6, math.sin(a) * 4), Color = Color3.fromRGB(110, 110, 115), Material = Enum.Material.Slate }, fire)
end
for i = 0, 2 do
	part({ Name = "Log", Shape = Enum.PartType.Cylinder, Size = Vector3.new(5, 1, 1), CFrame = CFrame.new(0, 0.7, 0) * CFrame.Angles(0, i * math.pi / 3, 0), Color = Color3.fromRGB(90, 60, 35), Material = Enum.Material.Wood }, fire)
end
local flame = part({ Name = "Flame", Shape = Enum.PartType.Ball, Size = Vector3.new(4, 4, 4), Position = Vector3.new(0, 2.5, 0), Color = Color3.fromRGB(255, 140, 30), Material = Enum.Material.Neon, Transparency = 0.15, CanCollide = false }, fire)
local fireLight = Instance.new("PointLight")
fireLight.Color = Color3.fromRGB(255, 160, 60)
fireLight.Brightness = 3
fireLight.Range = 40
fireLight.Parent = flame
local fuelPrompt = prompt(flame, "FuelPrompt", "Add Wood", 0.2)
fuelPrompt.MaxActivationDistance = 14
fire.PrimaryPart = flame
fire.Parent = world
local safeRing = part({ Name = "SafeRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 40, 40), CFrame = CFrame.new(0, 0.12, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 170, 60), Material = Enum.Material.Neon, Transparency = 0.8, CanCollide = false, CanTouch = false, CanQuery = false })

local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(8, 1, 8)
spawn.Position = Vector3.new(0, 0.5, 12)
spawn.Neutral = true
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Parent = world

-- Tents around the fire for atmosphere.
for i = 0, 3 do
	local a = i / 4 * math.pi * 2 + 0.4
	local tent = Instance.new("WedgePart")
	tent.Anchored = true
	tent.Size = Vector3.new(8, 6, 5)
	tent.CFrame = CFrame.new(math.cos(a) * 20, 3, math.sin(a) * 20) * CFrame.Angles(0, -a, 0)
	tent.Color = Color3.fromRGB(60 + i * 40, 90, 160 - i * 30)
	tent.Parent = world
end

-- Ghost platform where dead players wait for morning.
local GHOST = CFrame.new(0, 205, 0)
part({ Name = "GhostPlatform", Size = Vector3.new(40, 2, 40), Position = Vector3.new(0, 200, 0), Color = Color3.fromRGB(200, 220, 255), Material = Enum.Material.ForceField, Transparency = 0.5 })

-- Trees
local function buildTree(pos: Vector3): Model
	local tree = Instance.new("Model")
	tree.Name = "Tree"
	local h = rng:NextNumber(14, 22)
	local trunk = part({ Name = "Trunk", Size = Vector3.new(2.4, h, 2.4), Position = pos + Vector3.new(0, h / 2, 0), Color = Color3.fromRGB(95, 65, 40), Material = Enum.Material.Wood }, tree)
	for i = 0, 2 do
		local size = 11 - i * 3
		local leaves = Instance.new("WedgePart")
		leaves.Anchored = true
		leaves.Size = Vector3.new(size, 6, size)
		leaves.CFrame = CFrame.new(pos + Vector3.new(0, h - 2 + i * 4, 0))
		leaves.Color = Color3.fromRGB(35, 95 + i * 15, 45)
		leaves.Material = Enum.Material.Grass
		leaves.CanCollide = false
		leaves.Parent = tree
		local back = leaves:Clone()
		back.CFrame = leaves.CFrame * CFrame.Angles(0, math.pi, 0)
		back.Parent = tree
	end
	tree.PrimaryPart = trunk
	tree.Parent = world
	return tree
end

local wood: { [Player]: number } = {}
local hunger: { [Player]: number } = {}
local dead: { [Player]: boolean } = {}

local function hasClass(player: Player, id: string): boolean
	local data = DataService.Get(player)
	return data ~= nil and data.Class == id
end

local function woodCap(player: Player): number
	return if MonetizationService.OwnsPass(player, "BigBag") then Config.BigBagWood else Config.CarryWood
end

local function syncWood(player: Player)
	player:SetAttribute("Wood", wood[player] or 0)
end

for _ = 1, 70 do
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(45, 240)
	local pos = Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
	local tree = buildTree(pos)
	local trunk = tree.PrimaryPart :: BasePart
	local chop = prompt(trunk, "ChopPrompt", "Chop", Config.ChopTime)
	chop.ObjectText = "Tree"
	chop.Triggered:Connect(function(player)
		if dead[player] or not tree.Parent then
			return
		end
		local cap = woodCap(player)
		local have = wood[player] or 0
		if have >= cap then
			notify(player, "Your bag is full! Bring the wood to the campfire.", Color3.fromRGB(255, 200, 0))
			return
		end
		local gain = 1
		if MonetizationService.OwnsPass(player, "GoldenAxe") then
			gain += 1
		end
		if hasClass(player, "Lumberjack") then
			gain += 1
		end
		wood[player] = math.min(cap, have + gain)
		syncWood(player)
		tree.Parent = nil
		task.delay(Config.TreeRespawn, function()
			tree.Parent = world
		end)
	end)
end

-- Berry bushes
for _ = 1, 22 do
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(35, 200)
	local bush = part({ Name = "BerryBush", Shape = Enum.PartType.Ball, Size = Vector3.new(5, 5, 5), Position = Vector3.new(math.cos(a) * r, 1.8, math.sin(a) * r), Color = Color3.fromRGB(40, 110, 50), Material = Enum.Material.Grass })
	local berries = {}
	for _ = 1, 5 do
		local o = Vector3.new(rng:NextNumber(-1.8, 1.8), rng:NextNumber(-0.5, 1.8), rng:NextNumber(-1.8, 1.8)).Unit * 2.4
		table.insert(berries, part({ Name = "Berry", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), Position = bush.Position + o, Color = Color3.fromRGB(220, 30, 60), CanCollide = false }))
	end
	local eat = prompt(bush, "EatPrompt", "Eat Berries", 0.5)
	eat.ObjectText = "Berry Bush"
	eat.Triggered:Connect(function(player)
		if dead[player] or not eat.Enabled then
			return
		end
		local food = Config.BerryFood * (if hasClass(player, "Forager") then 2 else 1)
		hunger[player] = math.min(100, (hunger[player] or 100) + food)
		player:SetAttribute("Hunger", math.floor(hunger[player]))
		eat.Enabled = false
		for _, b in berries do
			b.Transparency = 1
		end
		task.delay(Config.BerryRegrow, function()
			eat.Enabled = true
			for _, b in berries do
				b.Transparency = 0
			end
		end)
	end)
end

---------------------------------------------------------------- campfire

local fuel = Config.StartFuel
local function safeRadius(): number
	if fuel <= 0 then
		return 0
	end
	return Config.BaseSafeRadius + fuel * Config.SafePerFuel
end
local function refreshFire()
	local r = safeRadius()
	workspace:SetAttribute("Fuel", math.floor(fuel))
	workspace:SetAttribute("SafeRadius", r)
	flame.Size = Vector3.one * (1 + fuel / 100 * 5)
	flame.Transparency = if fuel <= 0 then 1 else 0.15
	fireLight.Range = 10 + fuel * 0.6
	safeRing.Size = Vector3.new(0.2, r * 2, r * 2)
	safeRing.Transparency = if fuel <= 0 then 1 else 0.8
end

fuelPrompt.Triggered:Connect(function(player)
	local have = wood[player] or 0
	if have <= 0 then
		notify(player, "You have no wood! Chop trees in the forest.", Color3.fromRGB(255, 200, 0))
		return
	end
	local per = Config.FuelPerWood * (if hasClass(player, "Firekeeper") then 1.5 else 1)
	fuel = math.min(Config.MaxFuel, fuel + have * per)
	wood[player] = 0
	syncWood(player)
	refreshFire()
	notify(player, "+" .. have .. " wood on the fire!", Color3.fromRGB(255, 160, 60))
end)

---------------------------------------------------------------- the Sahur

local monster, monsterRoot = BrainrotModels.Build("tung", { Scale = 1.8 })
monster.Name = "Sahur"
local monsterHeight = (monster:GetAttribute("RootHeight") :: number?) or 6
local eyesLight = Instance.new("PointLight")
eyesLight.Color = Color3.fromRGB(255, 30, 30)
eyesLight.Range = 18
eyesLight.Brightness = 4
eyesLight.Parent = monsterRoot
local MONSTER_HOME = Vector3.new(0, monsterHeight, 300)
monster:PivotTo(CFrame.new(MONSTER_HOME))
monster.Parent = workspace

local state = { Phase = "Day", Night = 0, Banished = false, MonsterPos = MONSTER_HOME }

local function rootOf(player: Player): BasePart?
	if dead[player] then
		return nil
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function monsterStep(dt: number)
	if state.Phase ~= "Night" or state.Banished then
		state.MonsterPos = MONSTER_HOME
		monster:PivotTo(CFrame.new(MONSTER_HOME))
		return
	end
	local safe = safeRadius()
	local best: BasePart?, bestDist = nil, math.huge
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root then
			local fromFire = flat(root.Position).Magnitude
			local d = (flat(root.Position) - flat(state.MonsterPos)).Magnitude
			if fromFire > safe and d < bestDist then
				best, bestDist = root, d
			end
		end
	end
	local pos = flat(state.MonsterPos)
	local goal: Vector3
	if best then
		goal = flat(best.Position)
	else
		-- Nobody outside the light: circle the edge of it.
		local a = os.clock() * 0.3
		goal = Vector3.new(math.cos(a), 0, math.sin(a)) * (safe + 12)
	end
	local speed = Config.MonsterSpeed + state.Night * Config.MonsterSpeedPerNight
	local delta = goal - pos
	if delta.Magnitude > 0.1 then
		local step = delta.Unit * math.min(delta.Magnitude, speed * dt)
		pos += step
		-- Never step into the firelight.
		if pos.Magnitude < safe + 2 and safe > 0 then
			pos = pos.Unit * (safe + 2)
		end
	end
	state.MonsterPos = Vector3.new(pos.X, monsterHeight, pos.Z)
	local facing = if delta.Magnitude > 0.1 then delta.Unit else Vector3.new(0, 0, -1)
	monster:PivotTo(CFrame.lookAt(state.MonsterPos, state.MonsterPos + facing))
	-- Attack
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and (flat(root.Position) - pos).Magnitude < 6 and flat(root.Position).Magnitude > safe then
			local humanoid = (player.Character :: Model):FindFirstChildOfClass("Humanoid") :: Humanoid
			local dmg = Config.MonsterDamage * dt * (if hasClass(player, "Tank") then 0.6 else 1)
			humanoid:TakeDamage(dmg)
		end
	end
end

---------------------------------------------------------------- players

local function applyStats(player: Player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.WalkSpeed = if hasClass(player, "Runner") then 20 else 16
	local maxHealth = if hasClass(player, "Tank") then 160 else 100
	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth
end

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Diamonds", data.Diamonds)
	player:SetAttribute("BestNight", data.BestNight)
	player:SetAttribute("Class", data.Class)
	player:SetAttribute("OwnedClasses", table.concat(data.Classes, ","))
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		(ls :: any)["Best Night"].Value = data.BestNight;
		(ls :: any).Diamonds.Value = data.Diamonds
	end
end

local function revive(player: Player)
	dead[player] = false
	player:SetAttribute("Dead", false)
	hunger[player] = 100
	player:SetAttribute("Hunger", 100)
	local character = player.Character
	if character then
		character:PivotTo(CFrame.new(math.random(-6, 6), 4, 10))
		applyStats(player)
	end
end

local function aliveCount(): number
	local n = 0
	for _, player in Players:GetPlayers() do
		if DataService.Get(player) and not dead[player] then
			n += 1
		end
	end
	return n
end

DataService.ProfileLoaded:Connect(function(player, data)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, name in { "Best Night", "Diamonds" } do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = ls
	end
	ls.Parent = player
	wood[player] = if MonetizationService.OwnsPass(player, "VIP") then 3 else 0
	hunger[player] = 100
	-- Joining at night means you wait for morning, like everyone who died.
	dead[player] = state.Phase == "Night" and state.Night > 0
	player:SetAttribute("Dead", dead[player])
	player:SetAttribute("Hunger", 100)
	syncWood(player)
	sync(player)
	local function onCharacter(character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait()
		applyStats(player)
		if dead[player] then
			character:PivotTo(GHOST)
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				if not dead[player] then
					dead[player] = true
					player:SetAttribute("Dead", true)
					wood[player] = 0
					syncWood(player)
					notify(nil, player.DisplayName .. " was caught in the dark...", Color3.fromRGB(255, 80, 80))
					notify(player, "You died! You'll be back in the morning, or buy a Revive.", Color3.fromRGB(255, 200, 0))
				end
			end)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	if data.Diamonds == 0 and data.BestNight == 0 then
		task.delay(3, notify, player, "Keep the fire alive. Chop trees, eat berries, and stay in the light at night!", Color3.fromRGB(255, 200, 120))
	end
end)

Players.PlayerRemoving:Connect(function(player)
	wood[player] = nil
	hunger[player] = nil
	dead[player] = nil
end)

ClassRemote.OnServerInvoke = function(player, id)
	local data = DataService.Get(player)
	if not data or type(id) ~= "string" then
		return false
	end
	local info
	for _, c in Config.Classes do
		if c.Id == id then
			info = c
		end
	end
	if not info then
		return false
	end
	if not table.find(data.Classes, id) then
		if data.Diamonds < info.Cost then
			notify(player, "You need " .. info.Cost .. " diamonds!", Color3.fromRGB(255, 90, 90))
			return false
		end
		data.Diamonds -= info.Cost
		table.insert(data.Classes, id)
		notify(player, "Unlocked the " .. id .. " class!", Color3.fromRGB(120, 220, 255))
	end
	data.Class = id
	sync(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = if id == "Runner" then 20 else 16
		humanoid.MaxHealth = if id == "Tank" then 160 else 100
	end
	return true
end

---------------------------------------------------------------- day / night loop

local function resetRun()
	state.Night = 0
	fuel = Config.StartFuel
	refreshFire()
	for _, player in Players:GetPlayers() do
		wood[player] = if MonetizationService.OwnsPass(player, "VIP") then 3 else 0
		syncWood(player)
		revive(player)
	end
	notify(nil, "Everyone fell... A new run begins. Day 1!", Color3.fromRGB(255, 200, 120))
end

local function rewardNight()
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		if data and not dead[player] then
			local m = 1
			if MonetizationService.OwnsPass(player, "DoubleDiamonds") then
				m *= 2
			end
			if MonetizationService.OwnsPass(player, "VIP") then
				m *= 1.25
			end
			local gain = math.floor((Config.DiamondsPerNight + state.Night) * m)
			data.Diamonds += gain
			if state.Night > data.BestNight then
				data.BestNight = state.Night
			end
			sync(player)
			notify(player, "Night " .. state.Night .. " survived! +" .. gain .. " 💎", Color3.fromRGB(120, 220, 255))
		end
	end
end

local function runPhase(phase: string, length: number)
	state.Phase = phase
	workspace:SetAttribute("Phase", phase)
	workspace:SetAttribute("Night", state.Night)
	local ends = os.clock() + length
	local last = os.clock()
	local tick = 0
	while os.clock() < ends do
		task.wait(0.1)
		local now = os.clock()
		local dt = now - last
		last = now
		tick += dt
		local progress = 1 - (ends - now) / length
		Lighting.ClockTime = if phase == "Day" then 6 + progress * 12 else (18 + progress * 12) % 24
		Lighting.Brightness = if phase == "Day" then 2.2 else 0.15
		Lighting.Ambient = if phase == "Day" then Color3.fromRGB(120, 120, 120) else Color3.fromRGB(15, 15, 30)
		Lighting.OutdoorAmbient = Lighting.Ambient
		workspace:SetAttribute("TimeLeft", math.ceil(ends - now))
		fuel = math.max(0, fuel - Config.FuelDrain * dt * (if phase == "Night" then 1.6 else 1))
		monsterStep(dt)
		if tick >= 1 then
			tick -= 1
			refreshFire()
			for _, player in Players:GetPlayers() do
				local root = rootOf(player)
				if root then
					local drain = Config.HungerDrain * (if hasClass(player, "Forager") then 0.6 else 1)
					hunger[player] = math.max(0, (hunger[player] or 100) - drain)
					player:SetAttribute("Hunger", math.floor(hunger[player]))
					if hunger[player] <= 0 then
						local humanoid = (player.Character :: Model):FindFirstChildOfClass("Humanoid") :: Humanoid
						humanoid:TakeDamage(4)
					end
				end
			end
			if state.Night > 0 and #Players:GetPlayers() > 0 and aliveCount() == 0 then
				return false
			end
		end
	end
	return true
end

task.spawn(function()
	refreshFire()
	while true do
		state.Banished = false
		if not runPhase("Day", Config.DayLength) then
			resetRun()
			continue
		end
		state.Night += 1
		notify(nil, "🌙 Night " .. state.Night .. " falls. Stay in the light!", Color3.fromRGB(180, 140, 255))
		if not runPhase("Night", Config.NightLength) then
			resetRun()
			continue
		end
		rewardNight()
		-- Morning: everyone who died comes back.
		for _, player in Players:GetPlayers() do
			if dead[player] then
				revive(player)
			end
		end
		notify(nil, "☀️ Morning! Day " .. (state.Night + 1) .. ". Gather wood before dark.", Color3.fromRGB(255, 220, 120))
	end
end)

---------------------------------------------------------------- monetization

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		Revive = function(player, data)
			if dead[player] then
				revive(player)
				notify(nil, player.DisplayName .. " was REVIVED!", Color3.fromRGB(90, 255, 90))
			else
				data.Diamonds += 10
				sync(player)
				notify(player, "You're alive, so you got 10 diamonds instead!", Color3.fromRGB(120, 220, 255))
			end
			return true
		end,
		Diamonds = function(player, data)
			data.Diamonds += 60
			sync(player)
			return true
		end,
		FuelFire = function(player)
			fuel = Config.MaxFuel
			refreshFire()
			notify(nil, player.DisplayName .. " filled the campfire! 🔥", Color3.fromRGB(255, 160, 60))
			return true
		end,
		BanishSahur = function(player)
			state.Banished = true
			notify(nil, player.DisplayName .. " BANISHED Sahur for the rest of this night!", Color3.fromRGB(255, 80, 255))
			return true
		end,
	},
	OnPassOwned = function(player, name)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("NinetyNineNightsSahur_v1", {
	Diamonds = 0,
	BestNight = 0,
	Class = "",
	Classes = {},
})
