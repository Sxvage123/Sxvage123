-- Hatch a Brainrot server: clicking, eggs, pets, rebirths, gifts, purchases.
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)

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
local ClickRemote = remote("RemoteEvent", "Click")
local HatchRemote = remote("RemoteFunction", "Hatch")
local InventoryRemote = remote("RemoteEvent", "Inventory")
local EquipRemote = remote("RemoteFunction", "Equip")
local DeleteRemote = remote("RemoteFunction", "Delete")
local RebirthRemote = remote("RemoteFunction", "Rebirth")
local GiftRemote = remote("RemoteFunction", "ClaimGift")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

---------------------------------------------------------------- world

local function buildWorld()
	Lighting.ClockTime = 15
	Lighting.Brightness = 2.5
	local world = Instance.new("Folder")
	world.Name = "World"
	world.Parent = workspace
	local function part(props)
		local p = Instance.new("Part")
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth
		for k, v in props do
			(p :: any)[k] = v
		end
		p.Parent = world
		return p
	end
	part({ Name = "Island", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 260, 260), CFrame = CFrame.new(0, -2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(110, 210, 110), Material = Enum.Material.Grass })
	part({ Name = "Water", Size = Vector3.new(2000, 1, 2000), Position = Vector3.new(0, -5, 0), Color = Color3.fromRGB(60, 150, 255), Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false })
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.Position = Vector3.new(0, 0.5, 40)
	spawn.Color = Color3.fromRGB(255, 220, 90)
	spawn.Material = Enum.Material.Neon
	spawn.Neutral = true
	spawn.Parent = world

	local eggFolder = Instance.new("Folder")
	eggFolder.Name = "Eggs"
	eggFolder.Parent = workspace
	for i, egg in Config.Eggs do
		local angle = math.rad(-60 + (i - 1) * 30)
		local pos = Vector3.new(math.sin(angle) * 70, 0, -math.cos(angle) * 70)
		local base = CFrame.lookAt(pos, Vector3.new(0, 0, 0))
		local stand = Instance.new("Model")
		stand.Name = egg.Id
		stand:SetAttribute("EggId", egg.Id)
		stand.Parent = eggFolder
		local pedestal = part({ Name = "Pedestal", Size = Vector3.new(12, 3, 12), CFrame = base * CFrame.new(0, 1.5, 0), Color = Color3.fromRGB(70, 70, 90), Material = Enum.Material.Slate })
		pedestal.Parent = stand
		local eggPart = part({ Name = "Egg", Shape = Enum.PartType.Ball, Size = Vector3.new(7, 9, 7), CFrame = base * CFrame.new(0, 7.5, 0), Color = egg.Color, Material = Enum.Material.SmoothPlastic })
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = eggPart
		eggPart.Parent = stand
		stand.PrimaryPart = pedestal

		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(240, 90)
		gui.StudsOffset = Vector3.new(0, 8, 0)
		gui.MaxDistance = 80
		gui.Parent = eggPart
		local function line(text, color, y, h)
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Font = Enum.Font.FredokaOne
			l.TextScaled = true
			l.TextColor3 = color
			l.Size = UDim2.new(1, 0, 0, h)
			l.Position = UDim2.fromOffset(0, y)
			l.Text = text
			local s = Instance.new("UIStroke")
			s.Thickness = 3
			s.Parent = l
			l.Parent = gui
		end
		line(egg.Name, Color3.new(1, 1, 1), 0, 44)
		line(Format.Abbreviate(egg.Cost) .. " Brainpower", Color3.fromRGB(255, 120, 255), 46, 40)

		for _, spec in { { "Hatch1", "Hatch x1", Enum.KeyCode.E, 1 }, { "Hatch3", "Hatch x3", Enum.KeyCode.R, 3 } } do
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = spec[1]
			prompt.ActionText = spec[2]
			prompt.ObjectText = egg.Name
			prompt.KeyboardKeyCode = spec[3]
			prompt.MaxActivationDistance = 14
			prompt.RequiresLineOfSight = false
			prompt:SetAttribute("Count", spec[4])
			prompt.Parent = pedestal
		end
	end
end
buildWorld()

---------------------------------------------------------------- stats

local clickBudget: { [Player]: number } = {}

local function luck(player: Player): number
	local l = 1
	if MonetizationService.OwnsPass(player, "Lucky") then
		l *= 1.5
	end
	local data = DataService.Get(player)
	if data and data.BoostUntil > os.time() then
		l *= data.BoostLuck
	end
	return l
end

local function equipLimit(player: Player): number
	return Config.BaseEquips + (if MonetizationService.OwnsPass(player, "MoreEquips") then Config.ExtraEquips else 0)
end

local function storageLimit(player: Player): number
	return Config.BaseStorage + (if MonetizationService.OwnsPass(player, "MoreStorage") then Config.ExtraStorage else 0)
end

local function petCount(data): number
	local n = 0
	for _ in data.Pets do
		n += 1
	end
	return n
end

local function clickPower(player: Player): number
	local data = DataService.Get(player)
	if not data then
		return 0
	end
	local petBonus = 0
	for _, pet in data.Pets do
		if pet.Equipped then
			local info = Config.PetById[pet.Id]
			petBonus += info and info.Multiplier or 0
		end
	end
	local power = (1 + petBonus) * (1 + data.Rebirths * Config.RebirthBonus)
	if MonetizationService.OwnsPass(player, "DoubleClicks") then
		power *= 2
	end
	return power
end

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local power = clickPower(player)
	player:SetAttribute("Brainpower", data.Brainpower)
	player:SetAttribute("ClickPower", power)
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("Luck", luck(player))
	player:SetAttribute("BoostUntil", data.BoostUntil)
	player:SetAttribute("NextGift", data.NextGift)
	player:SetAttribute("EquipLimit", equipLimit(player))
	player:SetAttribute("StorageLimit", storageLimit(player))
	local equipped = {}
	for _, pet in data.Pets do
		if pet.Equipped then
			table.insert(equipped, pet.Id)
		end
	end
	player:SetAttribute("Equipped", table.concat(equipped, ","))
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Brainpower.Value = Format.Abbreviate(data.Brainpower)
		stats.Rebirths.Value = data.Rebirths
	end
end

local function sendInventory(player: Player)
	local data = DataService.Get(player)
	if data then
		InventoryRemote:FireClient(player, data.Pets)
	end
	sync(player)
end

local function addPower(player: Player, amount: number)
	local data = DataService.Get(player)
	if not data then
		return
	end
	data.Brainpower += amount
	if amount > 0 then
		data.TotalPower += amount
	end
	player:SetAttribute("Brainpower", data.Brainpower)
end

---------------------------------------------------------------- pets

local function roll(chances: { [string]: number }, luckMult: number): string
	local total = 0
	for id, weight in chances do
		local info = Config.PetById[id]
		total += weight * (if Config.LuckyRarities[info.Rarity] then luckMult else 1)
	end
	local r = math.random() * total
	local last
	for id, weight in chances do
		local info = Config.PetById[id]
		r -= weight * (if Config.LuckyRarities[info.Rarity] then luckMult else 1)
		last = id
		if r <= 0 then
			return id
		end
	end
	return last
end

local function equipBest(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local list = {}
	for uid, pet in data.Pets do
		pet.Equipped = false
		table.insert(list, { uid = uid, mult = Config.PetById[pet.Id].Multiplier })
	end
	table.sort(list, function(a, b)
		return a.mult > b.mult
	end)
	for i = 1, math.min(equipLimit(player), #list) do
		data.Pets[list[i].uid].Equipped = true
	end
end

local function givePet(player: Player, petId: string): string?
	local data = DataService.Get(player)
	if not data then
		return nil
	end
	local uid = HttpService:GenerateGUID(false)
	data.Pets[uid] = { Id = petId, Equipped = false }
	data.Index[petId] = true
	local info = Config.PetById[petId]
	if Config.RarityRank(info.Rarity) >= Config.RarityRank("Legendary") then
		notify(nil, player.DisplayName .. " hatched a " .. info.Rarity .. " " .. info.Name .. "!", Config.Rarities[info.Rarity])
	end
	return uid
end

local function autoEquipIfBetter(player: Player)
	local data = DataService.Get(player)
	if data and data.AutoEquip then
		equipBest(player)
	end
end

HatchRemote.OnServerInvoke = function(player, eggId, count)
	local data = DataService.Get(player)
	local egg = Config.EggById[eggId]
	if not data or not egg or (count ~= 1 and count ~= 3) then
		return false, "Invalid egg"
	end
	if count == 3 and not MonetizationService.OwnsPass(player, "TripleHatch") then
		return false, "NeedTriple"
	end
	-- Egg proximity check stops exploiters hatching from anywhere.
	local stand = workspace.Eggs:FindFirstChild(eggId)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not stand or not root or (stand:GetPivot().Position - root.Position).Magnitude > 25 then
		return false, "Get closer to the egg!"
	end
	local cost = egg.Cost * count
	if data.Brainpower < cost then
		return false, "Need " .. Format.Abbreviate(cost) .. " Brainpower!"
	end
	if petCount(data) + count > storageLimit(player) then
		return false, "Pet storage full! Delete some pets."
	end
	addPower(player, -cost)
	local results = {}
	local l = luck(player)
	for _ = 1, count do
		local id = roll(egg.Chances, l)
		givePet(player, id)
		table.insert(results, id)
	end
	data.Hatches += count
	autoEquipIfBetter(player)
	sendInventory(player)
	return true, results
end

EquipRemote.OnServerInvoke = function(player, uid, equip)
	local data = DataService.Get(player)
	if not data then
		return false
	end
	if uid == "BEST" then
		equipBest(player)
		sendInventory(player)
		return true
	end
	if uid == "AUTO" then
		data.AutoEquip = equip == true
		return true
	end
	local pet = type(uid) == "string" and data.Pets[uid]
	if not pet then
		return false
	end
	if equip then
		local n = 0
		for _, p in data.Pets do
			if p.Equipped then
				n += 1
			end
		end
		if n >= equipLimit(player) then
			notify(player, "Equip limit reached! Get +3 Equips.", Color3.fromRGB(255, 90, 90))
			return false
		end
	end
	pet.Equipped = equip == true
	sendInventory(player)
	return true
end

DeleteRemote.OnServerInvoke = function(player, uids)
	local data = DataService.Get(player)
	if not data or type(uids) ~= "table" then
		return false
	end
	for _, uid in uids do
		if type(uid) == "string" then
			data.Pets[uid] = nil
		end
	end
	sendInventory(player)
	return true
end

---------------------------------------------------------------- clicking, rebirth, gifts

ClickRemote.OnServerEvent:Connect(function(player)
	local budget = clickBudget[player]
	if not budget or budget <= 0 then
		return
	end
	clickBudget[player] = budget - 1
	addPower(player, clickPower(player))
end)

RebirthRemote.OnServerInvoke = function(player)
	local data = DataService.Get(player)
	if not data then
		return false, "Loading..."
	end
	local cost = Config.RebirthCost(data.Rebirths)
	if data.Brainpower < cost then
		return false, "Need " .. Format.Abbreviate(cost) .. " Brainpower!"
	end
	data.Brainpower = 0
	data.Rebirths += 1
	sync(player)
	notify(nil, player.DisplayName .. " reached Rebirth " .. data.Rebirths .. "!", Color3.fromRGB(255, 215, 0))
	return true, "Rebirth! Now " .. (1 + data.Rebirths * Config.RebirthBonus) .. "x Brainpower forever."
end

GiftRemote.OnServerInvoke = function(player)
	local data = DataService.Get(player)
	if not data or os.time() < data.NextGift then
		return false, "Not ready yet!"
	end
	data.NextGift = os.time() + Config.GiftEverySeconds
	data.GiftStreak += 1
	local reward
	if data.GiftStreak % 6 == 0 then
		data.BoostUntil = math.max(data.BoostUntil, os.time()) + 600
		data.BoostLuck = math.max(data.BoostLuck, 2)
		reward = "10 minutes of 2x Luck!"
	else
		local amount = math.max(100, math.floor(clickPower(player) * 8 * 120))
		addPower(player, amount)
		reward = Format.Abbreviate(amount) .. " Brainpower!"
	end
	sync(player)
	return true, "Gift: " .. reward
end

task.spawn(function()
	while true do
		task.wait(1)
		for _, player in Players:GetPlayers() do
			clickBudget[player] = Config.MaxClicksPerSecond
			if MonetizationService.OwnsPass(player, "AutoClick") and DataService.Get(player) then
				addPower(player, clickPower(player) * Config.AutoClicksPerSecond)
			end
			local data = DataService.Get(player)
			if data then
				data.PlaySeconds += 1
				local stats = player:FindFirstChild("leaderstats")
				if stats then
					stats.Brainpower.Value = Format.Abbreviate(data.Brainpower)
				end
			end
		end
	end
end)

---------------------------------------------------------------- monetization

local function powerPack(seconds: number, min: number)
	return function(player)
		-- Assume a brisk 8 clicks/sec of the player's current power.
		local amount = math.max(min, math.floor(clickPower(player) * 8 * seconds))
		addPower(player, amount)
		sync(player)
		notify(player, "+" .. Format.Abbreviate(amount) .. " Brainpower! Thanks!", Color3.fromRGB(90, 255, 90))
		return true
	end
end

local function luckBoost(mult: number, seconds: number)
	return function(player, data)
		if data.BoostUntil > os.time() and data.BoostLuck > mult then
			-- Stronger boost already running: extend it instead.
			data.BoostUntil += seconds
		else
			data.BoostUntil = math.max(data.BoostUntil, os.time()) + seconds
			data.BoostLuck = mult
		end
		sync(player)
		notify(player, mult .. "x Luck active!", Color3.fromRGB(0, 255, 200))
		return true
	end
end

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		PowerSmall = powerPack(15 * 60, 1_000),
		PowerLarge = powerPack(3 * 3600, 100_000),
		LuckBoost = luckBoost(2, 30 * 60),
		SuperLuckBoost = luckBoost(5, 15 * 60),
		SecretEgg = function(player, data)
			local id = roll(Config.SecretEgg, luck(player))
			-- Robux pets ignore storage limits so a purchase never fails.
			givePet(player, id)
			if data.AutoEquip then
				equipBest(player)
			end
			sendInventory(player)
			notify(player, "You got " .. Config.PetById[id].Name .. "!", Config.Rarities[Config.PetById[id].Rarity])
			return true
		end,
	},
	OnPassOwned = function(player, name)
		sync(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.ProfileLoaded:Connect(function(player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local power = Instance.new("StringValue")
	power.Name = "Brainpower"
	power.Parent = stats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = stats
	stats.Parent = player
	if data.NextGift == 0 then
		data.NextGift = os.time() + Config.GiftEverySeconds
	end
	-- Remove pets whose definitions were deleted from Config.
	for uid, pet in data.Pets do
		if not Config.PetById[pet.Id] then
			data.Pets[uid] = nil
		end
	end
	sendInventory(player)
end)

Players.PlayerRemoving:Connect(function(player)
	clickBudget[player] = nil
end)

DataService.Init("HatchABrainrot_v1", {
	Brainpower = 0,
	TotalPower = 0,
	Rebirths = 0,
	Pets = {},
	Index = {},
	Hatches = 0,
	AutoEquip = true,
	BoostUntil = 0,
	BoostLuck = 1,
	NextGift = 0,
	GiftStreak = 0,
	PlaySeconds = 0,
})
