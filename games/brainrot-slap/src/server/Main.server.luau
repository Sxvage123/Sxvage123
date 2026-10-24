-- Brainrot Slap Battles server: island arena, glove tools, validated slaps, kills, glove shop.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BrainrotModels = require(ReplicatedStorage.Common.BrainrotModels)
local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)

Lighting.ClockTime = 15
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
local SlapRemote = remote("RemoteEvent", "Slap")
local AbilityRemote = remote("RemoteEvent", "Ability")
local KnockbackRemote = remote("RemoteEvent", "Knockback")
local BuyGloveRemote = remote("RemoteFunction", "BuyGlove")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

---------------------------------------------------------------- map: lobby + floating island

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
local LOBBY = Vector3.new(0, 60, -120)
part({ Name = "Lobby", Size = Vector3.new(50, 2, 50), Position = LOBBY - Vector3.new(0, 1, 0), Color = Color3.fromRGB(235, 235, 245), Material = Enum.Material.Marble })
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = LOBBY + Vector3.new(0, 0.5, 0)
spawn.Neutral = true
spawn.Color = Color3.fromRGB(255, 200, 80)
spawn.Material = Enum.Material.Neon
spawn.Parent = world
local portal = part({ Name = "ArenaPortal", Size = Vector3.new(10, 12, 2), Position = LOBBY + Vector3.new(0, 6, 22), Color = Color3.fromRGB(170, 0, 255), Material = Enum.Material.Neon, Transparency = 0.3, CanCollide = false })

local ISLAND = Vector3.new(0, 0, 0)
part({ Name = "Island", Shape = Enum.PartType.Cylinder, Size = Vector3.new(10, 140, 140), CFrame = CFrame.new(ISLAND - Vector3.new(0, 5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(100, 200, 90), Material = Enum.Material.Grass })
part({ Name = "Dirt", Shape = Enum.PartType.Cylinder, Size = Vector3.new(16, 120, 120), CFrame = CFrame.new(ISLAND - Vector3.new(0, 16, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(120, 85, 55), Material = Enum.Material.Ground })
-- Giant brainrot statues on the island for flavour + cover.
for i, id in { "tung", "tralalero", "bombardiro", "ballerina" } do
	if BrainrotModels.Has(id) then
		local a = i / 4 * math.pi * 2
		local figure = BrainrotModels.Build(id, { Scale = 2.2 })
		local pos = Vector3.new(math.cos(a) * 42, figure:GetAttribute("RootHeight"), math.sin(a) * 42)
		figure:PivotTo(CFrame.lookAt(pos, Vector3.new(0, pos.Y, 0)))
		for _, d in figure:GetDescendants() do
			if d:IsA("BasePart") then
				d.CanCollide = true
			end
		end
		figure.Parent = world
	end
end

---------------------------------------------------------------- state

local lastSlap: { [Player]: number } = {}
local lastAbility: { [Player]: number } = {}
local lastHitBy: { [Player]: { by: Player, at: number } } = {}
local shieldUntil: { [Player]: number } = {}

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Slaps", data.Slaps)
	player:SetAttribute("Kills", data.Kills)
	player:SetAttribute("Glove", data.Glove)
	local owned = {}
	for id in data.Owned do
		table.insert(owned, id)
	end
	player:SetAttribute("OwnedGloves", table.concat(owned, ","))
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Slaps.Value = data.Slaps
		stats.Kills.Value = data.Kills
	end
end

local function slapMult(player: Player): number
	local m = 1
	if MonetizationService.OwnsPass(player, "DoubleSlaps") then
		m *= 2
	end
	if MonetizationService.OwnsPass(player, "VIP") then
		m *= 1.5
	end
	return m
end

local function addSlaps(player: Player, amount: number)
	local data = DataService.Get(player)
	if data then
		data.Slaps += math.floor(amount * slapMult(player) + 0.5)
		sync(player)
	end
end

local function owns(player: Player, glove): boolean
	if glove.Pass then
		return MonetizationService.OwnsPass(player, glove.Pass)
	end
	local data = DataService.Get(player)
	return data ~= nil and data.Owned[glove.Id] == true
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function inArena(player: Player): boolean
	local root = rootOf(player)
	return root ~= nil and (root.Position - ISLAND).Magnitude < 160 and root.Position.Y < 40
end

local function giveGlove(player: Player)
	local data = DataService.Get(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not data or not backpack then
		return
	end
	for _, container in { backpack, player.Character } do
		local old = container and container:FindFirstChild("Glove")
		if old then
			old:Destroy()
		end
	end
	local glove = Config.GloveById[data.Glove] or Config.Gloves[1]
	local tool = Instance.new("Tool")
	tool.Name = "Glove"
	tool.ToolTip = glove.Name
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1.4, 1.6, 0.8)
	handle.Color = glove.Color
	handle.Material = if glove.Pass then Enum.Material.Neon else Enum.Material.SmoothPlastic
	handle.CanCollide = false
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = handle
	handle.Parent = tool
	tool.Parent = backpack
end

---------------------------------------------------------------- slapping

local function knock(victim: Player, from: Vector3, power: number, attacker: Player)
	if (shieldUntil[victim] or 0) > os.clock() then
		return false
	end
	local root = rootOf(victim)
	if not root then
		return false
	end
	local dir = (root.Position - from) * Vector3.new(1, 0, 1)
	dir = if dir.Magnitude > 0.1 then dir.Unit else Vector3.xAxis
	KnockbackRemote:FireClient(victim, dir * power + Vector3.new(0, power * 0.45, 0))
	lastHitBy[victim] = { by = attacker, at = os.clock() }
	return true
end

local function nearby(attacker: Player, center: Vector3, radius: number): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		local r = p ~= attacker and inArena(p) and rootOf(p)
		if r and (r.Position - center).Magnitude <= radius then
			table.insert(list, p)
		end
	end
	return list
end

SlapRemote.OnServerEvent:Connect(function(attacker, target)
	local data = DataService.Get(attacker)
	local glove = data and (Config.GloveById[data.Glove] or Config.Gloves[1])
	local aRoot = rootOf(attacker)
	if not data or not glove or not aRoot or not inArena(attacker) then
		return
	end
	if not (attacker.Character and attacker.Character:FindFirstChild("Glove")) then
		return
	end
	local now = os.clock()
	if now - (lastSlap[attacker] or 0) < glove.Cooldown - 0.05 then
		return
	end
	local victims = {}
	if glove.Kind == "aoe" then
		victims = nearby(attacker, aRoot.Position, Config.SlapRange + 3)
	elseif typeof(target) == "Instance" and target:IsA("Player") and target ~= attacker and inArena(target) then
		local vRoot = rootOf(target)
		if vRoot and (vRoot.Position - aRoot.Position).Magnitude <= Config.SlapRange then
			victims = { target }
			if glove.Kind == "explode" then
				for _, p in nearby(attacker, vRoot.Position, 10) do
					if p ~= target then
						table.insert(victims, p)
					end
				end
				local boom = Instance.new("Explosion")
				boom.Position = vRoot.Position
				boom.BlastPressure = 0
				boom.DestroyJointRadiusPercent = 0
				boom.Parent = workspace
			end
		end
	end
	if #victims == 0 then
		return
	end
	lastSlap[attacker] = now
	local hits = 0
	for _, v in victims do
		if knock(v, aRoot.Position, glove.Power, attacker) then
			hits += 1
		end
	end
	if hits > 0 then
		data.SlapsGiven += hits
		addSlaps(attacker, Config.SlapReward * hits)
	end
end)

AbilityRemote.OnServerEvent:Connect(function(player)
	local data = DataService.Get(player)
	local glove = data and Config.GloveById[data.Glove]
	if not glove or not glove.Ability or not inArena(player) then
		return
	end
	local now = os.clock()
	if now - (lastAbility[player] or 0) < glove.Ability then
		return
	end
	lastAbility[player] = now
	local root = rootOf(player)
	if root and glove.Kind == "dash" then
		KnockbackRemote:FireClient(player, root.CFrame.LookVector * 110 + Vector3.new(0, 15, 0))
	end
end)

BuyGloveRemote.OnServerInvoke = function(player, id)
	local data = DataService.Get(player)
	local glove = type(id) == "string" and Config.GloveById[id]
	if not data or not glove then
		return false, "Invalid"
	end
	if not owns(player, glove) then
		if glove.Pass then
			return false, "Pass:" .. glove.Pass
		end
		if data.Slaps < glove.Cost then
			return false, "Need " .. glove.Cost .. " slaps!"
		end
		data.Slaps -= glove.Cost
		data.Owned[glove.Id] = true
	end
	data.Glove = glove.Id
	giveGlove(player)
	sync(player)
	return true, "Equipped " .. glove.Name .. "!"
end

-- Portal: touch to drop onto the island.
local portalBusy: { [Player]: boolean } = {}
portal.Touched:Connect(function(hit)
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if player and not portalBusy[player] then
		portalBusy[player] = true
		local a = math.random() * math.pi * 2
		character:PivotTo(CFrame.new(ISLAND + Vector3.new(math.cos(a) * 25, 6, math.sin(a) * 25)))
		task.wait(1)
		portalBusy[player] = nil
	end
end)

-- Void kills + kill credit
task.spawn(function()
	while true do
		task.wait(0.25)
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root and root.Position.Y < Config.VoidHeight then
				local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
				humanoid.Health = 0
				local hit = lastHitBy[player]
				lastHitBy[player] = nil
				if hit and hit.by.Parent and os.clock() - hit.at <= Config.KillCreditSeconds then
					local data = DataService.Get(hit.by)
					if data then
						data.Kills += 1
						addSlaps(hit.by, Config.KillReward)
					end
					notify(nil, hit.by.DisplayName .. " slapped " .. player.DisplayName .. " into the void!", Color3.fromRGB(255, 120, 60))
				end
			end
		end
	end
end)

---------------------------------------------------------------- players + monetization

DataService.ProfileLoaded:Connect(function(player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in { "Slaps", "Kills" } do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = stats
	end
	stats.Parent = player
	if not Config.GloveById[data.Glove] then
		data.Glove = "default"
	end
	sync(player)
	player.CharacterAdded:Connect(function()
		task.wait()
		giveGlove(player)
	end)
	if player.Character then
		giveGlove(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastSlap[player] = nil
	lastAbility[player] = nil
	lastHitBy[player] = nil
	shieldUntil[player] = nil
	portalBusy[player] = nil
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		SlapsSmall = function(player, data)
			data.Slaps += 500
			sync(player)
			return true
		end,
		SlapsLarge = function(player, data)
			data.Slaps += 4000
			sync(player)
			return true
		end,
		Shield = function(player)
			shieldUntil[player] = math.max(shieldUntil[player] or 0, os.clock()) + 120
			player:SetAttribute("ShieldUntil", os.time() + 120)
			notify(player, "Anti-slap shield active for 2 minutes!", Color3.fromRGB(120, 200, 255))
			return true
		end,
	},
	OnPassOwned = function(player, name)
		local glove = if name == "SigmaGlove" then "sigma" elseif name == "BombGlove" then "bomb" else nil
		local data = DataService.Get(player)
		if glove and data then
			data.Glove = glove
			giveGlove(player)
		end
		sync(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("BrainrotSlap_v1", {
	Slaps = 0,
	Kills = 0,
	SlapsGiven = 0,
	Glove = "default",
	Owned = { default = true },
})
