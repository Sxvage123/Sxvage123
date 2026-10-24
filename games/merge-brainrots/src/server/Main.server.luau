-- Merge Brainrots server: board state, buying, merging, drops, idle income, rebirths.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)

Lighting.ClockTime = 14

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
local BoardRemote = remote("RemoteEvent", "Board")
local BuyRemote = remote("RemoteFunction", "Buy")
local MoveRemote = remote("RemoteFunction", "Move")
local RebirthRemote = remote("RemoteFunction", "Rebirth")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

-- A simple lobby so players can see each other.
do
	local floor = Instance.new("Part")
	floor.Anchored = true
	floor.Size = Vector3.new(120, 2, 120)
	floor.Position = Vector3.new(0, -1, 0)
	floor.Color = Color3.fromRGB(120, 200, 255)
	floor.Material = Enum.Material.SmoothPlastic
	floor.Parent = workspace
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Neutral = true
	spawn.Parent = workspace
end

local function slots(player: Player): number
	return Config.BaseSlots + (if MonetizationService.OwnsPass(player, "MoreSlots") then Config.ExtraSlots else 0)
end

local function multiplier(player: Player, data): number
	local m = 1 + data.Rebirths * Config.RebirthBonus
	if MonetizationService.OwnsPass(player, "DoubleCash") then
		m *= 2
	end
	return m
end

local function income(player: Player, data): number
	local total = 0
	for i = 1, slots(player) do
		local level = data.Board[i] or 0
		if level > 0 then
			total += Config.Income(level)
		end
	end
	return total * multiplier(player, data)
end

local function best(data): number
	local b = data.Best
	for _, level in data.Board do
		b = math.max(b, level)
	end
	return b
end

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	data.Best = best(data)
	local buyLevel = Config.BuyLevel(data.Best)
	player:SetAttribute("Cash", data.Cash)
	player:SetAttribute("Income", income(player, data))
	player:SetAttribute("Best", data.Best)
	player:SetAttribute("BuyLevel", buyLevel)
	player:SetAttribute("BuyCost", Config.BuyCost(buyLevel, data.Purchases))
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("Slots", slots(player))
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Cash.Value = Format.Cash(data.Cash)
		stats.Best.Value = data.Best
	end
	-- Show your best brainrot over your head.
	local head = player.Character and player.Character:FindFirstChild("Head")
	if head then
		local tag = head:FindFirstChild("BestTag") :: BillboardGui?
		if not tag then
			local newTag = Instance.new("BillboardGui")
			newTag.Name = "BestTag"
			newTag.Size = UDim2.fromOffset(200, 30)
			newTag.StudsOffset = Vector3.new(0, 2.5, 0)
			newTag.MaxDistance = 60
			local label = Instance.new("TextLabel")
			label.Name = "Label"
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 1)
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 2
			stroke.Parent = label
			label.Parent = newTag
			newTag.Parent = head
			tag = newTag
		end
		local label = (tag :: BillboardGui):FindFirstChild("Label") :: TextLabel
		label.Text = "Lv" .. data.Best .. " " .. (Config.Names[data.Best] or "")
		label.TextColor3 = Config.Color(math.max(1, data.Best))
	end
end

local function sendBoard(player: Player)
	local data = DataService.Get(player)
	if data then
		BoardRemote:FireClient(player, data.Board)
	end
	sync(player)
end

local function emptySlot(player: Player, data): number?
	for i = 1, slots(player) do
		if (data.Board[i] or 0) == 0 then
			return i
		end
	end
	return nil
end

local function place(player: Player, data, level: number): boolean
	local slot = emptySlot(player, data)
	if not slot then
		return false
	end
	data.Board[slot] = math.min(level, Config.MaxLevel)
	return true
end

local function announceIfNew(player: Player, data, level: number)
	if level > data.Best then
		data.Best = level
		if level >= 10 then
			notify(nil, player.DisplayName .. " unlocked Lv" .. level .. " " .. Config.Names[level] .. "!", Config.Color(level))
		else
			notify(player, "NEW: " .. Config.Names[level] .. "!", Config.Color(level))
		end
	end
end

BuyRemote.OnServerInvoke = function(player)
	local data = DataService.Get(player)
	if not data then
		return false, "Loading..."
	end
	local level = Config.BuyLevel(best(data))
	local cost = Config.BuyCost(level, data.Purchases)
	if data.Cash < cost then
		return false, "Need " .. Format.Cash(cost) .. "!"
	end
	if not emptySlot(player, data) then
		return false, "Board full! Merge some brainrots."
	end
	data.Cash -= cost
	data.Purchases += 1
	place(player, data, level)
	sendBoard(player)
	return true
end

-- Move from slot a to slot b: merge if same level, swap otherwise.
local function move(player: Player, data, a: number, b: number): (boolean, string?)
	local limit = slots(player)
	if a == b or a < 1 or b < 1 or a > limit or b > limit then
		return false
	end
	local la, lb = data.Board[a] or 0, data.Board[b] or 0
	if la == 0 then
		return false
	end
	if la == lb and la < Config.MaxLevel then
		data.Board[a] = 0
		data.Board[b] = la + 1
		data.Merges += 1
		announceIfNew(player, data, la + 1)
		return true, "merged"
	end
	data.Board[a], data.Board[b] = lb, la
	return true, "moved"
end

MoveRemote.OnServerInvoke = function(player, a, b)
	local data = DataService.Get(player)
	if not data or type(a) ~= "number" or type(b) ~= "number" or a % 1 ~= 0 or b % 1 ~= 0 then
		return false
	end
	local ok, kind = move(player, data, a, b)
	if ok then
		sendBoard(player)
	end
	return ok, kind
end

RebirthRemote.OnServerInvoke = function(player)
	local data = DataService.Get(player)
	if not data then
		return false, "Loading..."
	end
	if best(data) < Config.RebirthLevel then
		return false, "Reach Lv" .. Config.RebirthLevel .. " (" .. Config.Names[Config.RebirthLevel] .. ") to rebirth!"
	end
	data.Rebirths += 1
	data.Board = {}
	data.Cash = 0
	data.Purchases = 0
	data.Best = 0
	place(player, data, 1)
	sendBoard(player)
	notify(nil, player.DisplayName .. " rebirthed! (" .. data.Rebirths .. ")", Color3.fromRGB(255, 215, 0))
	return true, "Rebirth! Now " .. (1 + data.Rebirths * Config.RebirthBonus) .. "x income."
end

---------------------------------------------------------------- loops

local nextDrop: { [Player]: number } = {}

task.spawn(function()
	while true do
		task.wait(1)
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			local data = DataService.Get(player)
			if not data then
				continue
			end
			local earned = income(player, data)
			data.Cash += earned
			data.TotalEarned += earned
			local changed = false
			-- Free drops
			local every = Config.DropEvery / (if MonetizationService.OwnsPass(player, "FastDrops") then 2 else 1)
			if now >= (nextDrop[player] or 0) then
				nextDrop[player] = now + every
				if place(player, data, Config.BuyLevel(best(data))) then
					changed = true
				end
			end
			-- Auto merge (pass): merge one matching pair per tick.
			if MonetizationService.OwnsPass(player, "AutoMerge") and player:GetAttribute("AutoMergeOn") ~= false then
				local seen = {}
				for i = 1, slots(player) do
					local level = data.Board[i] or 0
					if level > 0 and level < Config.MaxLevel then
						if seen[level] then
							move(player, data, seen[level], i)
							changed = true
							break
						end
						seen[level] = i
					end
				end
			end
			if changed then
				sendBoard(player)
			else
				sync(player)
			end
		end
	end
end)

remote("RemoteEvent", "ToggleAutoMerge").OnServerEvent:Connect(function(player)
	player:SetAttribute("AutoMergeOn", player:GetAttribute("AutoMergeOn") == false)
end)

---------------------------------------------------------------- players

DataService.ProfileLoaded:Connect(function(player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = stats
	local bestValue = Instance.new("IntValue")
	bestValue.Name = "Best"
	bestValue.Parent = stats
	stats.Parent = player
	-- Board is stored as a dense array of levels (0 = empty).
	for i = 1, Config.BaseSlots + Config.ExtraSlots do
		data.Board[i] = data.Board[i] or 0
	end
	if data.LoginCount == 1 then
		place(player, data, 1)
		place(player, data, 1)
	end
	if data.LastSave > 0 then
		local away = math.min(os.time() - data.LastSave, Config.OfflineCap)
		local earned = math.floor(away * income(player, data) * Config.OfflineRate)
		if earned > 0 then
			data.Cash += earned
			task.delay(3, notify, player, "Welcome back! You earned " .. Format.Cash(earned) .. " offline.", Color3.fromRGB(90, 255, 90))
		end
	end
	sendBoard(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Head", 10)
		sync(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	nextDrop[player] = nil
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		CashPack = function(player, data)
			local amount = math.max(1000, math.floor(income(player, data) * 3600))
			data.Cash += amount
			sync(player)
			notify(player, "+" .. Format.Cash(amount) .. "!", Color3.fromRGB(90, 255, 90))
			return true
		end,
		LevelUp = function(player, data)
			local top = 0
			for i, level in data.Board do
				if level > 0 then
					data.Board[i] = math.min(Config.MaxLevel, level + 1)
					top = math.max(top, data.Board[i])
				end
			end
			announceIfNew(player, data, top)
			sendBoard(player)
			notify(player, "Every brainrot leveled up!", Color3.fromRGB(255, 215, 0))
			return true
		end,
		MegaDrop = function(player, data)
			local level = math.min(Config.MaxLevel, Config.BuyLevel(best(data)) + 3)
			if not place(player, data, level) then
				-- Board full: overwrite the lowest slot so the purchase always lands.
				local low, lowIndex = math.huge, 1
				for i = 1, slots(player) do
					if (data.Board[i] or 0) < low then
						low, lowIndex = data.Board[i] or 0, i
					end
				end
				data.Board[lowIndex] = level
			end
			announceIfNew(player, data, level)
			sendBoard(player)
			return true
		end,
	},
	OnPassOwned = function(player, name)
		sendBoard(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("MergeBrainrots_v1", {
	Cash = 0,
	Board = {},
	Purchases = 0,
	Best = 0,
	Merges = 0,
	Rebirths = 0,
	TotalEarned = 0,
})
