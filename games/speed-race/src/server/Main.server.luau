-- +1 Speed Brainrot Race server: speed grows every second, finish lines along a huge track give wins,
-- wins buy trails and rebirths that make speed grow faster.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotModels = require(ReplicatedStorage.Common.BrainrotModels)
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
local ReturnRemote = remote("RemoteEvent", "Return")
local RebirthRemote = remote("RemoteFunction", "Rebirth")
local BuyTrailRemote = remote("RemoteFunction", "BuyTrail")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

---------------------------------------------------------------- map

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

local TRACK_W = 48
local START = CFrame.new(0, 4, -30)

-- Start area
part({ Name = "StartArea", Size = Vector3.new(90, 2, 70), Position = Vector3.new(0, -1, -35), Color = Color3.fromRGB(60, 60, 75), Material = Enum.Material.SmoothPlastic })
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(14, 1, 14)
spawn.Position = Vector3.new(0, 0.5, -30)
spawn.Neutral = true
spawn.Color = Color3.fromRGB(255, 200, 0)
spawn.Material = Enum.Material.Neon
spawn.Parent = world
part({ Name = "StartLine", Size = Vector3.new(TRACK_W, 0.2, 3), Position = Vector3.new(0, 0.1, 0), Color = Color3.new(1, 1, 1), Material = Enum.Material.Neon })
local startSign = part({ Name = "StartSign", Size = Vector3.new(TRACK_W + 6, 8, 1), Position = Vector3.new(0, 22, 0), Color = Color3.fromRGB(30, 30, 40) })
do
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(800, 120)
	gui.Parent = startSign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "+1 SPEED EVERY SECOND — RUN!"
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.fromRGB(255, 215, 0)
	label.Parent = gui
end
for _, sx in { -1, 1 } do
	part({ Size = Vector3.new(2, 22, 2), Position = Vector3.new(sx * (TRACK_W / 2 + 2), 11, 0), Color = Color3.fromRGB(30, 30, 40) })
end

-- The track: segments coloured by the zone they lead into, with rails so nobody falls off.
local SEG = 1000
local trackEnd = Config.Zones[#Config.Zones].Dist + 120
local function zoneColorAt(z: number): Color3
	for _, zone in Config.Zones do
		if z < zone.Dist then
			return zone.Color
		end
	end
	return Config.Zones[#Config.Zones].Color
end
local z0 = 0
local zoneStart = 0
for _, zone in Config.Zones do
	local zoneEnd = math.min(zone.Dist, trackEnd)
	z0 = zoneStart
	while z0 < zoneEnd do
		local len = math.min(SEG, zoneEnd - z0)
		part({ Name = "Track", Size = Vector3.new(TRACK_W, 2, len), Position = Vector3.new(0, -1, z0 + len / 2), Color = zoneColorAt(z0 + 1), Material = Enum.Material.SmoothPlastic })
		for _, sx in { -1, 1 } do
			part({ Name = "Rail", Size = Vector3.new(2, 8, len), Position = Vector3.new(sx * (TRACK_W / 2 + 1), 3, z0 + len / 2), Color = Color3.fromRGB(255, 255, 255), Transparency = 0.6 })
		end
		-- Distance markers every 100 studs so speed feels fast.
		for m = math.ceil(z0 / 100) * 100, z0 + len - 1, 100 do
			if m > 0 then
				part({ Name = "Marker", Size = Vector3.new(TRACK_W, 0.15, 1), Position = Vector3.new(0, 0.08, m), Color = zone.Color:Lerp(Color3.new(1, 1, 1), 0.6) })
			end
		end
		z0 += len
	end
	zoneStart = zoneEnd
end
part({ Name = "TrackEnd", Size = Vector3.new(TRACK_W, 2, trackEnd - zoneStart), Position = Vector3.new(0, -1, (zoneStart + trackEnd) / 2), Color = Config.Zones[#Config.Zones].Color })
part({ Name = "EndWall", Size = Vector3.new(TRACK_W + 4, 30, 4), Position = Vector3.new(0, 15, trackEnd + 2), Color = Color3.fromRGB(20, 20, 30) })

---------------------------------------------------------------- state

local claimed: { [Player]: { [number]: boolean } } = {}
local boostUntil = 0
local lastBooster = ""

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Speed", data.Speed)
	player:SetAttribute("Wins", data.Wins)
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("Trail", data.Trail)
	player:SetAttribute("BestZone", data.BestZone)
	player:SetAttribute("OwnedTrails", table.concat(data.Trails, ","))
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		(ls :: any).Speed.Value = data.Speed;
		(ls :: any).Wins.Value = data.Wins;
		(ls :: any).Rebirths.Value = data.Rebirths
	end
end

local function trailInfo(id: string?)
	for _, t in Config.Trails do
		if t.Id == id then
			return t
		end
	end
	return nil
end

local function speedGain(player: Player): number
	local data = DataService.Get(player)
	if not data then
		return 0
	end
	local m = 1 + data.Rebirths * Config.RebirthBoost
	local trail = trailInfo(data.Trail)
	if trail then
		m += trail.Boost
	end
	if MonetizationService.OwnsPass(player, "DoubleSpeed") then
		m *= 2
	end
	if MonetizationService.OwnsPass(player, "SuperLegs") then
		m *= 3
	end
	if MonetizationService.OwnsPass(player, "VIP") then
		m *= 1.5
	end
	if os.clock() < boostUntil then
		m *= 3
	end
	return math.max(1, math.floor(m))
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function applySpeed(player: Player)
	local data = DataService.Get(player)
	local humanoid = humanoidOf(player)
	if data and humanoid then
		humanoid.WalkSpeed = math.min(16 + data.Speed * Config.WalkPerSpeed, Config.MaxWalkSpeed)
		humanoid.JumpPower = math.min(50 + data.Speed * 0.02, 120)
	end
end

local function applyTrail(player: Player)
	local data = DataService.Get(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not data or not root then
		return
	end
	local old = root:FindFirstChild("SpeedTrail")
	if old then
		old:Destroy()
	end
	local info = trailInfo(data.Trail)
	local vip = MonetizationService.OwnsPass(player, "VIP")
	if not info and not vip then
		return
	end
	local a0 = root:FindFirstChild("TrailTop") or Instance.new("Attachment")
	a0.Name = "TrailTop";
	(a0 :: Attachment).Position = Vector3.new(0, 1, 0)
	a0.Parent = root
	local a1 = root:FindFirstChild("TrailBottom") or Instance.new("Attachment")
	a1.Name = "TrailBottom";
	(a1 :: Attachment).Position = Vector3.new(0, -1, 0)
	a1.Parent = root
	local t = Instance.new("Trail")
	t.Name = "SpeedTrail"
	t.Attachment0 = a0 :: Attachment
	t.Attachment1 = a1 :: Attachment
	if info then
		t.Color = ColorSequence.new(info.Color)
	else
		t.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 255, 120)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 120, 255)),
		})
	end
	t.LightEmission = 0.8
	t.Lifetime = 0.5
	t.WidthScale = NumberSequence.new(1, 0.2)
	t.Parent = root
end

local function sendToStart(player: Player)
	claimed[player] = {}
	local character = player.Character
	if character then
		character:PivotTo(START + Vector3.new(math.random(-10, 10), 0, 0))
	end
end

---------------------------------------------------------------- finish lines

local function claimZone(player: Player, i: number)
	local data = DataService.Get(player)
	local runClaims = claimed[player]
	if not data or not runClaims or runClaims[i] then
		return
	end
	runClaims[i] = true
	local zone = Config.Zones[i]
	local m = 1
	if MonetizationService.OwnsPass(player, "DoubleWins") then
		m *= 2
	end
	local wins = zone.Wins * m * (1 + data.Rebirths)
	data.Wins += wins
	if i > data.BestZone then
		data.BestZone = i
		notify(nil, player.DisplayName .. " reached " .. zone.Name .. "!", zone.Color)
	end
	sync(player)
	notify(player, "+" .. wins .. " wins! (" .. zone.Name .. ")", Color3.fromRGB(255, 215, 0))
	if i == #Config.Zones then
		notify(nil, player.DisplayName .. " BEAT THE WHOLE TRACK!", Color3.fromRGB(255, 80, 255))
		task.delay(1, sendToStart, player)
	end
end

for i, zone in Config.Zones do
	local line = part({
		Name = "Finish" .. i,
		Size = Vector3.new(TRACK_W, 14, 3),
		Position = Vector3.new(0, 7, zone.Dist),
		Color = zone.Color,
		Material = Enum.Material.ForceField,
		Transparency = 0.3,
		CanCollide = false,
	})
	line.Touched:Connect(function(hit)
		local model = hit:FindFirstAncestorOfClass("Model")
		local player = model and Players:GetPlayerFromCharacter(model)
		if player then
			claimZone(player, i)
		end
	end)
	-- Arch + sign
	for _, sx in { -1, 1 } do
		part({ Size = Vector3.new(3, 26, 3), Position = Vector3.new(sx * (TRACK_W / 2 + 2), 13, zone.Dist), Color = zone.Color, Material = Enum.Material.Neon })
	end
	local sign = part({ Name = "Sign", Size = Vector3.new(TRACK_W + 7, 7, 1), Position = Vector3.new(0, 26, zone.Dist), Color = Color3.fromRGB(25, 25, 35) })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(900, 120)
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = zone.Name:upper() .. "  •  +" .. zone.Wins .. " WINS"
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = zone.Color:Lerp(Color3.new(1, 1, 1), 0.4)
	label.Parent = gui
	-- Giant brainrot guardians on both sides of each finish line.
	if BrainrotModels.Has(zone.Boss) then
		for _, sx in { -1, 1 } do
			local statue, _ = BrainrotModels.Build(zone.Boss, { Scale = 2.2 + i * 0.25 })
			local h = (statue:GetAttribute("RootHeight") :: number?) or 4
			statue:PivotTo(CFrame.new(sx * (TRACK_W / 2 + 18), h, zone.Dist - 6) * CFrame.Angles(0, math.rad(sx * 25), 0))
			statue.Parent = world
		end
	end
	-- Ground either side so the statues stand on something.
	part({ Size = Vector3.new(30, 2, 40), Position = Vector3.new(-(TRACK_W / 2 + 18), -1, zone.Dist - 6), Color = zone.Color:Lerp(Color3.new(0, 0, 0), 0.2) })
	part({ Size = Vector3.new(30, 2, 40), Position = Vector3.new(TRACK_W / 2 + 18, -1, zone.Dist - 6), Color = zone.Color:Lerp(Color3.new(0, 0, 0), 0.2) })
end

-- Touching the start area resets your run so finish lines pay out again.
local startPad = part({ Name = "RunReset", Size = Vector3.new(TRACK_W, 6, 20), Position = Vector3.new(0, 3, -12), Transparency = 1, CanCollide = false })
startPad.Touched:Connect(function(hit)
	local model = hit:FindFirstAncestorOfClass("Model")
	local player = model and Players:GetPlayerFromCharacter(model)
	if player and claimed[player] and next(claimed[player]) ~= nil then
		claimed[player] = {}
	end
end)

---------------------------------------------------------------- speed tick

task.spawn(function()
	while true do
		task.wait(1)
		workspace:SetAttribute("BoostLeft", math.max(0, math.ceil(boostUntil - os.clock())))
		workspace:SetAttribute("Booster", if os.clock() < boostUntil then lastBooster else nil)
		for _, player in Players:GetPlayers() do
			local data = DataService.Get(player)
			if data and humanoidOf(player) then
				data.Speed += speedGain(player)
				sync(player)
				applySpeed(player)
			end
		end
	end
end)

---------------------------------------------------------------- remotes

ReturnRemote.OnServerEvent:Connect(function(player)
	sendToStart(player)
end)

RebirthRemote.OnServerInvoke = function(player)
	local data = DataService.Get(player)
	if not data then
		return false
	end
	local cost = Config.RebirthCost(data.Rebirths)
	if data.Wins < cost then
		notify(player, "You need " .. cost .. " wins to rebirth!", Color3.fromRGB(255, 90, 90))
		return false
	end
	data.Wins -= cost
	data.Rebirths += 1
	data.Speed = 0
	sync(player)
	applySpeed(player)
	sendToStart(player)
	notify(nil, player.DisplayName .. " REBIRTHED! (x" .. data.Rebirths .. ")", Color3.fromRGB(255, 120, 255))
	return true
end

BuyTrailRemote.OnServerInvoke = function(player, id)
	local data = DataService.Get(player)
	local info = trailInfo(id)
	if not data or not info then
		return false
	end
	if table.find(data.Trails, info.Id) then
		data.Trail = info.Id
	elseif data.Wins >= info.Cost then
		data.Wins -= info.Cost
		table.insert(data.Trails, info.Id)
		data.Trail = info.Id
		notify(player, "Bought " .. info.Name .. "! +" .. info.Boost .. "x speed gain", info.Color)
	else
		notify(player, "You need " .. info.Cost .. " wins!", Color3.fromRGB(255, 90, 90))
		return false
	end
	sync(player)
	applyTrail(player)
	return true
end

---------------------------------------------------------------- players + monetization

DataService.ProfileLoaded:Connect(function(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, name in { "Speed", "Wins", "Rebirths" } do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = ls
	end
	ls.Parent = player
	claimed[player] = {}
	sync(player)
	local function onCharacter(character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		claimed[player] = {}
		applySpeed(player)
		applyTrail(player)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	claimed[player] = nil
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		Speed1K = function(player, data)
			data.Speed += 1000
			sync(player)
			applySpeed(player)
			return true
		end,
		Speed25K = function(player, data)
			data.Speed += 25000
			sync(player)
			applySpeed(player)
			notify(nil, player.DisplayName .. " bought +25,000 SPEED!", Color3.fromRGB(255, 215, 0))
			return true
		end,
		SkipZone = function(player, data)
			local runClaims = claimed[player] or {}
			for i, zone in Config.Zones do
				if not runClaims[i] then
					local character = player.Character
					if character then
						character:PivotTo(CFrame.new(0, 4, zone.Dist - 8))
					end
					return true
				end
			end
			data.Speed += 500
			sync(player)
			notify(player, "You already cleared every zone this run, so you got +500 speed!", Color3.fromRGB(255, 215, 0))
			return true
		end,
		ServerBoost = function(player)
			boostUntil = math.max(boostUntil, os.clock()) + Config.ServerBoostTime
			lastBooster = player.DisplayName
			notify(nil, player.DisplayName .. " activated 3x SPEED for the whole server!", Color3.fromRGB(255, 80, 255))
			return true
		end,
	},
	OnPassOwned = function(player, name)
		applyTrail(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("SpeedBrainrotRace_v1", {
	Speed = 0,
	Wins = 0,
	Rebirths = 0,
	BestZone = 0,
	Trail = "",
	Trails = {},
})
