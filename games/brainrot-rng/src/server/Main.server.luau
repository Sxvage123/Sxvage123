-- Brainrot RNG server: rolling, luck, auras over heads, potions.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)

Lighting.ClockTime = 20
Lighting.Brightness = 1.5

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
local RollRemote = remote("RemoteFunction", "Roll")
local EquipRemote = remote("RemoteFunction", "Equip")
local InventoryRemote = remote("RemoteEvent", "Inventory")
local AutoRollResult = remote("RemoteEvent", "AutoRollResult")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

-- Simple night plaza
do
	local floor = Instance.new("Part")
	floor.Anchored = true
	floor.Size = Vector3.new(200, 2, 200)
	floor.Position = Vector3.new(0, -1, 0)
	floor.Color = Color3.fromRGB(40, 40, 60)
	floor.Material = Enum.Material.Slate
	floor.Parent = workspace
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(170, 0, 255)
	spawn.Neutral = true
	spawn.Parent = workspace
	for i = 1, 24 do
		local angle = i / 24 * math.pi * 2
		local crystal = Instance.new("Part")
		crystal.Anchored = true
		crystal.Size = Vector3.new(3, 8 + (i % 3) * 4, 3)
		crystal.CFrame = CFrame.new(math.cos(angle) * 60, crystal.Size.Y / 2, math.sin(angle) * 60) * CFrame.Angles(0, angle, math.rad(10))
		crystal.Color = Color3.fromHSV(i / 24, 0.7, 1)
		crystal.Material = Enum.Material.Neon
		crystal.Parent = workspace
	end
end

local lastRoll: { [Player]: number } = {}

local function luck(player: Player, data): number
	local l = 1
	if MonetizationService.OwnsPass(player, "Lucky") then
		l *= 1.5
	end
	if MonetizationService.OwnsPass(player, "VIP") then
		l *= 1.2
	end
	if data.PotionUntil > os.time() then
		l *= data.PotionLuck
	end
	if (workspace:GetAttribute("ServerLuckUntil") or 0) > os.time() then
		l *= 2
	end
	return l
end

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Rolls", data.Rolls)
	player:SetAttribute("Luck", luck(player, data))
	player:SetAttribute("PotionUntil", data.PotionUntil)
	player:SetAttribute("Heavenly", data.Heavenly)
	player:SetAttribute("Equipped", data.Equipped)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Rolls.Value = data.Rolls
		local best = Config.AuraById[data.Best]
		stats.Rarest.Value = if best then "1 in " .. Format.Abbreviate(best.Chance) else "-"
	end
end

local function showAura(player: Player)
	local data = DataService.Get(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not data or not head then
		return
	end
	local old = head:FindFirstChild("AuraTag")
	if old then
		old:Destroy()
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local oldFx = root and root:FindFirstChild("AuraFx")
	if oldFx then
		oldFx:Destroy()
	end
	local aura = Config.AuraById[data.Equipped]
	if not aura then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "AuraTag"
	gui.Size = UDim2.fromOffset(220, 50)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = 100
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = aura.Color
	label.Text = aura.Name .. "\n1 in " .. Format.Abbreviate(aura.Chance)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = if aura.Color == Color3.new(0, 0, 0) then Color3.new(1, 1, 1) else Color3.new(0, 0, 0)
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = head
	if root and aura.Chance >= 100 then
		local fx = Instance.new("ParticleEmitter")
		fx.Name = "AuraFx"
		fx.Color = ColorSequence.new(aura.Color)
		fx.LightEmission = 1
		fx.Size = NumberSequence.new(0.6, 0)
		fx.Rate = math.clamp(math.log10(aura.Chance) * 8, 10, 80)
		fx.Lifetime = NumberRange.new(0.8, 1.5)
		fx.Speed = NumberRange.new(2, 5)
		fx.SpreadAngle = Vector2.new(180, 180)
		fx.Parent = root
	end
end

local function doRoll(player: Player): (string?, boolean?)
	local data = DataService.Get(player)
	if not data then
		return nil
	end
	local cooldown = Config.RollCooldown / (if MonetizationService.OwnsPass(player, "QuickRoll") then 2 else 1)
	local now = os.clock()
	if now - (lastRoll[player] or 0) < cooldown - 0.05 then
		return nil
	end
	lastRoll[player] = now
	data.Rolls += 1
	local l = luck(player, data)
	local lucky = data.Rolls % Config.LuckyEvery == 0
	if lucky then
		l *= 2
	end
	if data.Heavenly > 0 then
		data.Heavenly -= 1
		l *= 200
	end
	local id = Config.Roll(l, math.random)
	local aura = Config.AuraById[id]
	data.Collected[id] = (data.Collected[id] or 0) + 1
	local best = Config.AuraById[data.Best]
	if not best or aura.Chance > best.Chance then
		data.Best = id
		-- Auto-equip a new personal best.
		data.Equipped = id
		showAura(player)
	end
	if aura.Chance >= Config.AnnounceAt then
		notify(nil, player.DisplayName .. " rolled " .. aura.Name .. " (1 in " .. Format.Abbreviate(aura.Chance) .. ")!", aura.Color)
	end
	sync(player)
	InventoryRemote:FireClient(player, data.Collected)
	return id, lucky
end

RollRemote.OnServerInvoke = function(player)
	return doRoll(player)
end

EquipRemote.OnServerInvoke = function(player, id)
	local data = DataService.Get(player)
	if not data or type(id) ~= "string" or not data.Collected[id] then
		return false
	end
	data.Equipped = id
	showAura(player)
	sync(player)
	return true
end

-- Keeps displayed luck correct as potions / server luck expire.
task.spawn(function()
	while true do
		task.wait(5)
		for _, player in Players:GetPlayers() do
			sync(player)
		end
	end
end)

-- Auto roll for pass owners who switched it on.
task.spawn(function()
	while true do
		task.wait(0.1)
		for _, player in Players:GetPlayers() do
			if player:GetAttribute("AutoRollOn") and MonetizationService.OwnsPass(player, "AutoRoll") then
				local id, lucky = doRoll(player)
				if id then
					AutoRollResult:FireClient(player, id, lucky)
				end
			end
		end
	end
end)

remote("RemoteEvent", "ToggleAutoRoll").OnServerEvent:Connect(function(player)
	player:SetAttribute("AutoRollOn", not player:GetAttribute("AutoRollOn"))
end)

DataService.ProfileLoaded:Connect(function(player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local rolls = Instance.new("IntValue")
	rolls.Name = "Rolls"
	rolls.Parent = stats
	local rarest = Instance.new("StringValue")
	rarest.Name = "Rarest"
	rarest.Parent = stats
	stats.Parent = player
	for id in data.Collected do
		if not Config.AuraById[id] then
			data.Collected[id] = nil
		end
	end
	sync(player)
	InventoryRemote:FireClient(player, data.Collected)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Head", 10)
		showAura(player)
	end)
	if player.Character then
		showAura(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastRoll[player] = nil
end)

local function potion(mult: number, seconds: number)
	return function(player, data)
		if data.PotionUntil > os.time() and data.PotionLuck > mult then
			data.PotionUntil += seconds
		else
			data.PotionUntil = math.max(data.PotionUntil, os.time()) + seconds
			data.PotionLuck = mult
		end
		sync(player)
		notify(player, mult .. "x luck active!", Color3.fromRGB(0, 255, 200))
		return true
	end
end

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		LuckPotion = potion(2, 600),
		SuperPotion = potion(5, 600),
		HeavenlyPotion = function(player, data)
			data.Heavenly += 1
			sync(player)
			notify(player, "Heavenly Potion ready! Your next roll has 200x luck!", Color3.fromRGB(255, 255, 160))
			return true
		end,
		ServerLuck = function(player)
			workspace:SetAttribute("ServerLuckUntil", math.max(workspace:GetAttribute("ServerLuckUntil") or 0, os.time()) + 900)
			notify(nil, player.DisplayName .. " gave EVERYONE 2x luck for 15 minutes!", Color3.fromRGB(0, 255, 200))
			for _, p in Players:GetPlayers() do
				sync(p)
			end
			return true
		end,
	},
	OnPassOwned = function(player, name)
		sync(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("BrainrotRNG_v1", {
	Rolls = 0,
	Collected = {},
	Best = "",
	Equipped = "",
	PotionUntil = 0,
	PotionLuck = 1,
	Heavenly = 0,
})
