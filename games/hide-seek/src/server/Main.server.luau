-- Brainrot Hide and Seek server: lobby -> hiders scatter -> seeker released -> tags -> rewards.
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
local NotifyRemote = Instance.new("RemoteEvent")
NotifyRemote.Name = "Notify"
NotifyRemote.Parent = remotes
local RadarRemote = Instance.new("RemoteEvent")
RadarRemote.Name = "Radar"
RadarRemote.Parent = remotes
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

-- Map: a messy backyard-town of crates, walls, sheds and hedges to hide behind.
part({ Name = "Ground", Size = Vector3.new(240, 2, 240), Position = Vector3.new(0, -1, 0), Color = Color3.fromRGB(100, 170, 90), Material = Enum.Material.Grass })
local LOBBY = Vector3.new(0, 120, 0)
part({ Name = "Lobby", Size = Vector3.new(50, 2, 50), Position = LOBBY - Vector3.new(0, 1, 0), Color = Color3.fromRGB(230, 230, 240) })
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = LOBBY + Vector3.new(0, 0.5, 0)
spawn.Neutral = true
spawn.Parent = world
local SEEKER_BOX = Vector3.new(0, 60, 150)
part({ Name = "SeekerBox", Size = Vector3.new(16, 1, 16), Position = SEEKER_BOX - Vector3.new(0, 1, 0), Color = Color3.fromRGB(40, 40, 40) })
local rng = Random.new(3)
local hideColors = { Color3.fromRGB(160, 110, 70), Color3.fromRGB(60, 120, 60), Color3.fromRGB(180, 180, 190), Color3.fromRGB(200, 90, 80) }
for _ = 1, 70 do
	local kind = rng:NextInteger(1, 4)
	local size = if kind == 1 then Vector3.new(5, 5, 5) elseif kind == 2 then Vector3.new(rng:NextInteger(10, 24), 7, 3) elseif kind == 3 then Vector3.new(14, 10, 12) else Vector3.new(3, 8, rng:NextInteger(10, 22))
	local pos = Vector3.new(rng:NextInteger(-110, 110), size.Y / 2, rng:NextInteger(-110, 110))
	if pos.Magnitude > 12 then
		part({ Name = "Cover", Size = size, Position = pos, Color = hideColors[kind], Material = if kind == 2 then Enum.Material.Grass else Enum.Material.Wood })
	end
end

local state = { Stage = "Lobby", Seeker = nil :: Player?, NextSeeker = nil :: Player? }

local function rootOf(p: Player): BasePart?
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil
	end
	return (p.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart?
end
local function sync(p: Player)
	local data = DataService.Get(p)
	if not data then
		return
	end
	p:SetAttribute("Coins", data.Coins)
	p:SetAttribute("Wins", data.Wins)
	local ls = p:FindFirstChild("leaderstats")
	if ls then
		(ls :: any).Wins.Value = data.Wins;
		(ls :: any).Coins.Value = data.Coins
	end
end
local function give(p: Player, coins: number, win: boolean)
	local data = DataService.Get(p)
	if data then
		local m = (if MonetizationService.OwnsPass(p, "DoubleCoins") then 2 else 1) * (if MonetizationService.OwnsPass(p, "VIP") then 1.5 else 1)
		data.Coins += math.floor(coins * m)
		if win then
			data.Wins += 1
		end
		sync(p)
	end
end
local function setSpeed(p: Player, base: number)
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = base * (if MonetizationService.OwnsPass(p, "Speed") then 1.15 else 1)
	end
end
local function toLobby(p: Player)
	if p.Character then
		p.Character:PivotTo(CFrame.new(LOBBY + Vector3.new(math.random(-10, 10), 4, math.random(-10, 10))))
	end
end
local function hiders(): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("Role") == "Hider" and rootOf(p) then
			table.insert(list, p)
		end
	end
	return list
end
local function costume(p: Player, on: boolean)
	local character = p.Character
	if not character then
		return
	end
	local old = character:FindFirstChild("SeekerCostume")
	if old then
		old:Destroy()
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if on and root then
		local m, mroot = BrainrotModels.Build("tung", { Scale = 0.9, Anchored = false })
		m.Name = "SeekerCostume"
		mroot.CFrame = root.CFrame * CFrame.new(0, 2, 0)
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = mroot
		w.Parent = mroot
		m.Parent = character
	end
end

local function pickSeeker(players: { Player }): Player
	if state.NextSeeker and table.find(players, state.NextSeeker) then
		return state.NextSeeker
	end
	local tickets = {}
	for _, p in players do
		for _ = 1, if MonetizationService.OwnsPass(p, "SeekerChance") then 3 else 1 do
			table.insert(tickets, p)
		end
	end
	return tickets[math.random(1, #tickets)]
end

task.spawn(function()
	while true do
		state.Stage = "Lobby"
		workspace:SetAttribute("Stage", "Lobby")
		for t = Config.Intermission, 1, -1 do
			workspace:SetAttribute("TimeLeft", t)
			task.wait(1)
		end
		local players = {}
		for _, p in Players:GetPlayers() do
			if DataService.Get(p) and rootOf(p) then
				table.insert(players, p)
			end
		end
		if #players == 0 then
			continue
		end
		local seeker = pickSeeker(players)
		state.Seeker = seeker
		state.NextSeeker = nil
		workspace:SetAttribute("Seeker", seeker.DisplayName)
		for _, p in players do
			p:SetAttribute("Role", if p == seeker then "Seeker" else "Hider")
			if p == seeker then
				(p.Character :: Model):PivotTo(CFrame.new(SEEKER_BOX + Vector3.new(0, 3, 0)))
				costume(p, true)
			else
				(p.Character :: Model):PivotTo(CFrame.new(math.random(-20, 20), 4, math.random(-20, 20)))
				setSpeed(p, 17)
			end
		end
		notify(nil, seeker.DisplayName .. " is the SEEKER! Hide!", Color3.fromRGB(255, 120, 60))
		state.Stage = "Hide"
		workspace:SetAttribute("Stage", "Hide")
		for t = Config.HideTime, 1, -1 do
			workspace:SetAttribute("TimeLeft", t)
			task.wait(1)
		end
		state.Stage = "Seek"
		workspace:SetAttribute("Stage", "Seek")
		if seeker.Character then
			seeker.Character:PivotTo(CFrame.new(0, 4, 0))
			setSpeed(seeker, 19)
		end
		notify(nil, "Ready or not, here comes Sahur!", Color3.fromRGB(255, 80, 80))
		local ends = os.clock() + Config.SeekTime
		while os.clock() < ends and #hiders() > 0 and seeker.Parent and rootOf(seeker) do
			task.wait(0.2)
			workspace:SetAttribute("TimeLeft", math.ceil(ends - os.clock()))
			workspace:SetAttribute("HidersLeft", #hiders())
			local sroot = rootOf(seeker) :: BasePart
			for _, h in hiders() do
				local hroot = rootOf(h) :: BasePart
				if (hroot.Position - sroot.Position).Magnitude <= Config.TagRange then
					h:SetAttribute("Role", "Found")
					give(seeker, Config.TagCoins, false)
					notify(nil, seeker.DisplayName .. " found " .. h.DisplayName .. "!", Color3.fromRGB(255, 160, 60))
					toLobby(h)
				end
			end
		end
		local left = hiders()
		if #left == 0 then
			give(seeker, Config.HiderWin, true)
			notify(nil, "The seeker found everyone!", Color3.fromRGB(255, 80, 80))
		else
			for _, h in left do
				give(h, Config.HiderWin, true)
			end
			notify(nil, #left .. " hider(s) survived!", Color3.fromRGB(90, 255, 90))
		end
		for _, p in Players:GetPlayers() do
			p:SetAttribute("Role", nil)
			costume(p, false)
			setSpeed(p, 16)
			toLobby(p)
		end
		state.Seeker = nil
		workspace:SetAttribute("Seeker", nil)
	end
end)

DataService.ProfileLoaded:Connect(function(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, n in { "Wins", "Coins" } do
		local v = Instance.new("IntValue")
		v.Name = n
		v.Parent = ls
	end
	ls.Parent = player
	sync(player)
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		BeSeeker = function(player)
			state.NextSeeker = player
			notify(player, "You'll be the seeker next round!", Color3.fromRGB(255, 120, 60))
			return true
		end,
		Radar = function(player, data)
			if state.Seeker == player and state.Stage == "Seek" then
				local spots = {}
				for _, h in hiders() do
					table.insert(spots, (rootOf(h) :: BasePart).Position)
				end
				RadarRemote:FireClient(player, spots)
			else
				data.Coins += 100
				sync(player)
				notify(player, "Radar only works as the seeker. Here's 100 coins!", Color3.fromRGB(255, 215, 0))
			end
			return true
		end,
		Coins = function(player, data)
			data.Coins += 1000
			sync(player)
			return true
		end,
	},
	OnPassOwned = function(player, name)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("BrainrotHideAndSeek_v1", { Coins = 0, Wins = 0 })
