-- Survive Tung Tung Sahur server: intermission -> round -> rewards loop.
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)
local Arena = require(script.Parent.Arena)

Lighting.ClockTime = 0
Lighting.Brightness = 1
Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 110)
Lighting.FogEnd = 260
Lighting.FogColor = Color3.fromRGB(20, 20, 40)

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
local BuyItemRemote = remote("RemoteFunction", "BuyItem")
local UsePotionRemote = remote("RemoteFunction", "UsePotion")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

local spawnPoints = Arena.Build()
local sahurFolder = Instance.new("Folder")
sahurFolder.Name = "Sahurs"
sahurFolder.Parent = workspace

local roundActive = false
local roundStart = 0
local slowUntil = 0
local queuedSahurs = 0
local sahurs = {}
local potionUntil: { [Player]: number } = {}

---------------------------------------------------------------- helpers

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("Wins", data.Wins)
	player:SetAttribute("Shields", data.Shields)
	player:SetAttribute("Potions", data.Potions)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Wins.Value = data.Wins
		stats.Coins.Value = data.Coins
	end
end

local function coinMultiplier(player: Player): number
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

local function applySpeed(player: Player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local speed = Config.PlayerSpeed
	if MonetizationService.OwnsPass(player, "Speed") then
		speed *= 1.2
	end
	if (potionUntil[player] or 0) > os.clock() then
		speed *= 1.3
	end
	humanoid.WalkSpeed = speed
end

local function randomArenaSpawn(): CFrame
	return CFrame.new(spawnPoints[math.random(1, #spawnPoints)])
end

local function alivePlayers(): { Player }
	local list = {}
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("Alive") and rootOf(player) then
			table.insert(list, player)
		end
	end
	return list
end

local function addVIPTrail(player: Player)
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
	local trail = Instance.new("Trail")
	trail.Name = "VIPTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	trail.LightEmission = 1
	trail.Lifetime = 0.5
	trail.Parent = root
end

---------------------------------------------------------------- sahur AI

local function spawnSahur()
	local offset = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
	local model = Arena.MakeSahur(Arena.Center + offset)
	model.Parent = sahurFolder
	model.PrimaryPart:SetNetworkOwner(nil)
	local sound = model.PrimaryPart:FindFirstChild("Footsteps") :: Sound?
	if sound then
		sound:Play()
	end
	local entry = {
		Model = model,
		Humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid,
		Root = model.PrimaryPart :: BasePart,
		Waypoints = nil,
		WaypointIndex = 0,
		NextPath = 0,
		StunnedUntil = 0,
	}
	table.insert(sahurs, entry)
	notify(nil, "TUNG TUNG TUNG SAHUR HAS ENTERED!", Color3.fromRGB(255, 60, 60))
	return entry
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function canSee(from: Vector3, to: BasePart): boolean
	rayParams.FilterDescendantsInstances = { sahurFolder, to.Parent :: Instance }
	return workspace:Raycast(from, to.Position - from, rayParams) == nil
end

local function updateSahur(s, now: number)
	local elapsed = now - roundStart
	local speed = math.min(Config.SahurMaxSpeed, Config.SahurSpeed + elapsed * Config.SahurSpeedGain)
	if os.clock() < slowUntil then
		speed *= 0.5
	end
	if os.clock() < s.StunnedUntil then
		speed = 0
	end
	s.Humanoid.WalkSpeed = speed

	-- Chase the closest living player.
	local best, bestDist = nil, math.huge
	for _, player in alivePlayers() do
		local root = rootOf(player) :: BasePart
		local d = (root.Position - s.Root.Position).Magnitude
		if d < bestDist then
			best, bestDist = root, d
		end
	end
	if not best then
		return
	end
	if bestDist < 45 and canSee(s.Root.Position, best) then
		s.Waypoints = nil
		s.Humanoid:MoveTo(best.Position)
		return
	end
	if now >= s.NextPath then
		s.NextPath = now + 0.8
		local target = best.Position
		task.spawn(function()
			local path = PathfindingService:CreatePath({ AgentRadius = 2.5, AgentHeight = 10, AgentCanJump = false })
			local ok = pcall(path.ComputeAsync, path, s.Root.Position, target)
			if ok and path.Status == Enum.PathStatus.Success then
				s.Waypoints = path:GetWaypoints()
				s.WaypointIndex = 2
			end
		end)
	end
	local waypoints = s.Waypoints
	if waypoints and waypoints[s.WaypointIndex] then
		local wp = waypoints[s.WaypointIndex].Position
		if (Vector3.new(wp.X, s.Root.Position.Y, wp.Z) - s.Root.Position).Magnitude < 4 then
			s.WaypointIndex += 1
		end
		local next = waypoints[s.WaypointIndex]
		if next then
			s.Humanoid:MoveTo(next.Position)
		end
	else
		s.Humanoid:MoveTo(best.Position)
	end
end

local function eliminate(player: Player, sahur)
	local data = DataService.Get(player)
	if data and (data.Shields > 0 or player:GetAttribute("FreeShield")) then
		if player:GetAttribute("FreeShield") then
			player:SetAttribute("FreeShield", nil)
		else
			data.Shields -= 1
		end
		sync(player)
		sahur.StunnedUntil = os.clock() + 2
		local root = rootOf(player)
		if root then
			local away = (root.Position - sahur.Root.Position) * Vector3.new(1, 0, 1)
			root.AssemblyLinearVelocity = (if away.Magnitude > 0 then away.Unit else Vector3.xAxis) * 90 + Vector3.new(0, 40, 0)
		end
		notify(player, "Your shield saved you! RUN!", Color3.fromRGB(120, 200, 255))
		return
	end
	player:SetAttribute("Alive", false)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
	notify(nil, player.DisplayName .. " got caught by Sahur!", Color3.fromRGB(255, 90, 90))
	notify(player, "Caught! Buy a Revive to jump back in!", Color3.fromRGB(255, 200, 0))
end

---------------------------------------------------------------- round loop

local function setState(state: string, timeLeft: number)
	workspace:SetAttribute("State", state)
	workspace:SetAttribute("TimeLeft", timeLeft)
	workspace:SetAttribute("AliveCount", #alivePlayers())
end

local function endRound()
	roundActive = false
	local survivors = alivePlayers()
	for _, player in survivors do
		local data = DataService.Get(player)
		if data then
			data.Wins += 1
			data.Survived += 1
			addCoins(player, Config.SurviveCoins * coinMultiplier(player))
		end
	end
	if #survivors > 0 then
		local names = {}
		for _, p in survivors do
			table.insert(names, p.DisplayName)
		end
		notify(nil, "SURVIVORS: " .. table.concat(names, ", "), Color3.fromRGB(90, 255, 90))
	else
		notify(nil, "Sahur got everyone...", Color3.fromRGB(255, 90, 90))
	end
	for _, s in sahurs do
		s.Model:Destroy()
	end
	table.clear(sahurs)
	for _, player in Players:GetPlayers() do
		player:SetAttribute("Alive", false)
		player:SetAttribute("FreeShield", nil)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			player.Character:PivotTo(Arena.LobbySpawn)
		end
	end
end

local function startRound()
	roundActive = true
	roundStart = os.clock()
	slowUntil = 0
	local participants = 0
	for _, player in Players:GetPlayers() do
		if DataService.Get(player) and rootOf(player) then
			participants += 1
			player:SetAttribute("Alive", true)
			if MonetizationService.OwnsPass(player, "StartShield") then
				player:SetAttribute("FreeShield", true)
			end
			player.Character:PivotTo(randomArenaSpawn())
			applySpeed(player)
		end
	end
	spawnSahur()
	for _ = 1, queuedSahurs do
		spawnSahur()
	end
	queuedSahurs = 0
	return participants
end

task.spawn(function()
	while true do
		for t = Config.Intermission, 1, -1 do
			setState("Intermission", t)
			task.wait(1)
		end
		local ready = 0
		for _, player in Players:GetPlayers() do
			if DataService.Get(player) and rootOf(player) then
				ready += 1
			end
		end
		if ready < Config.MinPlayers then
			continue
		end
		startRound()
		local extraIndex = 1
		local lastSecond = os.clock()
		while true do
			local now = os.clock()
			local elapsed = now - roundStart
			local left = Config.RoundTime - elapsed
			setState("Round", math.ceil(left))
			if left <= 0 or #alivePlayers() == 0 then
				break
			end
			local nextExtra = Config.ExtraSahurAt[extraIndex]
			if nextExtra and elapsed >= nextExtra then
				extraIndex += 1
				spawnSahur()
			end
			for _, s in sahurs do
				updateSahur(s, now)
				if now < s.StunnedUntil then
					continue
				end
				for _, player in alivePlayers() do
					local root = rootOf(player)
					if root and (root.Position - s.Root.Position).Magnitude < Config.KillRange + 1.5 then
						eliminate(player, s)
					end
				end
			end
			if now - lastSecond >= 1 then
				lastSecond = now
				for _, player in alivePlayers() do
					addCoins(player, Config.CoinPerSecondAlive * coinMultiplier(player))
					applySpeed(player)
				end
			end
			task.wait(0.1)
		end
		endRound()
		setState("Ended", 0)
		task.wait(4)
	end
end)

---------------------------------------------------------------- coin shop

BuyItemRemote.OnServerInvoke = function(player, item)
	local data = DataService.Get(player)
	if not data then
		return false, "Loading..."
	end
	local cost = if item == "Shield" then Config.ShieldCost elseif item == "Potion" then Config.SpeedPotionCost else nil
	if not cost then
		return false, "Unknown item"
	end
	if data.Coins < cost then
		return false, "Need " .. cost .. " coins!"
	end
	data.Coins -= cost
	if item == "Shield" then
		data.Shields += 1
	else
		data.Potions += 1
	end
	sync(player)
	return true, "Bought a " .. item .. "!"
end

UsePotionRemote.OnServerInvoke = function(player)
	local data = DataService.Get(player)
	if not data or data.Potions <= 0 then
		return false, "No potions! Buy one in the coin shop."
	end
	data.Potions -= 1
	potionUntil[player] = os.clock() + 20
	applySpeed(player)
	sync(player)
	task.delay(20.1, applySpeed, player)
	return true, "SPEED BOOST for 20s!"
end

---------------------------------------------------------------- players

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
	local function onCharacter(character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait()
		if roundActive and player:GetAttribute("Alive") then
			character:PivotTo(randomArenaSpawn())
		end
		applySpeed(player)
		if MonetizationService.OwnsPass(player, "VIP") then
			addVIPTrail(player)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	potionUntil[player] = nil
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		Revive = function(player, data)
			if roundActive and not player:GetAttribute("Alive") then
				player:SetAttribute("Alive", true)
				player:LoadCharacter()
				notify(nil, player.DisplayName .. " REVIVED!", Color3.fromRGB(90, 255, 90))
			else
				-- Not dead in a round: give a shield so the purchase is never wasted.
				data.Shields += 1
				sync(player)
				notify(player, "You weren't caught, so you got a Shield instead!", Color3.fromRGB(120, 200, 255))
			end
			return true
		end,
		SlowSahur = function(player)
			slowUntil = math.max(slowUntil, os.clock()) + 15
			notify(nil, player.DisplayName .. " SLOWED every Sahur for 15s!", Color3.fromRGB(120, 200, 255))
			return true
		end,
		ExtraSahur = function(player)
			if roundActive then
				spawnSahur()
			else
				queuedSahurs += 1
			end
			notify(nil, player.DisplayName .. " unleashed ANOTHER SAHUR!", Color3.fromRGB(255, 60, 60))
			return true
		end,
		Coins = function(player)
			addCoins(player, 500)
			return true
		end,
	},
	OnPassOwned = function(player, name)
		if name == "VIP" then
			addVIPTrail(player)
		end
		applySpeed(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("SurviveSahur_v1", {
	Coins = 0,
	Wins = 0,
	Survived = 0,
	Shields = 0,
	Potions = 0,
})
