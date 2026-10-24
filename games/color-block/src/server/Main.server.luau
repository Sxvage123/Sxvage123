-- Brainrot Color Block server: lobby -> rounds of "stand on the called colour" -> last survivors win.
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
local PreviewRemote = Instance.new("RemoteEvent")
PreviewRemote.Name = "Preview"
PreviewRemote.Parent = remotes
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
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent or world
	return p
end

local N, T = Config.GridSize, Config.TileSize
local BOARD_Y = 40
local LOBBY = Vector3.new(0, 80, -120)
part({ Name = "Lobby", Size = Vector3.new(60, 2, 40), Position = LOBBY - Vector3.new(0, 1, 0), Color = Color3.fromRGB(240, 240, 250) })
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = LOBBY + Vector3.new(0, 0.5, 0)
spawn.Neutral = true
spawn.Parent = world
part({ Name = "Void", Size = Vector3.new(400, 1, 400), Position = Vector3.new(0, 0, 0), Color = Color3.fromRGB(20, 10, 30), Material = Enum.Material.Neon, Transparency = 0.3 })

local tiles: { BasePart } = {}
for x = 1, N do
	for z = 1, N do
		table.insert(tiles, part({ Name = "Tile", Size = Vector3.new(T - 0.2, 1, T - 0.2), Position = Vector3.new((x - (N + 1) / 2) * T, BOARD_Y, (z - (N + 1) / 2) * T), Material = Enum.Material.SmoothPlastic }))
	end
end
local caller = Instance.new("Folder")
caller.Name = "Caller"
caller.Parent = workspace

local state = { Stage = "Lobby", ExtraTime = 0 }

local function rootOf(p: Player): BasePart?
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil
	end
	return (p.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart?
end
local function inRound(): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("InRound") and rootOf(p) then
			table.insert(list, p)
		end
	end
	return list
end
local function mult(p: Player): number
	return (if MonetizationService.OwnsPass(p, "DoubleCoins") then 2 else 1) * (if MonetizationService.OwnsPass(p, "VIP") then 1.5 else 1)
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
local function give(p: Player, coins: number)
	local data = DataService.Get(p)
	if data then
		data.Coins += math.floor(coins * mult(p))
		sync(p)
	end
end
local function boardSpot(): CFrame
	return CFrame.new(math.random(-N * T / 2 + 5, N * T / 2 - 5), BOARD_Y + 4, math.random(-N * T / 2 + 5, N * T / 2 - 5))
end
local function paint()
	for _, t in tiles do
		local c = Config.Colors[math.random(1, #Config.Colors)]
		t.Color = c.Color
		t:SetAttribute("ColorName", c.Name)
		t.Transparency = 0
		t.CanCollide = true
	end
end

-- Elimination: anyone who falls below the board is out.
task.spawn(function()
	while true do
		task.wait(0.2)
		for _, p in Players:GetPlayers() do
			local root = rootOf(p)
			if p:GetAttribute("InRound") and root and root.Position.Y < BOARD_Y - 15 then
				p:SetAttribute("InRound", false)
				notify(nil, p.DisplayName .. " fell!", Color3.fromRGB(255, 90, 90))
				p.Character:PivotTo(CFrame.new(LOBBY + Vector3.new(0, 4, 0)))
			end
		end
	end
end)

task.spawn(function()
	while true do
		state.Stage = "Lobby"
		workspace:SetAttribute("Stage", "Lobby")
		workspace:SetAttribute("Called", nil)
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
		paint()
		state.Stage = "Round"
		state.ExtraTime = 0
		workspace:SetAttribute("Stage", "Round")
		for _, p in players do
			p:SetAttribute("InRound", true)
			p.Character:PivotTo(boardSpot())
		end
		task.wait(3)
		local time = Config.StartTime
		local turn = 0
		while #inRound() > 0 and turn < 40 do
			turn += 1
			local c = Config.Colors[math.random(1, #Config.Colors)]
			for _, p in inRound() do
				if MonetizationService.OwnsPass(p, "ColorSense") then
					PreviewRemote:FireClient(p, c.Name)
				end
			end
			task.wait(1)
			workspace:SetAttribute("Called", c.Name)
			caller:ClearAllChildren()
			if BrainrotModels.Has(c.Brainrot) then
				local m, _ = BrainrotModels.Build(c.Brainrot, { Scale = 3, Tint = c.Color })
				m:PivotTo(CFrame.new(0, BOARD_Y + 30 + ((m:GetAttribute("RootHeight") :: number?) or 6), N * T / 2 + 20) * CFrame.Angles(0, math.pi, 0))
				m.Parent = caller
			end
			local wait = time + state.ExtraTime
			for t = math.ceil(wait), 1, -1 do
				workspace:SetAttribute("TimeLeft", t)
				task.wait(wait / math.ceil(wait))
			end
			for _, tile in tiles do
				if tile:GetAttribute("ColorName") ~= c.Name then
					tile.Transparency = 0.9
					tile.CanCollide = false
				end
			end
			task.wait(2.5)
			for _, p in inRound() do
				give(p, Config.CoinsPerTurn)
			end
			if #inRound() <= 1 and #players > 1 then
				break
			end
			paint()
			time = math.max(Config.MinTime, time - Config.Shrink)
		end
		local winners = inRound()
		for _, p in winners do
			local data = DataService.Get(p)
			if data then
				data.Wins += 1
				sync(p)
			end
			give(p, Config.WinCoins)
			notify(nil, p.DisplayName .. " WINS COLOR BLOCK!", Color3.fromRGB(255, 215, 0))
			p:SetAttribute("InRound", false)
			p.Character:PivotTo(CFrame.new(LOBBY + Vector3.new(0, 4, 0)))
		end
		for _, p in Players:GetPlayers() do
			p:SetAttribute("InRound", false)
		end
		caller:ClearAllChildren()
		paint()
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
	local function onCharacter(character: Model)
		local hum = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if hum then
			hum.WalkSpeed = if MonetizationService.OwnsPass(player, "Speed") then 19 else 16
		end
		if player:GetAttribute("InRound") then
			task.wait()
			character:PivotTo(boardSpot())
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		Revive = function(player, data)
			if state.Stage == "Round" and not player:GetAttribute("InRound") and player.Character then
				player:SetAttribute("InRound", true)
				player.Character:PivotTo(boardSpot())
				notify(nil, player.DisplayName .. " REVIVED!", Color3.fromRGB(90, 255, 90))
			else
				data.Coins += 300
				sync(player)
			end
			return true
		end,
		Coins = function(player, data)
			data.Coins += 1000
			sync(player)
			return true
		end,
		ExtraTime = function(player)
			state.ExtraTime += 2
			notify(nil, player.DisplayName .. " slowed the game down! +2s to find the colour", Color3.fromRGB(120, 200, 255))
			return true
		end,
	},
	OnPassOwned = function(player, name)
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and name == "Speed" then
			hum.WalkSpeed = 19
		end
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("BrainrotColorBlock_v1", { Coins = 0, Wins = 0 })
