-- Tower of Brainrot server: rounds with a fresh random tower, kill bricks, lava mutator, coins, coils.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)
local Tower = require(script.Parent.Tower)

Lighting.ClockTime = 16
Lighting.Brightness = 2.5

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local NotifyRemote = Instance.new("RemoteEvent")
NotifyRemote.Name = "Notify"
NotifyRemote.Parent = remotes
local CoilRemote = Instance.new("RemoteEvent")
CoilRemote.Name = "ToggleCoil"
CoilRemote.Parent = remotes

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(8, 1, 8)
spawn.Position = Vector3.new(-12, 0.5, -12)
spawn.Neutral = true
spawn.Color = Color3.fromRGB(255, 215, 0)
spawn.Material = Enum.Material.Neon
spawn.Parent = workspace

local lava = Instance.new("Part")
lava.Name = "RisingLava"
lava.Anchored = true
lava.CanCollide = false
lava.Size = Vector3.new(44, 2, 44)
lava.Color = Color3.fromRGB(255, 90, 20)
lava.Material = Enum.Material.Neon
lava.Transparency = 0.25
lava.Position = Vector3.new(0, -20, 0)
lava:SetAttribute("Kill", true)
lava.Parent = workspace

local finishers: { [Player]: boolean } = {}
local roundEnds = 0
local lavaOn = false
local rebuildRequested = false

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("Wins", data.Wins)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Wins.Value = data.Wins
		stats.Coins.Value = data.Coins
	end
end

local function applyMovement(player: Player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.UseJumpPower = true
	humanoid.WalkSpeed = if player:GetAttribute("SpeedOn") and MonetizationService.OwnsPass(player, "SpeedCoil") then 26 else 16
	humanoid.JumpPower = if player:GetAttribute("GravityOn") and MonetizationService.OwnsPass(player, "GravityCoil") then 70 else 50
end

local function hookKillers()
	for _, p in Tower.Folder():GetDescendants() do
		if p:IsA("BasePart") and p:GetAttribute("Kill") then
			p.Touched:Connect(function(hit)
				local model = hit:FindFirstAncestorOfClass("Model")
				local humanoid = model and model:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					humanoid.Health = 0
				end
			end)
		end
	end
end
lava.Touched:Connect(function(hit)
	local model = hit:FindFirstAncestorOfClass("Model")
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end
end)

local function onFinish(player: Player)
	if finishers[player] then
		return
	end
	finishers[player] = true
	local data = DataService.Get(player)
	if data then
		local m = 1
		if MonetizationService.OwnsPass(player, "DoubleCoins") then
			m *= 2
		end
		if MonetizationService.OwnsPass(player, "VIP") then
			m *= 1.5
		end
		data.Wins += 1
		data.Coins += math.floor(Config.TopCoins * m)
		sync(player)
	end
	notify(nil, player.DisplayName .. " beat the Tower of Brainrot!", Color3.fromRGB(255, 215, 0))
end

local function newTower()
	local finish = Tower.Build()
	finish.Touched:Connect(function(hit)
		local model = hit:FindFirstAncestorOfClass("Model")
		local player = model and Players:GetPlayerFromCharacter(model)
		if player then
			onFinish(player)
		end
	end)
	hookKillers()
	table.clear(finishers)
	lavaOn = false
	lava.Position = Vector3.new(0, -20, 0)
	roundEnds = os.time() + Config.RoundTime
	workspace:SetAttribute("RoundEnds", roundEnds)
	workspace:SetAttribute("LavaOn", false)
	for _, player in Players:GetPlayers() do
		if player.Character then
			player.Character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
		end
	end
	notify(nil, "A NEW TOWER appeared! Reach the top before time runs out!", Color3.fromRGB(120, 220, 255))
end

task.spawn(function()
	newTower()
	while true do
		task.wait(0.2)
		if rebuildRequested or os.time() >= roundEnds then
			rebuildRequested = false
			newTower()
		end
		if lavaOn and lava.Position.Y < Config.Sections * Config.SectionHeight - 4 then
			lava.Position += Vector3.new(0, Config.LavaSpeed * 0.2, 0)
		end
		-- current section for each player (shown on the HUD + used by Skip Section)
		for _, player in Players:GetPlayers() do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				player:SetAttribute("Section", math.clamp(math.floor(root.Position.Y / Config.SectionHeight) + 1, 1, Config.Sections))
			end
		end
	end
end)

CoilRemote.OnServerEvent:Connect(function(player, name)
	if name == "Speed" then
		player:SetAttribute("SpeedOn", not player:GetAttribute("SpeedOn"))
	elseif name == "Gravity" then
		player:SetAttribute("GravityOn", not player:GetAttribute("GravityOn"))
	end
	applyMovement(player)
end)

DataService.ProfileLoaded:Connect(function(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in { "Wins", "Coins" } do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = stats
	end
	stats.Parent = player
	sync(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 10)
		applyMovement(player)
	end)
	if player.Character then
		applyMovement(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	finishers[player] = nil
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		LavaRise = function(player)
			lavaOn = true
			lava.Position = Vector3.new(0, -2, 0)
			workspace:SetAttribute("LavaOn", true)
			notify(nil, player.DisplayName .. " made the LAVA RISE! Climb!", Color3.fromRGB(255, 120, 40))
			return true
		end,
		SlowTime = function(player)
			roundEnds += 120
			workspace:SetAttribute("RoundEnds", roundEnds)
			notify(nil, player.DisplayName .. " added 2 minutes to the timer!", Color3.fromRGB(120, 255, 120))
			return true
		end,
		SkipSection = function(player)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local section = player:GetAttribute("Section") or 1
				local y = math.min(section, Config.Sections) * Config.SectionHeight + 3
				player.Character:PivotTo(CFrame.new(10, y, 10))
			end
			return true
		end,
		NewTower = function(player)
			rebuildRequested = true
			notify(nil, player.DisplayName .. " summoned a NEW TOWER!", Color3.fromRGB(120, 220, 255))
			return true
		end,
	},
	OnPassOwned = function(player, name)
		if name == "SpeedCoil" then
			player:SetAttribute("SpeedOn", true)
		elseif name == "GravityCoil" then
			player:SetAttribute("GravityOn", true)
		end
		applyMovement(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("TowerOfBrainrot_v1", {
	Coins = 0,
	Wins = 0,
})
