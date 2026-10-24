-- Brainrot Tower Defense server: co-op waves, unit placement/upgrades, summons, rewards.
local HttpService = game:GetService("HttpService")
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
local function remote(className: string, name: string): any
	local r = Instance.new(className)
	r.Name = name
	r.Parent = remotes
	return r
end
local NotifyRemote = remote("RemoteEvent", "Notify")
local ShotRemote = remote("RemoteEvent", "Shot")
local InventoryRemote = remote("RemoteEvent", "Inventory")
local PlaceRemote = remote("RemoteFunction", "Place")
local UpgradeRemote = remote("RemoteFunction", "Upgrade")
local SellRemote = remote("RemoteFunction", "Sell")
local SummonRemote = remote("RemoteFunction", "Summon")
local EquipRemote = remote("RemoteFunction", "Equip")
local StartRemote = remote("RemoteEvent", "Start")
local SpeedRemote = remote("RemoteEvent", "ToggleSpeed")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

---------------------------------------------------------------- map + path

local world = Instance.new("Folder")
world.Name = "World"
world.Parent = workspace
local unitsFolder = Instance.new("Folder")
unitsFolder.Name = "Units"
unitsFolder.Parent = workspace
local enemiesFolder = Instance.new("Folder")
enemiesFolder.Name = "Enemies"
enemiesFolder.Parent = workspace

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

local WAYPOINTS = {
	Vector3.new(-95, 0, -80),
	Vector3.new(60, 0, -80),
	Vector3.new(60, 0, -40),
	Vector3.new(-60, 0, -40),
	Vector3.new(-60, 0, 0),
	Vector3.new(60, 0, 0),
	Vector3.new(60, 0, 40),
	Vector3.new(-60, 0, 40),
	Vector3.new(-60, 0, 80),
	Vector3.new(90, 0, 80),
}
local segLengths = {}
local totalLength = 0
for i = 1, #WAYPOINTS - 1 do
	local len = (WAYPOINTS[i + 1] - WAYPOINTS[i]).Magnitude
	segLengths[i] = len
	totalLength += len
end

local function pointAt(dist: number): (Vector3, Vector3)
	for i, len in segLengths do
		if dist <= len then
			local dir = (WAYPOINTS[i + 1] - WAYPOINTS[i]).Unit
			return WAYPOINTS[i] + dir * dist, dir
		end
		dist -= len
	end
	local n = #WAYPOINTS
	return WAYPOINTS[n], (WAYPOINTS[n] - WAYPOINTS[n - 1]).Unit
end

local function distToPath(p: Vector3): number
	local best = math.huge
	local flat = Vector3.new(p.X, 0, p.Z)
	for i = 1, #WAYPOINTS - 1 do
		local a, b = WAYPOINTS[i], WAYPOINTS[i + 1]
		local ab = b - a
		local t = math.clamp((flat - a):Dot(ab) / ab:Dot(ab), 0, 1)
		best = math.min(best, (flat - (a + ab * t)).Magnitude)
	end
	return best
end

part({ Name = "Ground", Size = Vector3.new(220, 2, 200), Position = Vector3.new(0, -1, 0), Color = Color3.fromRGB(90, 180, 90), Material = Enum.Material.Grass })
for i = 1, #WAYPOINTS - 1 do
	local a, b = WAYPOINTS[i], WAYPOINTS[i + 1]
	part({
		Name = "Path",
		Size = Vector3.new(8, 0.2, (b - a).Magnitude + 8),
		CFrame = CFrame.lookAt((a + b) / 2, b) + Vector3.new(0, 0.05, 0),
		Color = Color3.fromRGB(200, 170, 120),
		Material = Enum.Material.Sand,
		CanCollide = false,
	})
end
part({ Name = "Portal", Size = Vector3.new(2, 14, 12), CFrame = CFrame.new(WAYPOINTS[1] + Vector3.new(-3, 7, 0)), Color = Color3.fromRGB(170, 0, 255), Material = Enum.Material.Neon, Transparency = 0.3, CanCollide = false })
local base = part({ Name = "Base", Size = Vector3.new(14, 16, 14), Position = WAYPOINTS[#WAYPOINTS] + Vector3.new(6, 8, 0), Color = Color3.fromRGB(80, 120, 255), Material = Enum.Material.Brick })
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = Vector3.new(0, 0.5, -60)
spawn.Neutral = true
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Parent = world
do
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 40)
	gui.StudsOffset = Vector3.new(0, 11, 0)
	gui.Parent = base
	local label = Instance.new("TextLabel")
	label.Name = "HP"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Text = "BASE"
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Parent = label
	label.Parent = gui
end

---------------------------------------------------------------- match state

local match = {
	State = "Lobby",
	Wave = 0,
	BaseHealth = Config.BaseHealth,
	StartRequested = false,
	Revived = false,
}
local enemies = {}
local units: { [string]: any } = {}

local function setAttr()
	workspace:SetAttribute("MatchState", match.State)
	workspace:SetAttribute("Wave", match.Wave)
	workspace:SetAttribute("BaseHealth", match.BaseHealth)
	local label = (base:FindFirstChildOfClass("BillboardGui") :: BillboardGui):FindFirstChild("HP") :: TextLabel
	label.Text = "BASE " .. math.max(0, match.BaseHealth) .. "/" .. Config.BaseHealth
end
setAttr()

local function gameSpeed(): number
	return (workspace:GetAttribute("GameSpeed") or 1) :: number
end

local function matchCash(player: Player): number
	return (player:GetAttribute("MatchCash") or 0) :: number
end

local function addMatchCash(player: Player, amount: number)
	player:SetAttribute("MatchCash", math.floor(matchCash(player) + amount))
end

local function syncInventory(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Gems", data.Gems)
	player:SetAttribute("Slots", 4 + (if MonetizationService.OwnsPass(player, "ExtraSlot") then 1 else 0))
	InventoryRemote:FireClient(player, data.Units, data.Equipped)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Gems.Value = data.Gems
		stats["Best Wave"].Value = data.BestWave
	end
end

---------------------------------------------------------------- enemies

local function spawnEnemy(def, healthScale: number)
	local size = def.Size
	local body = part({
		Name = def.Id,
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * size,
		Color = def.Color,
		CanCollide = false,
		CanQuery = false,
	}, enemiesFolder)
	for _, side in { -1, 1 } do
		local eye = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * size * 0.25, Color = Color3.new(1, 1, 1), CanCollide = false, CanQuery = false, Anchored = false, Massless = true }, body)
		eye.CFrame = body.CFrame * CFrame.new(side * size * 0.2, size * 0.15, -size * 0.42)
		local w = Instance.new("WeldConstraint")
		w.Part0 = body
		w.Part1 = eye
		w.Parent = eye
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(80, 10)
	gui.StudsOffset = Vector3.new(0, size / 2 + 1, 0)
	gui.MaxDistance = 120
	gui.Parent = body
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
	back.Parent = gui
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(90, 255, 90)
	fill.BorderSizePixel = 0
	fill.Parent = back
	local startPos, startDir = pointAt(0)
	body.CFrame = CFrame.lookAt(startPos, startPos + startDir) + Vector3.new(0, size / 2, 0)
	local hp = def.Health * healthScale
	local e = { Def = def, Body = body, Health = hp, MaxHealth = hp, Dist = 0, Fill = fill, Boss = def.Id:sub(1, 5) == "boss_" }
	table.insert(enemies, e)
	return e
end

local function killEnemy(e, rewarded: boolean)
	local index = table.find(enemies, e)
	if index then
		table.remove(enemies, index)
	end
	e.Body:Destroy()
	if rewarded then
		for _, player in Players:GetPlayers() do
			addMatchCash(player, e.Def.Reward)
		end
	end
end

local function damageEnemy(e, amount: number)
	if e.Health <= 0 then
		return
	end
	e.Health -= amount
	e.Fill.Size = UDim2.fromScale(math.clamp(e.Health / e.MaxHealth, 0, 1), 1)
	if e.Health <= 0 then
		killEnemy(e, true)
	end
end

---------------------------------------------------------------- units

local function buildUnitModel(unit, level: number, position: Vector3, owner: Player): Model
	local model = Instance.new("Model")
	model.Name = unit.Id
	local pad = part({ Name = "Pad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 4.5, 4.5), CFrame = CFrame.new(position + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Config.RarityColor[unit.Rarity], Material = Enum.Material.Neon }, model)
	local body = part({ Name = "Body", Size = Vector3.new(2.6, 3.4, 2.6), CFrame = CFrame.new(position + Vector3.new(0, 2.3, 0)), Color = unit.Color }, model)
	part({ Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.one * 2.4, CFrame = body.CFrame * CFrame.new(0, 2.6, 0), Color = unit.Color:Lerp(Color3.new(1, 1, 1), 0.2) }, model)
	model.PrimaryPart = pad
	local gui = Instance.new("BillboardGui")
	gui.Name = "Tag"
	gui.Size = UDim2.fromOffset(140, 36)
	gui.StudsOffset = Vector3.new(0, 6.5, 0)
	gui.MaxDistance = 80
	gui.Parent = body
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Config.RarityColor[unit.Rarity]
	label.Text = unit.Name .. " Lv" .. level .. "\n" .. owner.DisplayName
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Parent = label
	label.Parent = gui
	model:SetAttribute("OwnerId", owner.UserId)
	model:SetAttribute("UnitId", unit.Id)
	model:SetAttribute("Level", level)
	model.Parent = unitsFolder
	return model
end

local function placedCount(player: Player): number
	local n = 0
	for _, u in units do
		if u.Owner == player then
			n += 1
		end
	end
	return n
end

PlaceRemote.OnServerInvoke = function(player, unitId, position)
	local data = DataService.Get(player)
	local unit = type(unitId) == "string" and Config.UnitById[unitId]
	if not data or not unit or typeof(position) ~= "Vector3" then
		return false, "Invalid"
	end
	if match.State ~= "Playing" and match.State ~= "Lobby" then
		return false, "Wait for the next match!"
	end
	if not table.find(data.Equipped, unitId) then
		return false, "Equip that unit first!"
	end
	if math.abs(position.X) > 105 or math.abs(position.Z) > 95 then
		return false, "Out of bounds!"
	end
	if distToPath(position) < 6 then
		return false, "Too close to the path!"
	end
	for _, u in units do
		if (u.Position - position).Magnitude < 4.5 then
			return false, "Too close to another unit!"
		end
	end
	if placedCount(player) >= Config.MaxPlacedPerPlayer then
		return false, "Max " .. Config.MaxPlacedPerPlayer .. " units!"
	end
	if matchCash(player) < unit.Cost then
		return false, "Need $" .. unit.Cost .. "!"
	end
	addMatchCash(player, -unit.Cost)
	local id = HttpService:GenerateGUID(false)
	local pos = Vector3.new(position.X, 0, position.Z)
	local model = buildUnitModel(unit, 1, pos, player)
	model:SetAttribute("Uid", id)
	units[id] = { Id = id, Owner = player, Unit = unit, Level = 1, Position = pos, Model = model, NextAttack = 0, Spent = unit.Cost }
	return true
end

UpgradeRemote.OnServerInvoke = function(player, id)
	local u = type(id) == "string" and units[id]
	if not u or u.Owner ~= player then
		return false, "Not your unit"
	end
	if u.Level >= Config.MaxLevel then
		return false, "Max level!"
	end
	local cost = Config.UpgradeCost(u.Unit, u.Level)
	if matchCash(player) < cost then
		return false, "Need $" .. cost .. "!"
	end
	addMatchCash(player, -cost)
	u.Spent += cost
	u.Level += 1
	u.Model:SetAttribute("Level", u.Level)
	local label = u.Model:FindFirstChild("Body") and u.Model.Body.Tag.Label
	if label then
		label.Text = u.Unit.Name .. " Lv" .. u.Level .. "\n" .. player.DisplayName
	end
	return true, "Upgraded to Lv" .. u.Level .. "!"
end

SellRemote.OnServerInvoke = function(player, id)
	local u = type(id) == "string" and units[id]
	if not u or u.Owner ~= player then
		return false, "Not your unit"
	end
	units[id] = nil
	u.Model:Destroy()
	local refund = math.floor(u.Spent * 0.5)
	addMatchCash(player, refund)
	return true, "Sold for $" .. refund
end

local function clearUnits(player: Player?)
	for id, u in units do
		if player == nil or u.Owner == player then
			u.Model:Destroy()
			units[id] = nil
		end
	end
end

---------------------------------------------------------------- summons + equipment

local function rollUnit(player: Player)
	local lucky = MonetizationService.OwnsPass(player, "LuckySummon")
	local total = 0
	for i, r in Config.RarityWeights do
		total += r.Weight * (if lucky and i >= 3 then 2 else 1)
	end
	local roll = math.random() * total
	local rarity = Config.RarityWeights[1].Name
	for i, r in Config.RarityWeights do
		roll -= r.Weight * (if lucky and i >= 3 then 2 else 1)
		if roll <= 0 then
			rarity = r.Name
			break
		end
	end
	local pool = {}
	for _, u in Config.Units do
		if u.Rarity == rarity then
			table.insert(pool, u.Id)
		end
	end
	return pool[math.random(1, #pool)]
end

local function grantUnit(player: Player, data, unitId: string)
	data.Units[unitId] = (data.Units[unitId] or 0) + 1
	local unit = Config.UnitById[unitId]
	if unit.Rarity == "Legendary" or unit.Rarity == "Mythic" then
		notify(nil, player.DisplayName .. " summoned " .. unit.Rarity .. " " .. unit.Name .. "!", Config.RarityColor[unit.Rarity])
	end
end

SummonRemote.OnServerInvoke = function(player, count)
	local data = DataService.Get(player)
	if not data or (count ~= 1 and count ~= 10) then
		return false, "Invalid"
	end
	local cost = Config.SummonCost * count * (if count == 10 then 0.9 else 1)
	if data.Gems < cost then
		return false, "Need " .. cost .. " gems!"
	end
	data.Gems -= cost
	data.Summons += count
	local results = {}
	for _ = 1, count do
		local id = rollUnit(player)
		grantUnit(player, data, id)
		table.insert(results, id)
	end
	syncInventory(player)
	return true, results
end

EquipRemote.OnServerInvoke = function(player, unitId, equip)
	local data = DataService.Get(player)
	if not data or type(unitId) ~= "string" or not data.Units[unitId] then
		return false
	end
	local index = table.find(data.Equipped, unitId)
	if equip and not index then
		if #data.Equipped >= (player:GetAttribute("Slots") or 4) then
			return false, "Slots full! Unequip one first."
		end
		table.insert(data.Equipped, unitId)
	elseif not equip and index then
		table.remove(data.Equipped, index)
	end
	syncInventory(player)
	return true
end

---------------------------------------------------------------- match loop

StartRemote.OnServerEvent:Connect(function()
	if match.State == "Lobby" then
		match.StartRequested = true
	end
end)

SpeedRemote.OnServerEvent:Connect(function(player)
	if MonetizationService.OwnsPass(player, "DoubleSpeed") then
		local speed = if gameSpeed() == 1 then 2 else 1
		workspace:SetAttribute("GameSpeed", speed)
		notify(nil, player.DisplayName .. " set game speed to " .. speed .. "x", Color3.fromRGB(255, 220, 80))
	end
end)

-- Enemy movement + unit attacks
task.spawn(function()
	local last = os.clock()
	while true do
		task.wait(0.05)
		local now = os.clock()
		local dt = (now - last) * gameSpeed()
		last = now
		if match.State ~= "Playing" then
			continue
		end
		for i = #enemies, 1, -1 do
			local e = enemies[i]
			e.Dist += e.Def.Speed * dt
			if e.Dist >= totalLength then
				match.BaseHealth -= if e.Boss then 35 else 5
				killEnemy(e, false)
				setAttr()
			else
				local pos, dir = pointAt(e.Dist)
				e.Body.CFrame = CFrame.lookAt(pos, pos + dir) + Vector3.new(0, e.Def.Size / 2, 0)
			end
		end
		for _, u in units do
			if now < u.NextAttack then
				continue
			end
			local stats = Config.UnitStats(u.Unit, u.Level)
			local target, best = nil, -1
			for _, e in enemies do
				local p = e.Body.Position
				if (Vector3.new(p.X, 0, p.Z) - u.Position).Magnitude <= stats.Range and e.Dist > best then
					target, best = e, e.Dist
				end
			end
			if target then
				u.NextAttack = now + stats.Cooldown / gameSpeed()
				local hitPos = target.Body.Position
				ShotRemote:FireAllClients(u.Position + Vector3.new(0, 4, 0), hitPos, u.Unit.Color, stats.Splash)
				if stats.Splash > 0 then
					for _, e in table.clone(enemies) do
						if (e.Body.Position - hitPos).Magnitude <= stats.Splash then
							damageEnemy(e, stats.Damage)
						end
					end
				else
					damageEnemy(target, stats.Damage)
				end
			end
		end
	end
end)

local function resetMatch()
	for _, e in table.clone(enemies) do
		killEnemy(e, false)
	end
	clearUnits(nil)
	match.Wave = 0
	match.BaseHealth = Config.BaseHealth
	match.Revived = false
	match.StartRequested = false
	workspace:SetAttribute("GameSpeed", 1)
	for _, player in Players:GetPlayers() do
		player:SetAttribute("MatchCash", Config.StartCash)
	end
end

local function reward(won: boolean)
	local cleared = math.max(0, match.Wave - (if won then 0 else 1))
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		if data then
			local gems = cleared * Config.GemsPerWave + (if won then Config.WinBonusGems else 0)
			if MonetizationService.OwnsPass(player, "VIP") then
				gems = math.floor(gems * 1.5)
			end
			data.Gems += gems
			data.BestWave = math.max(data.BestWave, cleared)
			if won then
				data.Wins += 1
			end
			syncInventory(player)
			notify(player, "+" .. gems .. " gems! (cleared " .. cleared .. " waves)", Color3.fromRGB(120, 200, 255))
		end
	end
end

task.spawn(function()
	resetMatch()
	while true do
		-- Lobby: place units, then start (button or timer).
		match.State = "Lobby"
		setAttr()
		local deadline = os.clock() + Config.AutoStartSeconds
		while not match.StartRequested and (os.clock() < deadline or #Players:GetPlayers() == 0) do
			workspace:SetAttribute("StartIn", math.max(0, math.ceil(deadline - os.clock())))
			if #Players:GetPlayers() == 0 then
				deadline = os.clock() + Config.AutoStartSeconds
			end
			task.wait(0.25)
		end
		match.State = "Playing"
		local won = false
		while true do
			match.Wave += 1
			setAttr()
			notify(nil, "WAVE " .. match.Wave .. (if match.Wave % 5 == 0 then " — BOSS INCOMING!" else ""), Color3.fromRGB(255, 220, 80))
			local scale = Config.HealthScale(match.Wave)
			local count = Config.WaveSize(match.Wave)
			for i = 1, count do
				if match.BaseHealth <= 0 then
					break
				end
				local def = Config.Enemies[math.random(1, math.min(#Config.Enemies, 1 + math.floor(match.Wave / 3)))]
				spawnEnemy(def, scale)
				task.wait(0.9 / gameSpeed())
				if i == count and match.Wave % 5 == 0 then
					local boss = Config.Bosses[math.min(#Config.Bosses, match.Wave // 5)]
					spawnEnemy(boss, 1 + (match.Wave / 5 - 1) * 0.6)
				end
			end
			while #enemies > 0 and match.BaseHealth > 0 do
				task.wait(0.2)
			end
			if match.BaseHealth <= 0 then
				-- Offer a revive window before ending.
				match.State = "Defeat"
				setAttr()
				notify(nil, "The base fell! Anyone can REVIVE it in the next 15s!", Color3.fromRGB(255, 90, 90))
				local reviveDeadline = os.clock() + 15
				while os.clock() < reviveDeadline and match.BaseHealth <= 0 do
					workspace:SetAttribute("ReviveIn", math.ceil(reviveDeadline - os.clock()))
					task.wait(0.25)
				end
				if match.BaseHealth > 0 then
					match.State = "Playing"
					setAttr()
					continue
				end
				break
			end
			if match.Wave >= Config.WinWave then
				won = true
				break
			end
			for _, player in Players:GetPlayers() do
				addMatchCash(player, 100 + match.Wave * 25)
			end
			task.wait(Config.WaveGap / gameSpeed())
		end
		match.State = if won then "Victory" else "GameOver"
		setAttr()
		notify(nil, if won then "VICTORY! You defended against " .. Config.WinWave .. " waves!" else "Game over at wave " .. match.Wave, if won then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(255, 90, 90))
		reward(won)
		task.wait(8)
		resetMatch()
	end
end)

---------------------------------------------------------------- players

DataService.ProfileLoaded:Connect(function(player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local gems = Instance.new("IntValue")
	gems.Name = "Gems"
	gems.Parent = stats
	local best = Instance.new("IntValue")
	best.Name = "Best Wave"
	best.Parent = stats
	stats.Parent = player
	if data.LoginCount == 1 then
		data.Units.noobini = 1
		data.Units.tung = 1
		data.Equipped = { "noobini", "tung" }
	end
	for id in data.Units do
		if not Config.UnitById[id] then
			data.Units[id] = nil
		end
	end
	for i = #data.Equipped, 1, -1 do
		if not data.Units[data.Equipped[i]] then
			table.remove(data.Equipped, i)
		end
	end
	player:SetAttribute("MatchCash", Config.StartCash)
	syncInventory(player)
end)

Players.PlayerRemoving:Connect(function(player)
	clearUnits(player)
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		GemsSmall = function(player, data)
			data.Gems += 500
			syncInventory(player)
			return true
		end,
		GemsLarge = function(player, data)
			data.Gems += 2500
			syncInventory(player)
			return true
		end,
		ReviveBase = function(player, data)
			if match.State == "Defeat" or match.State == "Playing" then
				match.BaseHealth = Config.BaseHealth
				setAttr()
				notify(nil, player.DisplayName .. " REVIVED THE BASE!", Color3.fromRGB(90, 255, 90))
			else
				-- No match to revive: refund as gems so the purchase is never wasted.
				data.Gems += 200
				syncInventory(player)
				notify(player, "No base to revive right now — you got 200 gems instead!", Color3.fromRGB(120, 200, 255))
			end
			return true
		end,
		StarterPack = function(player, data)
			local pool = {}
			for _, u in Config.Units do
				if u.Rarity == "Mythic" then
					table.insert(pool, u.Id)
				end
			end
			grantUnit(player, data, pool[math.random(1, #pool)])
			syncInventory(player)
			return true
		end,
	},
	OnPassOwned = function(player, name)
		syncInventory(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("BrainrotTD_v1", {
	Gems = Config.StartGems,
	Units = {},
	Equipped = {},
	Wins = 0,
	BestWave = 0,
	Summons = 0,
})
