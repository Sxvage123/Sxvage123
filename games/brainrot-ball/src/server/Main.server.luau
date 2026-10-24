-- Brainrot Ball server: homing ball, parries, eliminations, rounds, sword crates.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)

Lighting.ClockTime = 17.5
Lighting.Brightness = 2

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
local ParryRemote = remote("RemoteEvent", "Parry")
local ParryFx = remote("RemoteEvent", "ParryFx")
local CrateRemote = remote("RemoteFunction", "OpenCrate")
local EquipRemote = remote("RemoteFunction", "EquipSword")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

---------------------------------------------------------------- map

local ARENA = Vector3.new(0, 0, 300)
local ARENA_RADIUS = 70
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
part({ Name = "Lobby", Size = Vector3.new(90, 2, 90), Position = Vector3.new(0, -1, 0), Color = Color3.fromRGB(235, 235, 245), Material = Enum.Material.Marble })
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = Vector3.new(0, 0.5, 0)
spawn.Neutral = true
spawn.Color = Color3.fromRGB(255, 80, 80)
spawn.Material = Enum.Material.Neon
spawn.Parent = world
part({ Name = "Arena", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, ARENA_RADIUS * 2, ARENA_RADIUS * 2), CFrame = CFrame.new(ARENA - Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(60, 60, 80), Material = Enum.Material.Slate })
for i = 1, 36 do
	local a = i / 36 * math.pi * 2
	part({ Size = Vector3.new(13, 6, 1.5), CFrame = CFrame.new(ARENA + Vector3.new(math.cos(a) * ARENA_RADIUS, 3, math.sin(a) * ARENA_RADIUS)) * CFrame.Angles(0, -a + math.pi / 2, 0), Color = Color3.fromRGB(255, 60, 60), Material = Enum.Material.Neon, Transparency = 0.4 })
end

local ball = part({ Name = "Ball", Shape = Enum.PartType.Ball, Size = Vector3.one * 3, Position = ARENA + Vector3.new(0, 8, 0), Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon, CanCollide = false })
ball.Transparency = 1
local light = Instance.new("PointLight")
light.Range = 16
light.Brightness = 3
light.Parent = ball
local trailA = Instance.new("Attachment")
trailA.Position = Vector3.new(0, 1, 0)
trailA.Parent = ball
local trailB = Instance.new("Attachment")
trailB.Position = Vector3.new(0, -1, 0)
trailB.Parent = ball
local trail = Instance.new("Trail")
trail.Attachment0 = trailA
trail.Attachment1 = trailB
trail.Lifetime = 0.25
trail.LightEmission = 1
trail.Parent = ball

---------------------------------------------------------------- helpers

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("Wins", data.Wins)
	player:SetAttribute("Sword", data.Sword)
	local owned = {}
	for id in data.Swords do
		table.insert(owned, id)
	end
	player:SetAttribute("OwnedSwords", table.concat(owned, ","))
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Wins.Value = data.Wins
		stats.Kills.Value = data.Kills
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

local function addCoins(player: Player, amount: number)
	local data = DataService.Get(player)
	if data then
		data.Coins += math.floor(amount)
		sync(player)
	end
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function alive(): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("Alive") and rootOf(p) then
			table.insert(list, p)
		end
	end
	return list
end

local function equipSword(player: Player)
	local data = DataService.Get(player)
	local character = player.Character
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")) :: BasePart?
	if not data or not hand then
		return
	end
	local old = character:FindFirstChild("SwordBlade")
	if old then
		old:Destroy()
	end
	local sword = Config.SwordById[data.Sword] or Config.Swords[1]
	local blade = Instance.new("Part")
	blade.Name = "SwordBlade"
	blade.Size = Vector3.new(0.35, 0.35, 5)
	blade.Color = sword.Color
	blade.Material = sword.Material
	blade.CanCollide = false
	blade.CanQuery = false
	blade.Massless = true
	blade.CFrame = hand.CFrame * CFrame.new(0, -hand.Size.Y / 2, -2.4)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = blade
	weld.Parent = blade
	blade.Parent = character
end

---------------------------------------------------------------- ball

local state = {
	Active = false,
	Target = nil :: Player?,
	Speed = Config.BallStartSpeed,
	LastHitter = nil :: Player?,
	PausedUntil = 0,
}
local parryPressed: { [Player]: number } = {}
local parryCooldown: { [Player]: number } = {}

local function setTarget(player: Player?)
	state.Target = player
	ball:SetAttribute("TargetId", if player then player.UserId else 0)
	ball.Color = Color3.fromHSV(math.random(), 0.8, 1)
end

local function pickTarget(exclude: Player?, aim: Vector3?, from: Vector3?): Player?
	local candidates = {}
	for _, p in alive() do
		if p ~= exclude then
			table.insert(candidates, p)
		end
	end
	if #candidates == 0 then
		return exclude
	end
	if aim and from then
		local best, bestDot = nil, -2
		for _, p in candidates do
			local root = rootOf(p) :: BasePart
			local dot = (root.Position - from).Unit:Dot(aim.Unit)
			if dot > bestDot then
				best, bestDot = p, dot
			end
		end
		if best and bestDot > 0.5 then
			return best
		end
	end
	return candidates[math.random(1, #candidates)]
end

local function parryRange(): number
	return math.max(14, state.Speed * 0.4)
end

local function deflect(player: Player, aim: Vector3?)
	parryCooldown[player] = 0
	parryPressed[player] = nil
	state.Speed = math.min(Config.BallMaxSpeed, state.Speed + Config.BallSpeedGain)
	state.LastHitter = player
	local root = rootOf(player)
	setTarget(pickTarget(player, aim, root and root.Position))
	ParryFx:FireAllClients(ball.Position, player.UserId)
end

ParryRemote.OnServerEvent:Connect(function(player, aim)
	if not state.Active or not player:GetAttribute("Alive") then
		return
	end
	local now = os.clock()
	if now < (parryCooldown[player] or 0) then
		return
	end
	if typeof(aim) ~= "Vector3" or aim.Magnitude < 0.5 then
		aim = nil
	end
	local root = rootOf(player)
	if state.Target == player and root and (ball.Position - root.Position).Magnitude <= parryRange() then
		deflect(player, aim)
		return
	end
	-- Too early: remember the press briefly (latency forgiveness), then cooldown.
	parryPressed[player] = now
	parryCooldown[player] = now + Config.ParryCooldown
	player:SetAttribute("ParryAim", aim)
end)

local function eliminate(player: Player)
	player:SetAttribute("Alive", false)
	local root = rootOf(player)
	if root then
		local boom = Instance.new("Explosion")
		boom.Position = root.Position
		boom.BlastPressure = 0
		boom.DestroyJointRadiusPercent = 0
		boom.Parent = workspace
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
	local killer = state.LastHitter
	if killer and killer ~= player and killer.Parent then
		local data = DataService.Get(killer)
		if data then
			data.Kills += 1
			addCoins(killer, Config.KillCoins * coinMult(killer))
		end
		notify(nil, killer.DisplayName .. " eliminated " .. player.DisplayName .. "!", Color3.fromRGB(255, 120, 80))
	else
		notify(nil, player.DisplayName .. " got hit by the ball!", Color3.fromRGB(255, 120, 80))
	end
	state.Speed = Config.BallStartSpeed
	state.LastHitter = nil
	state.PausedUntil = os.clock() + 1.5
	ball.Position = ARENA + Vector3.new(0, 8, 0)
	setTarget(pickTarget(nil))
end

RunService.Heartbeat:Connect(function(dt)
	if not state.Active then
		return
	end
	local now = os.clock()
	if now < state.PausedUntil then
		return
	end
	local target = state.Target
	local root = target and target:GetAttribute("Alive") and rootOf(target)
	if not root then
		setTarget(pickTarget(nil))
		return
	end
	local toTarget = root.Position - ball.Position
	local dist = toTarget.Magnitude
	local step = state.Speed * dt
	if dist <= step + 2.5 then
		local pressed = parryPressed[target :: Player]
		if pressed and now - pressed <= Config.ParryWindow then
			deflect(target :: Player, (target :: Player):GetAttribute("ParryAim") :: Vector3?)
		else
			eliminate(target :: Player)
		end
		return
	end
	ball.Position += toTarget.Unit * step
end)

---------------------------------------------------------------- rounds

local function arenaSpawn(i: number, n: number): CFrame
	local a = i / n * math.pi * 2
	local pos = ARENA + Vector3.new(math.cos(a) * 45, 4, math.sin(a) * 45)
	return CFrame.lookAt(pos, ARENA + Vector3.new(0, 4, 0))
end

task.spawn(function()
	while true do
		for t = Config.Intermission, 1, -1 do
			workspace:SetAttribute("RoundState", "Intermission")
			workspace:SetAttribute("TimeLeft", t)
			task.wait(1)
		end
		local players = {}
		for _, p in Players:GetPlayers() do
			if DataService.Get(p) and rootOf(p) then
				table.insert(players, p)
			end
		end
		local minPlayers = if RunService:IsStudio() then 1 else Config.MinPlayers
		if #players < minPlayers then
			workspace:SetAttribute("RoundState", "Waiting")
			task.wait(2)
			continue
		end
		for i, p in players do
			p:SetAttribute("Alive", true)
			p.Character:PivotTo(arenaSpawn(i, #players))
		end
		workspace:SetAttribute("RoundState", "Playing")
		state.Speed = Config.BallStartSpeed
		state.LastHitter = nil
		state.PausedUntil = os.clock() + 2
		ball.Position = ARENA + Vector3.new(0, 8, 0)
		ball.Transparency = 0
		setTarget(pickTarget(nil))
		state.Active = true
		local solo = #players == 1
		while true do
			local left = alive()
			workspace:SetAttribute("AliveCount", #left)
			if #left == 0 or (not solo and #left <= 1) then
				break
			end
			task.wait(0.2)
		end
		state.Active = false
		ball.Transparency = 1
		setTarget(nil)
		local winners = alive()
		for _, w in winners do
			local data = DataService.Get(w)
			if data then
				data.Wins += 1
				addCoins(w, Config.WinCoins * coinMult(w))
			end
			notify(nil, w.DisplayName .. " WINS THE ROUND!", Color3.fromRGB(255, 215, 0))
			w:SetAttribute("Alive", false)
			if w.Character then
				w.Character:PivotTo(CFrame.new(0, 4, 0))
			end
		end
		workspace:SetAttribute("RoundState", "Ended")
		task.wait(3)
	end
end)

---------------------------------------------------------------- crates

local function rollSword(player: Player)
	local lucky = MonetizationService.OwnsPass(player, "LuckyCrates")
	local total = 0
	for i, r in Config.Rarities do
		total += r.Weight * (if lucky and i >= 3 then 2 else 1)
	end
	local roll = math.random() * total
	local rarity = Config.Rarities[1].Name
	for i, r in Config.Rarities do
		roll -= r.Weight * (if lucky and i >= 3 then 2 else 1)
		if roll <= 0 then
			rarity = r.Name
			break
		end
	end
	local pool = {}
	for _, s in Config.Swords do
		if s.Rarity == rarity then
			table.insert(pool, s.Id)
		end
	end
	return pool[math.random(1, #pool)]
end

CrateRemote.OnServerInvoke = function(player)
	local data = DataService.Get(player)
	if not data then
		return false, "Loading..."
	end
	if data.Coins < Config.CrateCost then
		return false, "Need " .. Config.CrateCost .. " coins!"
	end
	data.Coins -= Config.CrateCost
	local id = rollSword(player)
	local sword = Config.SwordById[id]
	local duplicate = data.Swords[id] == true
	if duplicate then
		data.Coins += math.floor(Config.CrateCost * 0.25)
	else
		data.Swords[id] = true
	end
	if sword.Rarity == "Legendary" or sword.Rarity == "Mythic" then
		notify(nil, player.DisplayName .. " unboxed " .. sword.Rarity .. " " .. sword.Name .. "!", Config.RarityColor[sword.Rarity])
	end
	sync(player)
	return true, id, duplicate
end

EquipRemote.OnServerInvoke = function(player, id)
	local data = DataService.Get(player)
	if not data or type(id) ~= "string" or not data.Swords[id] then
		return false
	end
	data.Sword = id
	equipSword(player)
	sync(player)
	return true
end

---------------------------------------------------------------- players

local function addTrail(player: Player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or root:FindFirstChild("VIPTrail") then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1, 0)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -1, 0)
	a1.Parent = root
	local t = Instance.new("Trail")
	t.Name = "VIPTrail"
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	t.LightEmission = 1
	t.Lifetime = 0.4
	t.Parent = root
end

DataService.ProfileLoaded:Connect(function(player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in { "Wins", "Kills" } do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = stats
	end
	stats.Parent = player
	sync(player)
	local function onCharacter(character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait(0.2)
		if state.Active and player:GetAttribute("Alive") then
			character:PivotTo(arenaSpawn(math.random(1, 12), 12))
		end
		equipSword(player)
		if MonetizationService.OwnsPass(player, "VIP") then
			addTrail(player)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	parryPressed[player] = nil
	parryCooldown[player] = nil
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		CoinsSmall = function(player)
			addCoins(player, 1000)
			return true
		end,
		CoinsLarge = function(player)
			addCoins(player, 6000)
			return true
		end,
		Respawn = function(player)
			if state.Active and not player:GetAttribute("Alive") then
				player:SetAttribute("Alive", true)
				player:LoadCharacter()
				notify(nil, player.DisplayName .. " got a SECOND CHANCE!", Color3.fromRGB(90, 255, 90))
			else
				addCoins(player, 300)
				notify(player, "No round to rejoin — you got 300 coins instead!", Color3.fromRGB(255, 215, 0))
			end
			return true
		end,
	},
	OnPassOwned = function(player, name)
		if name == "VIP" then
			addTrail(player)
		end
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("BrainrotBall_v1", {
	Coins = 0,
	Wins = 0,
	Kills = 0,
	Swords = { stick = true },
	Sword = "stick",
})
