-- Brainrot Lifting Simulator server: lifting, weights, boss arm-wrestling, rebirths, purchases.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BrainrotModels = require(ReplicatedStorage.Common.BrainrotModels)
local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
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
local LiftRemote = remote("RemoteEvent", "Lift")
local BuyWeightRemote = remote("RemoteFunction", "BuyWeight")
local WrestleRemote = remote("RemoteFunction", "Wrestle")
local WrestleTapRemote = remote("RemoteEvent", "WrestleTap")
local RebirthRemote = remote("RemoteFunction", "Rebirth")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

---------------------------------------------------------------- world: gym + boss arena

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
part({ Name = "Floor", Size = Vector3.new(160, 2, 260), Position = Vector3.new(0, -1, 60), Color = Color3.fromRGB(90, 90, 110), Material = Enum.Material.Concrete })
part({ Name = "GymMat", Size = Vector3.new(60, 0.2, 50), Position = Vector3.new(0, 0.1, 0), Color = Color3.fromRGB(40, 140, 220), Material = Enum.Material.Fabric })
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = Vector3.new(0, 0.5, -10)
spawn.Neutral = true
spawn.Color = Color3.fromRGB(255, 200, 40)
spawn.Material = Enum.Material.Neon
spawn.Parent = world

local bossFolder = Instance.new("Folder")
bossFolder.Name = "Bosses"
bossFolder.Parent = workspace

for i, boss in Config.Bosses do
	local z = 40 + (i - 1) * 20
	local x = if i % 2 == 0 then 30 else -30
	local tableTop = part({ Name = "Table" .. i, Size = Vector3.new(4, 0.6, 6), Position = Vector3.new(x, 3.6, z), Color = Color3.fromRGB(120, 80, 45), Material = Enum.Material.WoodPlanks })
	part({ Size = Vector3.new(1, 3.3, 1), Position = Vector3.new(x, 1.65, z), Color = Color3.fromRGB(80, 55, 30) })
	local stand = Instance.new("Model")
	stand.Name = boss.Id
	stand:SetAttribute("BossIndex", i)
	stand.Parent = bossFolder
	tableTop.Parent = stand
	stand.PrimaryPart = tableTop
	if BrainrotModels.Has(boss.Id) then
		local figure = BrainrotModels.Build(boss.Id, { Scale = 0.9 + i * 0.08 })
		figure:PivotTo(CFrame.lookAt(Vector3.new(x, figure:GetAttribute("RootHeight"), z + 5.5), Vector3.new(x, figure:GetAttribute("RootHeight"), z)))
		figure.Parent = stand
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(240, 70)
	gui.StudsOffset = Vector3.new(0, 9, 0)
	gui.MaxDistance = 90
	gui.Parent = tableTop
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = boss.Name .. "\nNeeds " .. Format.Abbreviate(boss.Need) .. " 💪  •  +" .. boss.Wins .. " 🏆"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Parent = label
	label.Parent = gui
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "WrestlePrompt"
	prompt.ActionText = "Arm Wrestle"
	prompt.ObjectText = boss.Name
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("BossIndex", i)
	prompt.Parent = tableTop
end

---------------------------------------------------------------- stats

local liftBudget: { [Player]: number } = {}
local matches: { [Player]: any } = {}

local function liftPower(player: Player, data): number
	local weight = Config.WeightById[data.Weight] or Config.Weights[1]
	local p = weight.Power * (1 + data.Rebirths * Config.RebirthBonus)
	if MonetizationService.OwnsPass(player, "DoubleStrength") then
		p *= 2
	end
	if MonetizationService.OwnsPass(player, "VIP") then
		p *= 1.5
	end
	if data.ProteinUntil > os.time() then
		p *= 3
	end
	return p
end

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Strength", data.Strength)
	player:SetAttribute("Wins", data.Wins)
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("Weight", data.Weight)
	player:SetAttribute("LiftPower", liftPower(player, data))
	player:SetAttribute("BestBoss", data.BestBoss)
	player:SetAttribute("ProteinUntil", data.ProteinUntil)
	local owned = {}
	for id in data.Owned do
		table.insert(owned, id)
	end
	player:SetAttribute("OwnedWeights", table.concat(owned, ","))
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Strength.Value = Format.Abbreviate(data.Strength)
		stats.Wins.Value = data.Wins
	end
end

local function giveDumbbell(player: Player)
	local data = DataService.Get(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not data or not backpack then
		return
	end
	for _, container in { backpack, player.Character } do
		local old = container and container:FindFirstChild("Dumbbell")
		if old then
			old:Destroy()
		end
	end
	local weight = Config.WeightById[data.Weight] or Config.Weights[1]
	local tool = Instance.new("Tool")
	tool.Name = "Dumbbell"
	tool.ToolTip = weight.Name
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.4, 2.4)
	handle.Color = Color3.fromRGB(60, 60, 65)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Parent = tool
	for _, z in { -1.1, 1.1 } do
		local plate = Instance.new("Part")
		plate.Shape = Enum.PartType.Cylinder
		plate.Size = Vector3.new(0.5, 1.4 + weight.Index * 0.12, 1.4 + weight.Index * 0.12)
		plate.Color = weight.Color
		plate.Material = if weight.Index >= 5 then Enum.Material.Neon else Enum.Material.Metal
		plate.CanCollide = false
		plate.Massless = true
		plate.CFrame = handle.CFrame * CFrame.new(0, 0, z) * CFrame.Angles(0, math.rad(90), 0)
		local w = Instance.new("WeldConstraint")
		w.Part0 = handle
		w.Part1 = plate
		w.Parent = plate
		plate.Parent = tool
	end
	tool.Parent = backpack
end

LiftRemote.OnServerEvent:Connect(function(player)
	local data = DataService.Get(player)
	local budget = liftBudget[player] or 0
	if not data or budget <= 0 or matches[player] then
		return
	end
	if not (player.Character and player.Character:FindFirstChild("Dumbbell")) then
		return
	end
	liftBudget[player] = budget - 1
	data.Strength += liftPower(player, data)
	data.Lifts += 1
	player:SetAttribute("Strength", data.Strength)
end)

BuyWeightRemote.OnServerInvoke = function(player, id)
	local data = DataService.Get(player)
	local weight = type(id) == "string" and Config.WeightById[id]
	if not data or not weight then
		return false, "Invalid"
	end
	if not data.Owned[id] then
		if data.Wins < weight.Cost then
			return false, "Need " .. weight.Cost .. " wins! Beat bosses to earn wins."
		end
		data.Wins -= weight.Cost
		data.Owned[id] = true
	end
	data.Weight = id
	giveDumbbell(player)
	sync(player)
	return true, "Equipped " .. weight.Name .. "!"
end

---------------------------------------------------------------- arm wrestling
-- A match lasts up to 10s. The bar starts at 50%. Your taps push it up by an amount that depends on
-- how strong you are vs the boss; the boss pushes back steadily. Reach 100% to win.

local function startMatch(player: Player, index: number): (boolean, any)
	local data = DataService.Get(player)
	local boss = Config.Bosses[index]
	if not data or not boss or matches[player] then
		return false, "Busy"
	end
	if index > data.BestBoss + 1 then
		return false, "Beat " .. Config.Bosses[index - 1].Name .. " first!"
	end
	local ratio = data.Strength / boss.Need
	local match = {
		Boss = index,
		Progress = 0.5,
		TapPower = math.clamp(0.035 * ratio, 0.004, 0.2),
		Push = 0.09,
		Ends = os.clock() + 10,
	}
	matches[player] = match
	player:SetAttribute("Wrestling", index)
	player:SetAttribute("WrestleProgress", 0.5)
	task.spawn(function()
		while matches[player] == match do
			task.wait(0.1)
			match.Progress -= match.Push * 0.1
			player:SetAttribute("WrestleProgress", match.Progress)
			local finished = match.Progress >= 1 or match.Progress <= 0 or os.clock() >= match.Ends
			if finished then
				matches[player] = nil
				player:SetAttribute("Wrestling", nil)
				local won = match.Progress >= 1
				if won then
					local wins = boss.Wins * (if MonetizationService.OwnsPass(player, "DoubleWins") then 2 else 1) * (1 + data.Rebirths * 0.5)
					wins = math.floor(wins)
					data.Wins += wins
					if index > data.BestBoss then
						data.BestBoss = index
						notify(nil, player.DisplayName .. " defeated " .. boss.Name .. "!", Color3.fromRGB(255, 215, 0))
					end
					notify(player, "You beat " .. boss.Name .. "! +" .. wins .. " wins", Color3.fromRGB(90, 255, 90))
				else
					notify(player, boss.Name .. " was too strong! Lift more.", Color3.fromRGB(255, 90, 90))
				end
				player:SetAttribute("WrestleResult", if won then "Win" else "Lose")
				sync(player)
			end
		end
	end)
	return true, match.TapPower
end

WrestleRemote.OnServerInvoke = function(player, index)
	if type(index) ~= "number" then
		return false, "Invalid"
	end
	return startMatch(player, index)
end

WrestleTapRemote.OnServerEvent:Connect(function(player)
	local match = matches[player]
	local budget = liftBudget[player] or 0
	if not match or budget <= 0 then
		return
	end
	liftBudget[player] = budget - 1
	match.Progress = math.min(1, match.Progress + match.TapPower)
end)

RebirthRemote.OnServerInvoke = function(player)
	local data = DataService.Get(player)
	if not data then
		return false, "Loading..."
	end
	local cost = Config.RebirthCost(data.Rebirths)
	if data.Wins < cost then
		return false, "Need " .. Format.Abbreviate(cost) .. " wins to rebirth!"
	end
	data.Wins = 0
	data.Strength = 0
	data.BestBoss = 0
	data.Owned = { stick = true }
	data.Weight = "stick"
	data.Rebirths += 1
	giveDumbbell(player)
	sync(player)
	notify(nil, player.DisplayName .. " rebirthed! (" .. data.Rebirths .. ")", Color3.fromRGB(255, 215, 0))
	return true, "Rebirth! " .. (1 + data.Rebirths * Config.RebirthBonus) .. "x strength forever."
end

---------------------------------------------------------------- loops

task.spawn(function()
	while true do
		task.wait(1)
		for _, player in Players:GetPlayers() do
			liftBudget[player] = Config.MaxLiftsPerSecond
			local data = DataService.Get(player)
			if data and MonetizationService.OwnsPass(player, "AutoLift") and not matches[player] then
				data.Strength += liftPower(player, data) * Config.AutoLiftsPerSecond
			end
			if data then
				sync(player)
			end
		end
	end
end)

---------------------------------------------------------------- players + monetization

DataService.ProfileLoaded:Connect(function(player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local strength = Instance.new("StringValue")
	strength.Name = "Strength"
	strength.Parent = stats
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Parent = stats
	stats.Parent = player
	if not Config.WeightById[data.Weight] then
		data.Weight = "stick"
	end
	sync(player)
	player.CharacterAdded:Connect(function()
		task.wait()
		giveDumbbell(player)
	end)
	if player.Character then
		giveDumbbell(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	liftBudget[player] = nil
	matches[player] = nil
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		StrengthPack = function(player, data)
			local amount = math.max(500, math.floor(liftPower(player, data) * 8 * 1200))
			data.Strength += amount
			sync(player)
			notify(player, "+" .. Format.Abbreviate(amount) .. " strength!", Color3.fromRGB(90, 255, 90))
			return true
		end,
		WinsPack = function(player, data)
			local best = Config.Bosses[math.max(1, data.BestBoss)]
			local amount = best.Wins * 5
			data.Wins += amount
			sync(player)
			notify(player, "+" .. amount .. " wins!", Color3.fromRGB(255, 215, 0))
			return true
		end,
		Protein = function(player, data)
			data.ProteinUntil = math.max(data.ProteinUntil, os.time()) + 900
			sync(player)
			notify(player, "3x strength for 15 minutes!", Color3.fromRGB(0, 255, 200))
			return true
		end,
	},
	OnPassOwned = function(player, name)
		sync(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("BrainrotLifting_v1", {
	Strength = 0,
	Wins = 0,
	Rebirths = 0,
	Weight = "stick",
	Owned = { stick = true },
	BestBoss = 0,
	Lifts = 0,
	ProteinUntil = 0,
})
