-- Pet Breakers server: areas + gates, breakables, pet damage loop, eggs, inventory, boosts.
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

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
local TargetRemote = remote("RemoteEvent", "Target")
local CoinPopRemote = remote("RemoteEvent", "CoinPop")
local HatchRemote = remote("RemoteFunction", "Hatch")
local InventoryRemote = remote("RemoteEvent", "Inventory")
local EquipRemote = remote("RemoteFunction", "Equip")
local DeleteRemote = remote("RemoteFunction", "Delete")
local UnlockRemote = remote("RemoteFunction", "Unlock")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

---------------------------------------------------------------- world

local L = Config.AreaLength
local world = Instance.new("Folder")
world.Name = "World"
world.Parent = workspace
local breakFolder = Instance.new("Folder")
breakFolder.Name = "Breakables"
breakFolder.Parent = workspace
local eggFolder = Instance.new("Folder")
eggFolder.Name = "Eggs"
eggFolder.Parent = workspace

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
local function billboard(adornee: BasePart, text: string, offset: number, color: Color3?): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(240, 70)
	gui.StudsOffset = Vector3.new(0, offset, 0)
	gui.MaxDistance = 100
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Parent = label
	label.Parent = gui
	return label
end

local function areaCenter(i: number): Vector3
	return Vector3.new(0, 0, (i - 1) * L)
end

local gates = {}
for i, area in Config.Areas do
	local c = areaCenter(i)
	part({ Name = "Area" .. i, Size = Vector3.new(80, 2, L), Position = c - Vector3.new(0, 1, 0), Color = area.Color, Material = if i == 5 then Enum.Material.Basalt else Enum.Material.Grass })
	for _, sx in { -1, 1 } do
		part({ Size = Vector3.new(2, 10, L), Position = c + Vector3.new(sx * 41, 5, 0), Color = area.Color:Lerp(Color3.new(0, 0, 0), 0.3), Transparency = 0.5 })
	end
	local sign = part({ Size = Vector3.new(1, 1, 1), Position = c + Vector3.new(0, 10, -L / 2 + 4), Transparency = 1, CanCollide = false })
	billboard(sign, area.Name, 0, Color3.new(1, 1, 1))
	if i > 1 then
		local gate = part({ Name = "Gate" .. i, Size = Vector3.new(80, 14, 2), Position = c + Vector3.new(0, 7, -L / 2), Color = Color3.fromRGB(255, 80, 80), Material = Enum.Material.ForceField, Transparency = 0.3 })
		billboard(gate, "🔒 " .. area.Name .. "\n" .. Format.Abbreviate(area.Unlock) .. " coins", 0)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "UnlockPrompt"
		prompt.ActionText = "Unlock (" .. Format.Abbreviate(area.Unlock) .. ")"
		prompt.ObjectText = area.Name
		prompt.MaxActivationDistance = 16
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Area", i)
		prompt.Parent = gate
		gates[i] = gate
	end
	-- Egg stand on the left side of each area
	local stand = Instance.new("Model")
	stand.Name = "Egg" .. i
	stand:SetAttribute("Area", i)
	stand.Parent = eggFolder
	local pedestal = part({ Name = "Pedestal", Size = Vector3.new(10, 3, 10), Position = c + Vector3.new(-30, 1.5, -L / 2 + 12), Color = Color3.fromRGB(70, 70, 90), Material = Enum.Material.Slate }, stand)
	local egg = part({ Name = "Egg", Size = Vector3.new(6, 8, 6), Position = pedestal.Position + Vector3.new(0, 5.5, 0), Color = area.Color:Lerp(Color3.new(1, 1, 1), 0.4) }, stand)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = egg
	stand.PrimaryPart = pedestal
	billboard(egg, area.Name .. " Egg\n" .. Format.Abbreviate(area.Egg.Cost) .. " coins", 7)
	for _, spec in { { "Hatch1", "Hatch x1", Enum.KeyCode.E, 1 }, { "Hatch3", "Hatch x3", Enum.KeyCode.R, 3 } } do
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = spec[1]
		prompt.ActionText = spec[2]
		prompt.ObjectText = area.Name .. " Egg"
		prompt.KeyboardKeyCode = spec[3]
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Count", spec[4])
		prompt:SetAttribute("Area", i)
		prompt.Parent = pedestal
	end
end
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = Vector3.new(0, 0.5, -L / 2 + 10)
spawn.Neutral = true
spawn.Color = Color3.fromRGB(255, 215, 0)
spawn.Material = Enum.Material.Neon
spawn.Parent = world

---------------------------------------------------------------- breakables

local breakables: { [BasePart]: any } = {}

local function rollBreakable()
	local total = 0
	for _, b in Config.Breakables do
		total += b.Weight
	end
	local r = math.random() * total
	for _, b in Config.Breakables do
		r -= b.Weight
		if r <= 0 then
			return b
		end
	end
	return Config.Breakables[1]
end

local function spawnBreakable(areaIndex: number)
	local def = rollBreakable()
	local area = Config.Areas[areaIndex]
	local c = areaCenter(areaIndex)
	local pos = c + Vector3.new(math.random(-34, 34), def.Size / 2, math.random(-L / 2 + 22, L / 2 - 6))
	local p = part({
		Name = def.Id,
		Size = Vector3.new(def.Size, def.Size * (if def.Id == "chest" or def.Id == "giant" then 0.75 else 0.5), def.Size),
		Position = pos,
		Color = def.Color,
		Material = if def.Id == "chest" or def.Id == "giant" then Enum.Material.WoodPlanks else Enum.Material.Neon,
	}, breakFolder)
	if def.Id == "coins" or def.Id == "bigcoins" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	else
		part({ Size = Vector3.new(def.Size + 0.1, 0.3, def.Size * 0.3), Position = pos + Vector3.new(0, def.Size * 0.3, -def.Size * 0.2), Color = Color3.fromRGB(255, 215, 0), Material = Enum.Material.Metal, CanCollide = false }, p)
	end
	local hp = def.Health * area.Mult
	local label = billboard(p, Format.Abbreviate(hp), def.Size * 0.5 + 1.5, Color3.fromRGB(120, 255, 120))
	local labelGui = label.Parent :: BillboardGui
	labelGui.Size = UDim2.fromOffset(120, 30)
	p:SetAttribute("Area", areaIndex)
	breakables[p] = { Def = def, Area = areaIndex, Health = hp, MaxHealth = hp, Label = label }
end

for i in Config.Areas do
	for _ = 1, Config.BreakablesPerArea do
		spawnBreakable(i)
	end
end

---------------------------------------------------------------- players

local targets: { [Player]: BasePart } = {}

local function equipLimit(player: Player): number
	return Config.BaseEquips + (if MonetizationService.OwnsPass(player, "MoreEquips") then Config.ExtraEquips else 0)
end

local function coinMult(player: Player): number
	local m = 1
	if MonetizationService.OwnsPass(player, "DoubleCoins") then
		m *= 2
	end
	if (workspace:GetAttribute("ServerCoinsUntil") or 0) > os.time() then
		m *= 2
	end
	return m
end

local function teamPower(data): number
	local total = 0
	for _, pet in data.Pets do
		if pet.Eq then
			total += Config.PetPower(pet)
		end
	end
	return total
end

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("Unlocked", data.Unlocked)
	player:SetAttribute("Power", teamPower(data))
	player:SetAttribute("EquipLimit", equipLimit(player))
	local eq = {}
	for _, pet in data.Pets do
		if pet.Eq then
			table.insert(eq, pet.Id .. ":" .. (pet.V or "normal") .. ":" .. (if pet.Huge then "1" else "0"))
		end
	end
	player:SetAttribute("Equipped", table.concat(eq, ","))
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Coins.Value = Format.Abbreviate(data.Coins)
	end
end

local function sendInventory(player: Player)
	local data = DataService.Get(player)
	if data then
		InventoryRemote:FireClient(player, data.Pets)
	end
	sync(player)
end

local function equipBest(player: Player, data)
	local list = {}
	for uid, pet in data.Pets do
		pet.Eq = false
		table.insert(list, { uid = uid, power = Config.PetPower(pet) })
	end
	table.sort(list, function(a, b)
		return a.power > b.power
	end)
	for i = 1, math.min(equipLimit(player), #list) do
		data.Pets[list[i].uid].Eq = true
	end
end

local function petCount(data): number
	local n = 0
	for _ in data.Pets do
		n += 1
	end
	return n
end

local function rollPet(player: Player, chances, luckMult: number)
	local total = 0
	for _, w in chances do
		total += w
	end
	local r = math.random() * total
	local id
	for petId, w in chances do
		r -= w
		id = petId
		if r <= 0 then
			break
		end
	end
	local luck = luckMult * (if MonetizationService.OwnsPass(player, "Lucky") then 2 else 1) * (if (workspace:GetAttribute("ServerLuckUntil") or 0) > os.time() then 2 else 1)
	local variant = "normal"
	local v = math.random()
	if v < Config.RainbowChance * luck then
		variant = "rainbow"
	elseif v < (Config.RainbowChance + Config.GoldenChance) * luck then
		variant = "golden"
	end
	local huge = math.random() < Config.HugeChance * luck
	return { Id = id, V = variant, Huge = huge or nil, Eq = false }
end

local function givePet(player: Player, data, pet)
	data.Pets[HttpService:GenerateGUID(false)] = pet
	data.Hatched += 1
	local info = Config.PetById[pet.Id]
	if pet.Huge then
		notify(nil, "🌟 " .. player.DisplayName .. " HATCHED A HUGE " .. string.upper(info.Name) .. "! 🌟", Color3.fromRGB(255, 215, 0))
	elseif pet.V == "rainbow" or info.Rarity == "Mythic" then
		notify(nil, player.DisplayName .. " hatched a " .. (if pet.V == "rainbow" then "Rainbow " else "") .. info.Name .. "!", Config.Rarities[info.Rarity])
	end
end

HatchRemote.OnServerInvoke = function(player, areaIndex, count)
	local data = DataService.Get(player)
	local area = type(areaIndex) == "number" and Config.Areas[areaIndex]
	if not data or not area or (count ~= 1 and count ~= 3) then
		return false, "Invalid"
	end
	if areaIndex > data.Unlocked then
		return false, "Unlock " .. area.Name .. " first!"
	end
	if count == 3 and not MonetizationService.OwnsPass(player, "TripleHatch") then
		return false, "NeedTriple"
	end
	local stand = eggFolder:FindFirstChild("Egg" .. areaIndex)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not stand or not root or (stand:GetPivot().Position - root.Position).Magnitude > 25 then
		return false, "Get closer to the egg!"
	end
	local cost = area.Egg.Cost * count
	if data.Coins < cost then
		return false, "Need " .. Format.Abbreviate(cost) .. " coins!"
	end
	if petCount(data) + count > Config.Storage then
		return false, "Pet storage full! Delete some pets."
	end
	data.Coins -= cost
	local results = {}
	for _ = 1, count do
		local pet = rollPet(player, area.Egg.Chances, 1)
		givePet(player, data, pet)
		table.insert(results, pet)
	end
	if data.AutoEquip then
		equipBest(player, data)
	end
	sendInventory(player)
	return true, results
end

EquipRemote.OnServerInvoke = function(player, uid, equip)
	local data = DataService.Get(player)
	if not data then
		return false
	end
	if uid == "BEST" then
		equipBest(player, data)
		sendInventory(player)
		return true
	end
	local pet = type(uid) == "string" and data.Pets[uid]
	if not pet then
		return false
	end
	if equip then
		local n = 0
		for _, p in data.Pets do
			if p.Eq then
				n += 1
			end
		end
		if n >= equipLimit(player) then
			return false, "Equip limit reached!"
		end
	end
	pet.Eq = equip == true
	sendInventory(player)
	return true
end

DeleteRemote.OnServerInvoke = function(player, uid)
	local data = DataService.Get(player)
	if data and type(uid) == "string" and data.Pets[uid] then
		data.Pets[uid] = nil
		sendInventory(player)
		return true
	end
	return false
end

local function tryUnlock(player: Player, areaIndex: number): (boolean, string)
	local data = DataService.Get(player)
	local area = Config.Areas[areaIndex]
	if not data or not area then
		return false, "Invalid"
	end
	if areaIndex <= data.Unlocked then
		return true, "Already unlocked"
	end
	if areaIndex ~= data.Unlocked + 1 then
		return false, "Unlock the areas in order!"
	end
	if data.Coins < area.Unlock then
		return false, "Need " .. Format.Abbreviate(area.Unlock) .. " coins!"
	end
	data.Coins -= area.Unlock
	data.Unlocked = areaIndex
	sync(player)
	notify(nil, player.DisplayName .. " unlocked " .. area.Name .. "!", Color3.fromRGB(120, 255, 120))
	return true, "Unlocked " .. area.Name .. "!"
end
UnlockRemote.OnServerInvoke = function(player, areaIndex)
	if type(areaIndex) ~= "number" then
		return false, "Invalid"
	end
	return tryUnlock(player, areaIndex)
end
for i, gate in gates do
	local prompt = gate:FindFirstChild("UnlockPrompt") :: ProximityPrompt
	prompt.Triggered:Connect(function(player)
		local ok, msg = tryUnlock(player, i)
		notify(player, msg, if ok then Color3.fromRGB(120, 255, 120) else Color3.fromRGB(255, 90, 90))
	end)
end

TargetRemote.OnServerEvent:Connect(function(player, target)
	if typeof(target) == "Instance" and breakables[target :: any] then
		targets[player] = target :: BasePart
		player:SetAttribute("TargetId", (target :: BasePart):GetDebugId())
	elseif target == nil then
		targets[player] = nil
	end
end)

---------------------------------------------------------------- damage loop

local function nearestBreakable(root: BasePart, maxArea: number): BasePart?
	local best, bestDist = nil, 45
	for p, b in breakables do
		if b.Area <= maxArea then
			local d = (p.Position - root.Position).Magnitude
			if d < bestDist then
				best, bestDist = p, d
			end
		end
	end
	return best
end

task.spawn(function()
	while true do
		task.wait(0.5)
		for _, player in Players:GetPlayers() do
			local data = DataService.Get(player)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not data or not root then
				continue
			end
			local target = targets[player]
			if target and (not breakables[target] or (target.Position - root.Position).Magnitude > 70) then
				target = nil
				targets[player] = nil
			end
			if not target and MonetizationService.OwnsPass(player, "AutoFarm") and player:GetAttribute("AutoFarmOn") ~= false then
				target = nearestBreakable(root, data.Unlocked)
				targets[player] = target
			end
			player:SetAttribute("TargetPos", if target then target.Position else nil)
			if not target then
				continue
			end
			local b = breakables[target]
			if b.Area > data.Unlocked then
				targets[player] = nil
				continue
			end
			local power = teamPower(data)
			if power <= 0 then
				continue
			end
			b.Health -= power * 0.5
			b.Label.Text = Format.Abbreviate(math.max(0, b.Health))
			if b.Health <= 0 then
				breakables[target] = nil
				local coins = math.floor(b.Def.Coins * Config.Areas[b.Area].Mult * coinMult(player))
				-- Everyone who was hitting it gets the coins (cooperative, like Pet Sim).
				for other, t in targets do
					if t == target then
						local od = DataService.Get(other)
						if od then
							od.Coins += coins
							od.TotalCoins += coins
							sync(other)
							CoinPopRemote:FireClient(other, target.Position, coins)
						end
						targets[other] = nil
					end
				end
				local areaIndex = b.Area
				target:Destroy()
				task.delay(math.random(3, 8), spawnBreakable, areaIndex)
			end
		end
	end
end)

remote("RemoteEvent", "ToggleAutoFarm").OnServerEvent:Connect(function(player)
	player:SetAttribute("AutoFarmOn", player:GetAttribute("AutoFarmOn") == false)
end)

-- Keep players out of locked areas: push them back to their last unlocked area.
task.spawn(function()
	while true do
		task.wait(0.3)
		for _, player in Players:GetPlayers() do
			local data = DataService.Get(player)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if data and root then
				local limitZ = areaCenter(data.Unlocked).Z + L / 2 - 2
				if root.Position.Z > limitZ then
					player.Character:PivotTo(CFrame.new(root.Position.X, root.Position.Y + 1, limitZ - 6))
				end
			end
		end
	end
end)

---------------------------------------------------------------- players + monetization

DataService.ProfileLoaded:Connect(function(player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local coins = Instance.new("StringValue")
	coins.Name = "Coins"
	coins.Parent = stats
	stats.Parent = player
	if data.LoginCount == 1 then
		data.Pets[HttpService:GenerateGUID(false)] = { Id = "pet_dog", V = "normal", Eq = true }
		data.Pets[HttpService:GenerateGUID(false)] = { Id = "pet_cat", V = "normal", Eq = true }
	end
	for uid, pet in data.Pets do
		if not Config.PetById[pet.Id] then
			data.Pets[uid] = nil
		end
	end
	sendInventory(player)
end)

Players.PlayerRemoving:Connect(function(player)
	targets[player] = nil
end)

local function coinPack(seconds: number, min: number)
	return function(player, data)
		-- Estimate income from the player's best area and team power.
		local area = Config.Areas[data.Unlocked]
		local perSecond = teamPower(data) * 0.5 * area.Mult
		local amount = math.max(min, math.floor(perSecond * seconds))
		data.Coins += amount
		sync(player)
		notify(player, "+" .. Format.Abbreviate(amount) .. " coins!", Color3.fromRGB(255, 215, 0))
		return true
	end
end

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		ExclusiveEgg = function(player, data)
			local pet = rollPet(player, Config.ExclusiveEgg, 1)
			if math.random() < 1 / 50 then
				pet.Huge = true
			end
			givePet(player, data, pet)
			if data.AutoEquip then
				equipBest(player, data)
			end
			sendInventory(player)
			notify(player, "Exclusive Egg: " .. (if pet.Huge then "HUGE " else "") .. Config.PetById[pet.Id].Name .. "!", Color3.fromRGB(255, 215, 0))
			return true
		end,
		CoinsSmall = coinPack(1200, 500),
		CoinsLarge = coinPack(3 * 3600, 20_000),
		ServerLuck = function(player)
			workspace:SetAttribute("ServerLuckUntil", math.max(workspace:GetAttribute("ServerLuckUntil") or 0, os.time()) + 900)
			notify(nil, player.DisplayName .. " activated 2x SERVER LUCK!", Color3.fromRGB(0, 255, 200))
			return true
		end,
		ServerCoins = function(player)
			workspace:SetAttribute("ServerCoinsUntil", math.max(workspace:GetAttribute("ServerCoinsUntil") or 0, os.time()) + 900)
			notify(nil, player.DisplayName .. " activated 2x SERVER COINS!", Color3.fromRGB(255, 215, 0))
			return true
		end,
	},
	OnPassOwned = function(player, name)
		sendInventory(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("PetBreakers_v1", {
	Coins = 0,
	TotalCoins = 0,
	Unlocked = 1,
	Pets = {},
	AutoEquip = true,
	Hatched = 0,
})
