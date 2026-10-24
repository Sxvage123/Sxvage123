-- Sahur Mystery server: roles (Sahur / Sheriff / Innocents), bat + gun combat, coins, crates, perks.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local BrainrotModels = require(ReplicatedStorage.Common.BrainrotModels)
local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)

Lighting.ClockTime = 20.5
Lighting.Brightness = 1.2
Lighting.OutdoorAmbient = Color3.fromRGB(90, 90, 120)

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
local RoleRemote = remote("RemoteEvent", "Role")
local BatRemote = remote("RemoteEvent", "Bat")
local GunRemote = remote("RemoteEvent", "Gun")
local TracerRemote = remote("RemoteEvent", "Tracer")
local CrateRemote = remote("RemoteFunction", "OpenCrate")
local EquipRemote = remote("RemoteFunction", "EquipSkin")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

---------------------------------------------------------------- lobby + mansion map

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
part({ Name = "Lobby", Size = Vector3.new(60, 2, 60), Position = Vector3.new(0, -1, 0), Color = Color3.fromRGB(230, 225, 240), Material = Enum.Material.Marble })
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = Vector3.new(0, 0.5, 0)
spawn.Neutral = true
spawn.Parent = world
if BrainrotModels.Has("tung") then
	local statue = BrainrotModels.Build("tung", { Scale = 2 })
	statue:PivotTo(CFrame.new(0, statue:GetAttribute("RootHeight"), 24) * CFrame.Angles(0, math.pi, 0))
	statue.Parent = world
end

local MANSION = Vector3.new(0, 0, 300)
local SIZE = 120
part({ Name = "MansionFloor", Size = Vector3.new(SIZE, 2, SIZE), Position = MANSION - Vector3.new(0, 1, 0), Color = Color3.fromRGB(150, 110, 75), Material = Enum.Material.WoodPlanks })
for _, s in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
	part({ Size = if s[1] ~= 0 then Vector3.new(2, 16, SIZE) else Vector3.new(SIZE, 16, 2), Position = MANSION + Vector3.new(s[1] * SIZE / 2, 8, s[2] * SIZE / 2), Color = Color3.fromRGB(120, 60, 60), Material = Enum.Material.Brick })
end
-- Interior walls on a grid with doorways.
local rng = Random.new(99)
for gx = -2, 2 do
	for gz = -2, 2 do
		local c = MANSION + Vector3.new(gx * 24, 0, gz * 24)
		if gx < 2 and rng:NextNumber() < 0.7 then
			part({ Size = Vector3.new(1, 12, 9), Position = c + Vector3.new(12, 6, -7.5), Color = Color3.fromRGB(200, 185, 160), Material = Enum.Material.Plaster })
			part({ Size = Vector3.new(1, 12, 9), Position = c + Vector3.new(12, 6, 7.5), Color = Color3.fromRGB(200, 185, 160), Material = Enum.Material.Plaster })
		end
		if gz < 2 and rng:NextNumber() < 0.7 then
			part({ Size = Vector3.new(9, 12, 1), Position = c + Vector3.new(-7.5, 6, 12), Color = Color3.fromRGB(200, 185, 160), Material = Enum.Material.Plaster })
			part({ Size = Vector3.new(9, 12, 1), Position = c + Vector3.new(7.5, 6, 12), Color = Color3.fromRGB(200, 185, 160), Material = Enum.Material.Plaster })
		end
		if rng:NextNumber() < 0.4 then
			part({ Size = Vector3.new(6, 3, 3), Position = c + Vector3.new(rng:NextNumber(-6, 6), 1.5, rng:NextNumber(-6, 6)), Color = Color3.fromRGB(90, 50, 40), Material = Enum.Material.Fabric })
		end
		local lamp = part({ Size = Vector3.new(1, 1, 1), Position = c + Vector3.new(0, 11, 0), Color = Color3.fromRGB(255, 220, 150), Material = Enum.Material.Neon, CanCollide = false })
		local light = Instance.new("PointLight")
		light.Range = 22
		light.Brightness = 1.5
		light.Parent = lamp
	end
end
local coinFolder = Instance.new("Folder")
coinFolder.Name = "Coins"
coinFolder.Parent = workspace

local function randomMansionPoint(): Vector3
	return MANSION + Vector3.new(rng:NextNumber(-SIZE / 2 + 4, SIZE / 2 - 4), 3, rng:NextNumber(-SIZE / 2 + 4, SIZE / 2 - 4))
end

---------------------------------------------------------------- data helpers

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("Wins", data.Wins)
	player:SetAttribute("BatSkin", data.BatSkin)
	player:SetAttribute("GunSkin", data.GunSkin)
	player:SetAttribute("SahurPerk", data.SahurPerk)
	player:SetAttribute("SheriffPerk", data.SheriffPerk)
	local owned = {}
	for id in data.Skins do
		table.insert(owned, id)
	end
	player:SetAttribute("OwnedSkins", table.concat(owned, ","))
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Wins.Value = data.Wins
		stats.Coins.Value = data.Coins
	end
end

local function coinMult(player: Player): number
	local m = 1
	if MonetizationService.OwnsPass(player, "DoubleCoins") then
		m *= 2
	end
	if MonetizationService.OwnsPass(player, "VIP") then
		m *= 1.5
	end
	return m
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function makeWeapon(kind: string, skinId: string): Tool
	local skin = Config.SkinById[skinId] or Config.SkinById[if kind == "Bat" then "bat_wood" else "gun_basic"]
	local tool = Instance.new("Tool")
	tool.Name = kind
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = if kind == "Bat" then Vector3.new(0.4, 4.4, 0.4) else Vector3.new(0.4, 1.0, 1.8)
	handle.Color = skin.Color
	handle.Material = (Enum.Material :: any)[skin.Material]
	handle.CanCollide = false
	handle.Parent = tool
	if kind == "Bat" then
		tool.GripPos = Vector3.new(0, -1.6, 0)
		local barrel = Instance.new("Part")
		barrel.Shape = Enum.PartType.Cylinder
		barrel.Size = Vector3.new(2.0, 0.75, 0.75)
		barrel.Color = skin.Color
		barrel.Material = handle.Material
		barrel.CanCollide = false
		barrel.Massless = true
		barrel.CFrame = handle.CFrame * CFrame.new(0, 1.7, 0) * CFrame.Angles(0, 0, math.rad(90))
		local w = Instance.new("WeldConstraint")
		w.Part0 = handle
		w.Part1 = barrel
		w.Parent = barrel
		barrel.Parent = tool
	end
	return tool
end

---------------------------------------------------------------- round state

local round = { Active = false, Sahur = nil :: Player?, Sheriff = nil :: Player?, Hero = nil :: Player?, Coins = {} :: { [Player]: number }, Over = false, Winner = "" }
local lastBat: { [Player]: number } = {}
local lastGun: { [Player]: number } = {}
local droppedGun: BasePart? = nil

local function alive(): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("InRound") and rootOf(p) then
			table.insert(list, p)
		end
	end
	return list
end

local function endRound(winner: string)
	if round.Over then
		return
	end
	round.Over = true
	round.Winner = winner
end

local function clearDroppedGun()
	if droppedGun then
		droppedGun:Destroy()
		droppedGun = nil
	end
end

local function dropGun(at: Vector3)
	clearDroppedGun()
	local gun = part({ Name = "DroppedGun", Size = Vector3.new(0.6, 1, 2), Position = at + Vector3.new(0, 1, 0), Color = Color3.fromRGB(80, 120, 255), Material = Enum.Material.Neon, CanCollide = false })
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickupGun"
	prompt.ActionText = "Pick up Gun"
	prompt.RequiresLineOfSight = false
	prompt.Parent = gun
	prompt.Triggered:Connect(function(player)
		if not round.Active or player == round.Sahur or not player:GetAttribute("InRound") or not rootOf(player) then
			return
		end
		clearDroppedGun()
		round.Hero = player
		player:SetAttribute("Role", "Hero")
		local data = DataService.Get(player)
		makeWeapon("Gun", data and data.GunSkin or "gun_basic").Parent = player:FindFirstChildOfClass("Backpack")
		RoleRemote:FireClient(player, "Hero")
		notify(nil, "Someone picked up the gun!", Color3.fromRGB(80, 160, 255))
	end)
	droppedGun = gun
	notify(nil, "The Sheriff fell! The gun dropped — innocents can grab it!", Color3.fromRGB(80, 160, 255))
end

local function kill(victim: Player, by: Player?)
	local character = victim.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local root = rootOf(victim)
	local at = if root then root.Position else MANSION
	humanoid.Health = 0
	victim:SetAttribute("InRound", false)
	if victim == round.Sahur then
		notify(nil, "TUNG TUNG SAHUR WAS STOPPED by " .. (if by then by.DisplayName else "someone") .. "!", Color3.fromRGB(90, 255, 90))
		if by then
			local data = DataService.Get(by)
			if data then
				data.Coins += math.floor(Config.WinCoins * coinMult(by))
				sync(by)
			end
		end
		endRound("Innocents")
		return
	end
	if victim == round.Sheriff or victim == round.Hero then
		dropGun(at)
	end
end

BatRemote.OnServerEvent:Connect(function(player)
	if not round.Active or round.Over or player ~= round.Sahur then
		return
	end
	local root = rootOf(player)
	if not root or not (player.Character and player.Character:FindFirstChild("Bat")) then
		return
	end
	local now = os.clock()
	if now - (lastBat[player] or 0) < Config.BatCooldown then
		return
	end
	lastBat[player] = now
	local best, bestDist = nil, Config.BatRange
	for _, p in alive() do
		if p ~= player then
			local r = rootOf(p) :: BasePart
			local d = (r.Position - root.Position).Magnitude
			if d <= bestDist then
				best, bestDist = p, d
			end
		end
	end
	if best then
		kill(best, player)
	end
end)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
GunRemote.OnServerEvent:Connect(function(player, target)
	if not round.Active or round.Over or typeof(target) ~= "Vector3" then
		return
	end
	if player ~= round.Sheriff and player ~= round.Hero then
		return
	end
	local head = player.Character and player.Character:FindFirstChild("Head") :: BasePart?
	if not head or not player.Character:FindFirstChild("Gun") then
		return
	end
	local now = os.clock()
	if now - (lastGun[player] or 0) < Config.GunCooldown then
		return
	end
	lastGun[player] = now
	local dir = target - head.Position
	if dir.Magnitude < 0.1 then
		return
	end
	rayParams.FilterDescendantsInstances = { player.Character, coinFolder }
	local hit = workspace:Raycast(head.Position, dir.Unit * Config.GunRange, rayParams)
	local endPos = if hit then hit.Position else head.Position + dir.Unit * Config.GunRange
	TracerRemote:FireAllClients(head.Position, endPos)
	local victimModel = hit and hit.Instance:FindFirstAncestorOfClass("Model")
	local victim = victimModel and Players:GetPlayerFromCharacter(victimModel)
	if victim and victim:GetAttribute("InRound") then
		if victim == round.Sahur then
			kill(victim, player)
		else
			-- Shot an innocent: both die, gun drops.
			kill(victim, player)
			notify(nil, player.DisplayName .. " shot an innocent!", Color3.fromRGB(255, 90, 90))
			kill(player, nil)
		end
	end
end)

---------------------------------------------------------------- coins

local function spawnCoin()
	local coin = part({ Name = "Coin", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 1.6, 1.6), Position = randomMansionPoint(), Color = Color3.fromRGB(255, 200, 40), Material = Enum.Material.Neon, CanCollide = false })
	coin.CFrame *= CFrame.Angles(0, 0, math.rad(90))
	coin.Parent = coinFolder
	coin.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or not round.Active or not player:GetAttribute("InRound") or not coin.Parent then
			return
		end
		local cap = if MonetizationService.OwnsPass(player, "VIP") then Config.VIPCoinBag else Config.CoinBag
		if (round.Coins[player] or 0) >= cap then
			return
		end
		coin:Destroy()
		round.Coins[player] = (round.Coins[player] or 0) + 1
		player:SetAttribute("RoundCoins", round.Coins[player])
	end)
end

---------------------------------------------------------------- round loop

local function pickWeighted(pool: { Player }, perkKey: string): Player
	local total = 0
	local weights = {}
	for i, p in pool do
		local data = DataService.Get(p)
		weights[i] = 1 + (if data and data[perkKey] > 0 then 15 else 0)
		total += weights[i]
	end
	local r = math.random() * total
	for i, p in pool do
		r -= weights[i]
		if r <= 0 then
			return p
		end
	end
	return pool[#pool]
end

task.spawn(function()
	while true do
		for t = Config.Intermission, 1, -1 do
			workspace:SetAttribute("RoundState", "Intermission")
			workspace:SetAttribute("TimeLeft", t)
			task.wait(1)
		end
		local pool = {}
		for _, p in Players:GetPlayers() do
			if DataService.Get(p) and rootOf(p) then
				table.insert(pool, p)
			end
		end
		local minPlayers = if RunService:IsStudio() then 1 else Config.MinPlayers
		if #pool < minPlayers then
			workspace:SetAttribute("RoundState", "Waiting")
			task.wait(2)
			continue
		end
		round.Active = true
		round.Over = false
		round.Winner = ""
		round.Hero = nil
		round.Coins = {}
		table.clear(lastBat)
		table.clear(lastGun)
		round.Sahur = pickWeighted(pool, "SahurPerk")
		local rest = {}
		for _, p in pool do
			if p ~= round.Sahur then
				table.insert(rest, p)
			end
		end
		round.Sheriff = if #rest > 0 then pickWeighted(rest, "SheriffPerk") else nil
		for _, p in pool do
			local data = DataService.Get(p)
			local role = if p == round.Sahur then "Sahur" elseif p == round.Sheriff then "Sheriff" else "Innocent"
			if data then
				if role == "Sahur" and data.SahurPerk > 0 then
					data.SahurPerk -= 1
				elseif role == "Sheriff" and data.SheriffPerk > 0 then
					data.SheriffPerk -= 1
				end
				sync(p)
			end
			p:SetAttribute("Role", role)
			p:SetAttribute("InRound", true)
			p:SetAttribute("RoundCoins", 0)
			p.Character:PivotTo(CFrame.new(randomMansionPoint()))
			RoleRemote:FireClient(p, role)
			local backpack = p:FindFirstChildOfClass("Backpack")
			if role == "Sahur" then
				makeWeapon("Bat", data and data.BatSkin or "bat_wood").Parent = backpack
			elseif role == "Sheriff" then
				makeWeapon("Gun", data and data.GunSkin or "gun_basic").Parent = backpack
			end
		end
		coinFolder:ClearAllChildren()
		for _ = 1, 25 do
			spawnCoin()
		end
		workspace:SetAttribute("RoundState", "Playing")
		local started = os.clock()
		local nextCoin = os.clock()
		while not round.Over do
			local left = Config.RoundTime - (os.clock() - started)
			workspace:SetAttribute("TimeLeft", math.ceil(left))
			local living = alive()
			workspace:SetAttribute("AliveCount", #living)
			if left <= 0 then
				endRound("Innocents")
			elseif round.Sahur and not round.Sahur:GetAttribute("InRound") then
				endRound("Innocents")
			else
				local innocents = 0
				for _, p in living do
					if p ~= round.Sahur then
						innocents += 1
					end
				end
				if innocents == 0 and #pool > 1 then
					endRound("Sahur")
				end
			end
			-- Coin Magnet pass: collect coins within 14 studs.
			for _, p in living do
				if MonetizationService.OwnsPass(p, "CoinMagnet") then
					local r = rootOf(p)
					local cap = if MonetizationService.OwnsPass(p, "VIP") then Config.VIPCoinBag else Config.CoinBag
					for _, coin in coinFolder:GetChildren() do
						if r and (round.Coins[p] or 0) < cap and coin:IsA("BasePart") and (coin.Position - r.Position).Magnitude <= 14 then
							coin:Destroy()
							round.Coins[p] = (round.Coins[p] or 0) + 1
							p:SetAttribute("RoundCoins", round.Coins[p])
						end
					end
				end
			end
			if os.clock() >= nextCoin and #coinFolder:GetChildren() < 40 then
				nextCoin = os.clock() + 2
				spawnCoin()
			end
			task.wait(0.25)
		end
		-- rewards
		local sahur = round.Sahur
		for _, p in pool do
			local data = DataService.Get(p)
			if data and p.Parent then
				local earned = round.Coins[p] or 0
				local won = (round.Winner == "Sahur" and p == sahur) or (round.Winner == "Innocents" and p ~= sahur)
				if won then
					earned += Config.WinCoins
					data.Wins += 1
				end
				data.Coins += math.floor(earned * coinMult(p))
				sync(p)
			end
		end
		notify(nil, if round.Winner == "Sahur" then "TUNG TUNG SAHUR WINS! It was " .. (if sahur then sahur.DisplayName else "?") else "INNOCENTS WIN! Sahur was " .. (if sahur then sahur.DisplayName else "?"), if round.Winner == "Sahur" then Color3.fromRGB(255, 70, 70) else Color3.fromRGB(90, 255, 90))
		round.Active = false
		clearDroppedGun()
		coinFolder:ClearAllChildren()
		for _, p in Players:GetPlayers() do
			p:SetAttribute("Role", nil)
			p:SetAttribute("InRound", false)
			for _, container in { p:FindFirstChildOfClass("Backpack"), p.Character } do
				for _, name in { "Bat", "Gun" } do
					local tool = container and container:FindFirstChild(name)
					if tool then
						tool:Destroy()
					end
				end
			end
			if rootOf(p) then
				p.Character:PivotTo(CFrame.new(0, 4, 0))
			end
		end
		workspace:SetAttribute("RoundState", "Ended")
		task.wait(5)
	end
end)

---------------------------------------------------------------- crates + skins

CrateRemote.OnServerInvoke = function(player)
	local data = DataService.Get(player)
	if not data then
		return false, "Loading..."
	end
	if data.Coins < Config.CrateCost then
		return false, "Need " .. Config.CrateCost .. " coins!"
	end
	data.Coins -= Config.CrateCost
	local total = 0
	for _, r in Config.Rarities do
		total += r.Weight
	end
	local roll = math.random() * total
	local rarity = Config.Rarities[1].Name
	for _, r in Config.Rarities do
		roll -= r.Weight
		if roll <= 0 then
			rarity = r.Name
			break
		end
	end
	local pool = {}
	for _, s in Config.Skins do
		if s.Rarity == rarity then
			table.insert(pool, s.Id)
		end
	end
	local id = pool[math.random(1, #pool)]
	data.Skins[id] = (data.Skins[id] or 0) + 1
	local skin = Config.SkinById[id]
	if rarity == "Legendary" or rarity == "Godly" then
		notify(nil, player.DisplayName .. " unboxed " .. rarity .. " " .. skin.Name .. "!", Config.RarityColor[rarity])
	end
	sync(player)
	return true, id
end

EquipRemote.OnServerInvoke = function(player, id)
	local data = DataService.Get(player)
	local skin = type(id) == "string" and Config.SkinById[id]
	if not data or not skin or not data.Skins[id] then
		return false
	end
	if skin.Kind == "Bat" then
		data.BatSkin = id
	else
		data.GunSkin = id
	end
	sync(player)
	return true
end

---------------------------------------------------------------- players + monetization

DataService.ProfileLoaded:Connect(function(player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in { "Wins", "Coins" } do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = stats
	end
	stats.Parent = player
	sync(player)
end)

Players.PlayerRemoving:Connect(function(player)
	lastBat[player] = nil
	lastGun[player] = nil
	if round.Active and player == round.Sahur then
		notify(nil, "Sahur left the game!", Color3.fromRGB(255, 200, 80))
		endRound("Innocents")
	elseif round.Active and (player == round.Sheriff or player == round.Hero) then
		local root = rootOf(player)
		dropGun(if root then root.Position else MANSION)
	end
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		SahurPerk = function(player, data)
			data.SahurPerk += 1
			sync(player)
			notify(player, "You're very likely to be Sahur next round!", Color3.fromRGB(255, 80, 80))
			return true
		end,
		SheriffPerk = function(player, data)
			data.SheriffPerk += 1
			sync(player)
			notify(player, "You're very likely to be Sheriff next round!", Color3.fromRGB(80, 160, 255))
			return true
		end,
		CoinPack = function(player, data)
			data.Coins += 1000
			sync(player)
			return true
		end,
	},
	OnPassOwned = function(player, name)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("SahurMystery_v1", {
	Coins = 0,
	Wins = 0,
	Skins = { bat_wood = 1, gun_basic = 1 },
	BatSkin = "bat_wood",
	GunSkin = "gun_basic",
	SahurPerk = 0,
	SheriffPerk = 0,
})
