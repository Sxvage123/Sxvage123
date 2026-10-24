-- Escape the Lava for Brainrots server: brainrots spawn out on the beach (rarer the further out),
-- players grab them and carry them home, and a lava sweeps the beach every so often.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotModels = require(ReplicatedStorage.Common.BrainrotModels)
local Format = require(ReplicatedStorage.Common.Format)
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
local UpgradeRemote = remote("RemoteFunction", "UpgradeSpeed")
local RebirthRemote = remote("RemoteFunction", "Rebirth")
local HomeRemote = remote("RemoteEvent", "Home")

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
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent or world
	return p
end
local function billboard(adornee: BasePart, height: number, lines: { { string | Color3 } }): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 26 * #lines)
	gui.StudsOffset = Vector3.new(0, height, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120
	gui.Adornee = adornee
	for i, line in lines do
		local label = Instance.new("TextLabel")
		label.Name = "Line" .. i
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, 26)
		label.Position = UDim2.fromOffset(0, (i - 1) * 26)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Text = line[1] :: string
		label.TextColor3 = line[2] :: Color3
		label.TextStrokeTransparency = 0
		label.Parent = gui
	end
	gui.Parent = adornee
	return gui
end

---------------------------------------------------------------- map

local TRACK_W = 290
local PLOTS = 6
local PLOT_W = 44
local BASE_DEPTH = 70

-- Base strip: a raised, wave-proof ledge with one plot per player.
part({ Name = "BaseGround", Size = Vector3.new(TRACK_W, 4, BASE_DEPTH), Position = Vector3.new(0, -2, -BASE_DEPTH / 2), Color = Color3.fromRGB(110, 200, 110), Material = Enum.Material.Grass })
part({ Name = "SafeLine", Size = Vector3.new(TRACK_W, 0.2, 2), Position = Vector3.new(0, 0.1, -1), Color = Color3.fromRGB(90, 255, 120), Material = Enum.Material.Neon })
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = Vector3.new(0, 0.5, -BASE_DEPTH + 6)
spawn.Neutral = true
spawn.Color = Color3.fromRGB(255, 200, 0)
spawn.Parent = world

-- The beach, coloured per zone, with zone signs.
for _, zone in Config.Zones do
	local len = zone.To - zone.From
	part({ Name = "Zone", Size = Vector3.new(TRACK_W, 2, len), Position = Vector3.new(0, -1, zone.From + len / 2), Color = zone.Color, Material = Enum.Material.Basalt })
	local sign = part({ Name = "ZoneSign", Size = Vector3.new(40, 8, 1), Position = Vector3.new(0, 18, zone.From), Color = Color3.fromRGB(25, 25, 35), CanCollide = false })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(600, 120)
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = zone.Name:upper()
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Config.RarityByName[zone.Rarity].Color
	label.Parent = gui
end
local first = Config.Zones[1]
part({ Name = "Shallows", Size = Vector3.new(TRACK_W, 2, first.From), Position = Vector3.new(0, -1, first.From / 2), Color = Color3.fromRGB(240, 220, 160), Material = Enum.Material.Basalt })
local lastTo = Config.Zones[#Config.Zones].To
part({ Name = "FarEnd", Size = Vector3.new(TRACK_W, 2, Config.TrackEnd - lastTo), Position = Vector3.new(0, -1, (lastTo + Config.TrackEnd) / 2), Color = Color3.fromRGB(30, 30, 40), Material = Enum.Material.Basalt })
for _, sx in { -1, 1 } do
	part({ Name = "Cliff", Size = Vector3.new(6, 40, Config.TrackEnd + BASE_DEPTH), Position = Vector3.new(sx * (TRACK_W / 2 + 3), 18, (Config.TrackEnd - BASE_DEPTH) / 2), Color = Color3.fromRGB(120, 100, 80), Material = Enum.Material.Slate })
end
part({ Name = "Volcano", Size = Vector3.new(TRACK_W + 12, 60, 6), Position = Vector3.new(0, 29, Config.TrackEnd + 3), Color = Color3.fromRGB(70, 40, 35), Material = Enum.Material.Basalt, Transparency = 0.3 })

-- Shelters: duck into one when the wave comes and it washes right over you.
local shelters: { BasePart } = {}
do
	local rng = Random.new(7)
	local z = 160
	while z < Config.TrackEnd - 40 do
		for _ = 1, 3 do
			local x = rng:NextInteger(-TRACK_W // 2 + 20, TRACK_W // 2 - 20)
			local floor = part({ Name = "Shelter", Size = Vector3.new(16, 0.4, 16), Position = Vector3.new(x, 0.2, z), Color = Color3.fromRGB(60, 230, 90), Material = Enum.Material.Neon })
			part({ Name = "ShelterRoof", Size = Vector3.new(18, 1, 18), Position = Vector3.new(x, 9, z), Color = Color3.fromRGB(90, 90, 100), Material = Enum.Material.Concrete })
			for _, c in { Vector3.new(-8, 0, -8), Vector3.new(8, 0, -8), Vector3.new(-8, 0, 8), Vector3.new(8, 0, 8) } do
				part({ Size = Vector3.new(1.5, 9, 1.5), Position = Vector3.new(x, 4.5, z) + c, Color = Color3.fromRGB(90, 90, 100) })
			end
			table.insert(shelters, floor)
		end
		z += 170
	end
end

local function inShelter(pos: Vector3): boolean
	for _, s in shelters do
		local d = pos - s.Position
		if math.abs(d.X) <= 8.5 and math.abs(d.Z) <= 8.5 and d.Y < 9 then
			return true
		end
	end
	return false
end

---------------------------------------------------------------- plots

type Plot = { Index: number, Owner: Player?, Floor: BasePart, Pedestals: { BasePart }, Sign: TextLabel, Models: { [number]: Model } }
local plots: { Plot } = {}
for i = 1, PLOTS do
	local x = (i - (PLOTS + 1) / 2) * PLOT_W
	local floor = part({ Name = "Plot" .. i, Size = Vector3.new(PLOT_W - 4, 0.4, BASE_DEPTH - 20), Position = Vector3.new(x, 0.2, -BASE_DEPTH / 2), Color = Color3.fromRGB(80, 80, 95), Material = Enum.Material.SmoothPlastic })
	local pedestals = {}
	for s = 1, Config.BaseSlots do
		local col = (s - 1) % 2
		local row = (s - 1) // 2
		local ped = part({ Name = "Pedestal" .. s, Size = Vector3.new(7, 1.2, 7), Position = Vector3.new(x - 8 + col * 16, 0.8, -12 - row * 9), Color = Color3.fromRGB(200, 200, 215), Material = Enum.Material.Marble })
		table.insert(pedestals, ped)
	end
	local signPart = part({ Name = "PlotSign", Size = Vector3.new(PLOT_W - 6, 6, 1), Position = Vector3.new(x, 7, -BASE_DEPTH + 2), Color = Color3.fromRGB(30, 30, 45) })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(400, 80)
	gui.Parent = signPart
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = "Empty base"
	label.Parent = gui
	table.insert(plots, { Index = i, Owner = nil, Floor = floor, Pedestals = pedestals, Sign = label, Models = {} })
end

local function plotOf(player: Player): Plot?
	for _, plot in plots do
		if plot.Owner == player then
			return plot
		end
	end
	return nil
end

---------------------------------------------------------------- state

local carrying: { [Player]: { string } } = {}
local carryModels: { [Player]: { Model } } = {}
local luckUntil = 0
local calmUntil = 0
local wave = { Active = false, Front = Config.TrackEnd, NextAt = os.clock() + Config.WaveInterval }

local function multiplier(player: Player, data): number
	local m = 1 + data.Rebirths * Config.RebirthBonus
	if MonetizationService.OwnsPass(player, "DoubleCash") then
		m *= 2
	end
	if MonetizationService.OwnsPass(player, "VIP") then
		m *= 1.5
	end
	return m
end

local function incomeOf(data): number
	local total = 0
	for _, id in data.Placed do
		local info = Config.ById[id]
		if info then
			total += info.Income
		end
	end
	return total
end

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Cash", data.Cash)
	player:SetAttribute("Income", math.floor(incomeOf(data) * multiplier(player, data)))
	player:SetAttribute("SpeedLevel", data.SpeedLevel)
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("Carrying", #(carrying[player] or {}))
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		(ls :: any).Cash.Value = math.min(data.Cash, 2 ^ 53);
		(ls :: any).Rebirths.Value = data.Rebirths
	end
end

local function carryCap(player: Player): number
	return if MonetizationService.OwnsPass(player, "CarryMore") then 3 else 1
end

local function applySpeed(player: Player)
	local data = DataService.Get(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if data and humanoid then
		local speed = Config.WalkSpeed + data.SpeedLevel * Config.SpeedPerLevel
		if MonetizationService.OwnsPass(player, "SpeedCoil") then
			speed *= Config.SpeedCoilMultiplier
		end
		humanoid.WalkSpeed = speed
	end
end

---------------------------------------------------------------- base display

local function renderPlot(plot: Plot)
	for _, m in plot.Models do
		m:Destroy()
	end
	table.clear(plot.Models)
	local owner = plot.Owner
	local data = owner and DataService.Get(owner)
	plot.Sign.Text = if owner then owner.DisplayName .. "'s Base" else "Empty base"
	if not owner or not data then
		return
	end
	for slot, id in data.Placed do
		local info = Config.ById[id]
		local ped = plot.Pedestals[slot]
		if info and ped and BrainrotModels.Has(id) then
			local model, root = BrainrotModels.Build(id, { Scale = 0.8 })
			local h = (model:GetAttribute("RootHeight") :: number?) or 3
			model:PivotTo(CFrame.new(ped.Position + Vector3.new(0, 0.6 + h, 0)) * CFrame.Angles(0, math.pi, 0))
			local rarity = Config.RarityByName[info.Rarity]
			billboard(root, h + 2, { { info.Name, Color3.new(1, 1, 1) }, { info.Rarity, rarity.Color }, { "$" .. Format.Abbreviate(info.Income) .. "/s", Color3.fromRGB(90, 255, 90) } })
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "SellPrompt"
			prompt.ActionText = "Sell ($" .. Format.Abbreviate(info.Income * 60 * Config.SellRefund) .. ")"
			prompt.ObjectText = info.Name
			prompt.HoldDuration = 1
			prompt.RequiresLineOfSight = false
			prompt.Parent = root
			prompt.Triggered:Connect(function(who)
				if who ~= owner or data.Placed[slot] ~= id then
					return
				end
				table.remove(data.Placed, slot)
				data.Cash += math.floor(info.Income * 60 * Config.SellRefund)
				sync(owner)
				renderPlot(plot)
			end)
			model.Parent = world
			plot.Models[slot] = model
		end
	end
end

---------------------------------------------------------------- carrying

local function clearCarry(player: Player)
	local models: { Model } = carryModels[player] or {}
	for _, m in models do
		m:Destroy()
	end
	carryModels[player] = {}
	carrying[player] = {}
	player:SetAttribute("Carrying", 0)
end

local function attachCarry(player: Player, id: string)
	local character = player.Character
	local head = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not head then
		return
	end
	local model, root = BrainrotModels.Build(id, { Scale = 0.55, Anchored = false })
	local n = #(carryModels[player] or {})
	root.CFrame = head.CFrame * CFrame.new(0, 4.5 + n * 3, 0)
	local w = Instance.new("WeldConstraint")
	w.Part0 = head
	w.Part1 = root
	w.Parent = root
	model.Parent = character
	carryModels[player] = carryModels[player] or {}
	table.insert(carryModels[player], model)
end

local function deposit(player: Player)
	local data = DataService.Get(player)
	local plot = plotOf(player)
	local held = carrying[player]
	if not data or not plot or not held or #held == 0 then
		return
	end
	local stored, sold = 0, 0
	for _, id in held do
		if #data.Placed < Config.BaseSlots then
			table.insert(data.Placed, id)
			stored += 1
			local info = Config.ById[id]
			if info and Config.RarityIndex[info.Rarity] >= 5 then
				notify(nil, player.DisplayName .. " saved a " .. info.Rarity:upper() .. " " .. info.Name .. "!", Config.RarityByName[info.Rarity].Color)
			end
		else
			local info = Config.ById[id]
			data.Cash += math.floor((if info then info.Income else 1) * 60 * Config.SellRefund)
			sold += 1
		end
	end
	clearCarry(player)
	sync(player)
	renderPlot(plot)
	if sold > 0 then
		notify(player, "Base full! Sold " .. sold .. " brainrot(s). Sell weak ones to make room.", Color3.fromRGB(255, 200, 0))
	elseif stored > 0 then
		notify(player, "Brainrot saved to your base!", Color3.fromRGB(90, 255, 90))
	end
end

---------------------------------------------------------------- beach spawns

local spawnFolder = Instance.new("Folder")
spawnFolder.Name = "BeachBrainrots"
spawnFolder.Parent = workspace
local zoneCounts: { [number]: number } = {}

local function pickBrainrot(zoneIndex: number): string
	local zone = Config.Zones[zoneIndex]
	local idx = Config.RarityIndex[zone.Rarity]
	-- Small chance of the next rarity up; Server Luck doubles it. The last zone can roll a Secret.
	local upChance = if os.clock() < luckUntil then 0.16 else 0.08
	if zoneIndex == #Config.Zones then
		upChance = if os.clock() < luckUntil then 0.05 else 0.02
	end
	if math.random() < upChance and Config.Rarities[idx + 1] then
		idx += 1
	end
	local pool = Config.ByRarity[Config.Rarities[idx].Name]
	return pool[math.random(1, #pool)].Id
end

local function spawnBrainrot(zoneIndex: number, id: string, z: number?)
	local zone = Config.Zones[zoneIndex]
	local info = Config.ById[id]
	if not info or not BrainrotModels.Has(id) then
		return
	end
	local x = math.random(-TRACK_W // 2 + 15, TRACK_W // 2 - 15)
	local zz = z or math.random(zone.From + 10, zone.To - 10)
	local rarity = Config.RarityByName[info.Rarity]
	local model, root = BrainrotModels.Build(id, { Scale = 0.9 })
	local h = (model:GetAttribute("RootHeight") :: number?) or 3
	model:PivotTo(CFrame.new(x, h, zz) * CFrame.Angles(0, math.rad(math.random(0, 359)), 0))
	model:SetAttribute("Zone", zoneIndex)
	billboard(root, h + 2, { { info.Name, Color3.new(1, 1, 1) }, { info.Rarity, rarity.Color }, { "$" .. Format.Abbreviate(info.Income) .. "/s", Color3.fromRGB(90, 255, 90) } })
	if Config.RarityIndex[info.Rarity] >= 4 then
		local light = Instance.new("PointLight")
		light.Color = rarity.Color
		light.Range = 14
		light.Brightness = 2
		light.Parent = root
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GrabPrompt"
	prompt.ActionText = "Grab"
	prompt.ObjectText = info.Name
	prompt.HoldDuration = 0.3 + Config.RarityIndex[info.Rarity] * 0.15
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.Parent = root
	zoneCounts[zoneIndex] = (zoneCounts[zoneIndex] or 0) + 1
	prompt.Triggered:Connect(function(player)
		if not model.Parent then
			return
		end
		local held = carrying[player] or {}
		carrying[player] = held
		if #held >= carryCap(player) then
			notify(player, "Your hands are full! Get the Big Backpack to carry 3.", Color3.fromRGB(255, 200, 0))
			return
		end
		model:Destroy()
		zoneCounts[zoneIndex] -= 1
		table.insert(held, id)
		attachCarry(player, id)
		player:SetAttribute("Carrying", #held)
		notify(player, "Got " .. info.Name .. "! Run back to your base!", rarity.Color)
	end)
	model.Parent = spawnFolder
end

task.spawn(function()
	while true do
		for i, zone in Config.Zones do
			if (zoneCounts[i] or 0) < zone.Max then
				spawnBrainrot(i, pickBrainrot(i))
			end
		end
		task.wait(3)
	end
end)

---------------------------------------------------------------- lava

local waveModel = Instance.new("Model")
waveModel.Name = "Lava"
local waveBody = part({ Name = "Lava", Size = Vector3.new(TRACK_W, 60, 30), Color = Color3.fromRGB(255, 90, 20), Material = Enum.Material.Neon, Transparency = 0.1, CanCollide = false, CanTouch = false }, waveModel)
part({ Name = "Foam", Size = Vector3.new(TRACK_W, 6, 34), Color = Color3.fromRGB(255, 200, 60), Material = Enum.Material.Neon, CanCollide = false, CanTouch = false, CFrame = CFrame.new(0, 31, 0) }, waveModel)
waveModel.PrimaryPart = waveBody
local HIDDEN = CFrame.new(0, -200, Config.TrackEnd + 200)
waveModel:PivotTo(HIDDEN)
waveModel.Parent = workspace

local function hitByWave(player: Player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		local lost = #(carrying[player] or {})
		clearCarry(player)
		humanoid.Health = 0
		notify(player, if lost > 0 then "The lava took your brainrot!" else "Burned by the lava!", Color3.fromRGB(80, 160, 255))
	end
end

task.spawn(function()
	while true do
		task.wait(0.1)
		local now = os.clock()
		if now < calmUntil then
			wave.NextAt = math.max(wave.NextAt, calmUntil)
		end
		workspace:SetAttribute("WaveIn", math.max(0, math.ceil(wave.NextAt - now)))
		workspace:SetAttribute("Calm", math.max(0, math.ceil(calmUntil - now)))
		if not wave.Active and now >= wave.NextAt then
			wave.Active = true
			wave.Front = Config.TrackEnd
			workspace:SetAttribute("WaveActive", true)
			notify(nil, "🌋 LAVA INCOMING! Get to a shelter or your base!", Color3.fromRGB(80, 160, 255))
			local hit: { [Player]: boolean } = {}
			local last = os.clock()
			while wave.Front > 2 do
				task.wait(0.05)
				local t = os.clock()
				wave.Front -= Config.WaveSpeed * (t - last)
				last = t
				waveModel:PivotTo(CFrame.new(0, 28, wave.Front + 15))
				for _, player in Players:GetPlayers() do
					local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if root and not hit[player] and root.Position.Z > wave.Front and root.Position.Z > 0 and not inShelter(root.Position) then
						hit[player] = true
						hitByWave(player)
					end
				end
			end
			waveModel:PivotTo(HIDDEN)
			wave.Active = false
			workspace:SetAttribute("WaveActive", false)
			wave.NextAt = os.clock() + Config.WaveInterval
			-- The lava burns away about a third of the brainrots on the beach.
			for _, m in spawnFolder:GetChildren() do
				if math.random() < 0.35 then
					local zi = m:GetAttribute("Zone") :: number?
					if zi then
						zoneCounts[zi] -= 1
					end
					m:Destroy()
				end
			end
		end
	end
end)

---------------------------------------------------------------- income + deposits

task.spawn(function()
	while true do
		task.wait(1)
		for _, player in Players:GetPlayers() do
			local data = DataService.Get(player)
			if data then
				data.Cash += math.floor(incomeOf(data) * multiplier(player, data))
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root and root.Position.Z < 0 and #(carrying[player] or {}) > 0 then
					deposit(player)
				end
				sync(player)
			end
		end
		workspace:SetAttribute("LuckLeft", math.max(0, math.ceil(luckUntil - os.clock())))
	end
end)

---------------------------------------------------------------- remotes

UpgradeRemote.OnServerInvoke = function(player)
	local data = DataService.Get(player)
	if not data or data.SpeedLevel >= Config.MaxSpeedLevel then
		return false
	end
	local cost = Config.SpeedUpgradeCost(data.SpeedLevel)
	if data.Cash < cost then
		notify(player, "Need $" .. Format.Abbreviate(cost) .. " for the next speed upgrade!", Color3.fromRGB(255, 90, 90))
		return false
	end
	data.Cash -= cost
	data.SpeedLevel += 1
	sync(player)
	applySpeed(player)
	return true
end

RebirthRemote.OnServerInvoke = function(player)
	local data = DataService.Get(player)
	if not data then
		return false
	end
	local cost = Config.RebirthCost(data.Rebirths)
	if data.Cash < cost then
		notify(player, "Rebirth costs $" .. Format.Abbreviate(cost) .. "!", Color3.fromRGB(255, 90, 90))
		return false
	end
	data.Cash = Config.StartingCash
	data.SpeedLevel = 0
	data.Rebirths += 1
	sync(player)
	applySpeed(player)
	notify(nil, player.DisplayName .. " REBIRTHED! (+" .. math.floor(data.Rebirths * Config.RebirthBonus * 100) .. "% cash)", Color3.fromRGB(255, 120, 255))
	return true
end

HomeRemote.OnServerEvent:Connect(function(player)
	local plot = plotOf(player)
	if plot and player.Character then
		player.Character:PivotTo(CFrame.new(plot.Floor.Position + Vector3.new(0, 4, -8)))
	end
end)

---------------------------------------------------------------- players

DataService.ProfileLoaded:Connect(function(player, data)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local cash = Instance.new("NumberValue")
	cash.Name = "Cash"
	cash.Parent = ls
	local reb = Instance.new("IntValue")
	reb.Name = "Rebirths"
	reb.Parent = ls
	ls.Parent = player

	-- Offline earnings
	if data.LastOnline > 0 then
		local away = math.min(os.time() - data.LastOnline, Config.OfflineCapSeconds)
		local earned = math.floor(incomeOf(data) * multiplier(player, data) * away * Config.OfflineRate)
		if earned > 0 then
			data.Cash += earned
			task.delay(3, notify, player, "Welcome back! Your brainrots earned $" .. Format.Abbreviate(earned) .. " while you were away.", Color3.fromRGB(90, 255, 90))
		end
	end
	data.LastOnline = os.time()

	for _, plot in plots do
		if not plot.Owner then
			plot.Owner = player
			renderPlot(plot)
			break
		end
	end
	carrying[player] = {}
	carryModels[player] = {}
	sync(player)
	local function onCharacter(character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		carryModels[player] = {}
		carrying[player] = {}
		player:SetAttribute("Carrying", 0)
		applySpeed(player)
		local plot = plotOf(player)
		if plot then
			task.wait()
			character:PivotTo(CFrame.new(plot.Floor.Position + Vector3.new(0, 4, -8)))
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end)

DataService.ProfileReleasing:Connect(function(player, data)
	data.LastOnline = os.time()
end)

Players.PlayerRemoving:Connect(function(player)
	local plot = plotOf(player)
	if plot then
		plot.Owner = nil
		renderPlot(plot)
	end
	carrying[player] = nil
	carryModels[player] = nil
end)

---------------------------------------------------------------- monetization

local function cashPack(player: Player, data, key: string)
	local pack = Config.CashPacks[key]
	local amount = math.max(pack.Min, math.floor(incomeOf(data) * multiplier(player, data) * pack.Seconds))
	data.Cash += amount
	sync(player)
	notify(player, "+$" .. Format.Abbreviate(amount) .. "!", Color3.fromRGB(90, 255, 90))
	return true
end

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		CashPack = function(player, data)
			return cashPack(player, data, "CashPack")
		end,
		CashVault = function(player, data)
			return cashPack(player, data, "CashVault")
		end,
		ServerLuck = function(player)
			luckUntil = math.max(luckUntil, os.clock()) + Config.ServerLuckTime
			notify(nil, player.DisplayName .. " activated 2x SERVER LUCK!", Color3.fromRGB(255, 215, 0))
			return true
		end,
		StopLava = function(player)
			calmUntil = math.max(calmUntil, os.clock()) + Config.StopLavaTime
			notify(nil, player.DisplayName .. " STOPPED THE LAVA for 5 minutes! Go grab the rare ones!", Color3.fromRGB(90, 255, 200))
			return true
		end,
		SummonSecret = function(player)
			local pool = Config.ByRarity.Secret
			local id = pool[math.random(1, #pool)].Id
			spawnBrainrot(#Config.Zones, id, Config.Zones[#Config.Zones].To - 30)
			notify(nil, player.DisplayName .. " summoned a SECRET " .. Config.ById[id].Name .. " at the far end!", Color3.fromRGB(255, 0, 170))
			return true
		end,
	},
	OnPassOwned = function(player, name)
		applySpeed(player)
		sync(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("EscapeLavaBrainrots_v1", {
	Cash = Config.StartingCash,
	SpeedLevel = 0,
	Rebirths = 0,
	Placed = {},
	LastOnline = 0,
})
