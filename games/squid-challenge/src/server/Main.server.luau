-- Squid Challenge server: lobby -> Red Light Green Light -> Glass Bridge -> winners.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)

Lighting.ClockTime = 14
Lighting.Brightness = 2.5

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local NotifyRemote = Instance.new("RemoteEvent")
NotifyRemote.Name = "Notify"
NotifyRemote.Parent = remotes

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

-- Lobby
part({ Name = "Lobby", Size = Vector3.new(60, 2, 60), Position = Vector3.new(0, -1, -120), Color = Color3.fromRGB(80, 200, 160), Material = Enum.Material.SmoothPlastic })
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = Vector3.new(0, 0.5, -120)
spawn.Neutral = true
spawn.Color = Color3.fromRGB(255, 80, 140)
spawn.Parent = world

-- Stage 1: field, start line at z = 0, finish at z = 160, the doll at the far end.
part({ Name = "Field", Size = Vector3.new(80, 2, 180), Position = Vector3.new(0, -1, 80), Color = Color3.fromRGB(230, 200, 140), Material = Enum.Material.Sand })
part({ Name = "StartLine", Size = Vector3.new(80, 0.2, 2), Position = Vector3.new(0, 0.1, 5), Color = Color3.new(1, 1, 1) })
part({ Name = "FinishLine", Size = Vector3.new(80, 0.2, 2), Position = Vector3.new(0, 0.1, 160), Color = Color3.fromRGB(255, 60, 60), Material = Enum.Material.Neon })
for _, sx in { -1, 1 } do
	part({ Size = Vector3.new(2, 20, 180), Position = Vector3.new(sx * 41, 10, 80), Color = Color3.fromRGB(255, 120, 170) })
end
local doll = Instance.new("Model")
doll.Name = "Doll"
local dollBody = part({ Name = "Body", Size = Vector3.new(6, 10, 4), Position = Vector3.new(0, 5, 172), Color = Color3.fromRGB(255, 150, 40) }, doll)
local dollHead = part({ Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.one * 5, Position = Vector3.new(0, 12.5, 172), Color = Color3.fromRGB(255, 220, 180) }, doll)
local dollFace = part({ Name = "Face", Size = Vector3.new(3, 1, 0.2), Position = Vector3.new(0, 12.8, 169.6), Color = Color3.fromRGB(30, 30, 30) }, doll)
part({ Size = Vector3.new(5.4, 2, 5.4), Position = Vector3.new(0, 14.2, 172.3), Color = Color3.fromRGB(40, 25, 15) }, doll)
doll.PrimaryPart = dollBody
doll.Parent = world

-- Stage 2: glass bridge from z = 200 to z = 200 + steps*8, high above a pit.
local BRIDGE_Y = 30
part({ Name = "BridgeStart", Size = Vector3.new(30, 2, 16), Position = Vector3.new(0, BRIDGE_Y - 1, 196), Color = Color3.fromRGB(90, 90, 110) })
local bridgeEndZ = 200 + Config.BridgeSteps * 8 + 8
part({ Name = "BridgeEnd", Size = Vector3.new(30, 2, 16), Position = Vector3.new(0, BRIDGE_Y - 1, bridgeEndZ), Color = Color3.fromRGB(90, 200, 90) })
local glassFolder = Instance.new("Folder")
glassFolder.Name = "Glass"
glassFolder.Parent = workspace

---------------------------------------------------------------- state

local state = { Stage = "Lobby", Green = true }
local lastPos: { [Player]: Vector3 } = {}
local finished: { [Player]: boolean } = {}

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
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

local function eliminate(player: Player, reason: string)
	if not player:GetAttribute("InRound") then
		return
	end
	player:SetAttribute("InRound", false)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
	notify(nil, player.DisplayName .. " " .. reason, Color3.fromRGB(255, 90, 90))
	notify(player, "Eliminated! Buy a Revive to jump back in!", Color3.fromRGB(255, 200, 0))
end

local function applySpeed(player: Player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = if MonetizationService.OwnsPass(player, "Speed") then 19 else 16
	end
end

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("Wins", data.Wins)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Wins.Value = data.Wins
		ls.Coins.Value = data.Coins
	end
end

local function stageStart(stage: string): CFrame
	if stage == "Bridge" then
		return CFrame.new(math.random(-8, 8), BRIDGE_Y + 3, 194)
	end
	return CFrame.new(math.random(-30, 30), 4, math.random(-4, 2))
end

---------------------------------------------------------------- glass bridge

local safeSide: { number } = {}
local function buildBridge()
	glassFolder:ClearAllChildren()
	table.clear(safeSide)
	for i = 1, Config.BridgeSteps do
		safeSide[i] = if math.random() < 0.5 then -1 else 1
		for _, side in { -1, 1 } do
			local glass = part({
				Name = "Glass",
				Size = Vector3.new(6, 0.6, 6),
				Position = Vector3.new(side * 5, BRIDGE_Y, 200 + i * 8),
				Color = Color3.fromRGB(180, 230, 255),
				Material = Enum.Material.Glass,
				Transparency = 0.35,
			}, glassFolder)
			glass:SetAttribute("Safe", side == safeSide[i])
			glass:SetAttribute("Step", i)
			if side ~= safeSide[i] then
				glass.Touched:Connect(function(hit)
					local model = hit:FindFirstAncestorOfClass("Model")
					if model and Players:GetPlayerFromCharacter(model) and glass.Parent then
						glass.Transparency = 1
						glass.CanCollide = false
						glass.Parent = nil
					end
				end)
			end
		end
	end
end

---------------------------------------------------------------- round loop

local function runRLGL(duration: number)
	state.Stage = "RLGL"
	workspace:SetAttribute("Stage", "Red Light, Green Light")
	local ends = os.clock() + duration
	local nextSwitch = os.clock() + math.random(3, 5)
	state.Green = true
	workspace:SetAttribute("Light", "Green")
	dollHead.CFrame = CFrame.new(dollHead.Position) * CFrame.Angles(0, math.pi, 0)
	while os.clock() < ends and #inRound() > 0 do
		workspace:SetAttribute("TimeLeft", math.ceil(ends - os.clock()))
		local now = os.clock()
		if now >= nextSwitch then
			state.Green = not state.Green
			workspace:SetAttribute("Light", if state.Green then "Green" else "Red")
			dollFace.Transparency = if state.Green then 1 else 0
			nextSwitch = now + (if state.Green then math.random(25, 50) / 10 else math.random(20, 35) / 10)
			for _, p in inRound() do
				lastPos[p] = (rootOf(p) :: BasePart).Position
			end
			if not state.Green then
				task.wait(0.4) -- grace period to stop
				for _, p in inRound() do
					lastPos[p] = (rootOf(p) :: BasePart).Position
				end
			end
		end
		for _, p in inRound() do
			local root = rootOf(p) :: BasePart
			if root.Position.Z >= 160 then
				if not finished[p] then
					finished[p] = true
					notify(p, "You crossed the line! Wait for the next stage.", Color3.fromRGB(90, 255, 90))
				end
			elseif not state.Green and not finished[p] then
				local before = lastPos[p]
				if before and (root.Position - before).Magnitude > Config.MoveTolerance then
					eliminate(p, "moved on red light!")
				end
			end
		end
		task.wait(0.15)
	end
	-- Anyone who didn't cross is out.
	for _, p in inRound() do
		if not finished[p] then
			eliminate(p, "ran out of time!")
		end
	end
end

local function runBridge(duration: number)
	state.Stage = "Bridge"
	workspace:SetAttribute("Stage", "Glass Bridge")
	workspace:SetAttribute("Light", nil)
	buildBridge()
	table.clear(finished)
	for _, p in inRound() do
		p.Character:PivotTo(stageStart("Bridge"))
	end
	local ends = os.clock() + duration
	while os.clock() < ends and #inRound() > 0 do
		workspace:SetAttribute("TimeLeft", math.ceil(ends - os.clock()))
		for _, p in inRound() do
			local root = rootOf(p) :: BasePart
			if root.Position.Y < BRIDGE_Y - 15 then
				eliminate(p, "picked the wrong glass!")
			elseif root.Position.Z >= bridgeEndZ - 6 and root.Position.Y > BRIDGE_Y - 2 then
				finished[p] = true
			end
		end
		local everyoneDone = true
		for _, p in inRound() do
			if not finished[p] then
				everyoneDone = false
			end
		end
		if everyoneDone then
			break
		end
		task.wait(0.2)
	end
	for _, p in inRound() do
		if not finished[p] then
			eliminate(p, "didn't cross the bridge in time!")
		end
	end
end

task.spawn(function()
	while true do
		state.Stage = "Lobby"
		workspace:SetAttribute("Stage", "Lobby")
		workspace:SetAttribute("Light", nil)
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
		table.clear(finished)
		table.clear(lastPos)
		for _, p in players do
			p:SetAttribute("InRound", true)
			p.Character:PivotTo(stageStart("RLGL"))
			applySpeed(p)
		end
		notify(nil, "ROUND STARTING: Red Light, Green Light!", Color3.fromRGB(255, 80, 140))
		task.wait(2)
		runRLGL(Config.RLGLTime)
		if #inRound() > 0 then
			notify(nil, "STAGE 2: The Glass Bridge! Pick the right panels...", Color3.fromRGB(120, 200, 255))
			task.wait(2)
			runBridge(Config.BridgeTime)
		end
		local winners = inRound()
		for _, p in winners do
			local data = DataService.Get(p)
			if data then
				local m = 1
				if MonetizationService.OwnsPass(p, "DoubleWins") then
					m *= 2
				end
				if MonetizationService.OwnsPass(p, "VIP") then
					m *= 1.5
				end
				data.Wins += 1
				data.Coins += math.floor(Config.WinCoins * m)
				sync(p)
			end
			notify(nil, p.DisplayName .. " SURVIVED THE CHALLENGE!", Color3.fromRGB(255, 215, 0))
			p:SetAttribute("InRound", false)
			p.Character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
		end
		if #winners == 0 then
			notify(nil, "Nobody survived this time!", Color3.fromRGB(255, 90, 90))
		end
		glassFolder:ClearAllChildren()
		task.wait(3)
	end
end)

---------------------------------------------------------------- players + monetization

DataService.ProfileLoaded:Connect(function(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, name in { "Wins", "Coins" } do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = ls
	end
	ls.Parent = player
	sync(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait()
		if player:GetAttribute("InRound") and state.Stage ~= "Lobby" then
			character:PivotTo(stageStart(state.Stage))
		end
		applySpeed(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	lastPos[player] = nil
	finished[player] = nil
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		Revive = function(player, data)
			if state.Stage ~= "Lobby" and not player:GetAttribute("InRound") then
				player:SetAttribute("InRound", true)
				lastPos[player] = nil
				player:LoadCharacter()
				notify(nil, player.DisplayName .. " REVIVED!", Color3.fromRGB(90, 255, 90))
			else
				data.Coins += 300
				sync(player)
				notify(player, "Nothing to revive right now, so you got 300 coins!", Color3.fromRGB(255, 215, 0))
			end
			return true
		end,
		SkipStage = function(player, data)
			if state.Stage == "RLGL" and player:GetAttribute("InRound") then
				finished[player] = true
				player.Character:PivotTo(CFrame.new(math.random(-20, 20), 4, 165))
			elseif state.Stage == "Bridge" and player:GetAttribute("InRound") then
				finished[player] = true
				player.Character:PivotTo(CFrame.new(0, BRIDGE_Y + 3, bridgeEndZ))
			else
				data.Coins += 500
				sync(player)
				notify(player, "No stage to skip right now, so you got 500 coins!", Color3.fromRGB(255, 215, 0))
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
		applySpeed(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("SquidChallenge_v1", {
	Coins = 0,
	Wins = 0,
})
