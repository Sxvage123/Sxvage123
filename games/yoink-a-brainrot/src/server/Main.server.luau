-- Yoink a Brainrot: buy brainrots off the runway, they earn cash in your base,
-- steal other players' brainrots, lock your base, rebirth for multipliers.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)
local Map = require(script.Parent.Map)
local Models = require(script.Parent.Models)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local NotifyRemote = Instance.new("RemoteEvent")
NotifyRemote.Name = "Notify"
NotifyRemote.Parent = remotes
local RebirthRemote = Instance.new("RemoteFunction")
RebirthRemote.Name = "Rebirth"
RebirthRemote.Parent = remotes

local plots = Map.Build()
local playerPlot: { [Player]: any } = {}
local carrying: { [Player]: any } = {}
local records: { [string]: any } = {} -- uid -> brainrot record
local brainrotFolder = Instance.new("Folder")
brainrotFolder.Name = "Brainrots"
brainrotFolder.Parent = workspace

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

---------------------------------------------------------------- stats & cash

local function multiplier(player: Player): number
	local data = DataService.Get(player)
	local m = 1 + (data and data.Rebirths or 0) * Config.RebirthBonus
	if MonetizationService.OwnsPass(player, "DoubleCash") then
		m *= 2
	end
	if MonetizationService.OwnsPass(player, "VIP") then
		m *= 1.5
	end
	return m
end

local function income(player: Player): number
	local plot = playerPlot[player]
	if not plot then
		return 0
	end
	local total = 0
	for _, rec in plot.Slots do
		if rec.State == "Placed" then
			total += rec.Info.Income
		end
	end
	return total * multiplier(player)
end

local function updateStats(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Cash", data.Cash)
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("Multiplier", multiplier(player))
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Cash.Value = Format.Cash(data.Cash)
		stats.Rebirths.Value = data.Rebirths
	end
end

local function addCash(player: Player, amount: number)
	local data = DataService.Get(player)
	if not data then
		return
	end
	data.Cash += amount
	if amount > 0 then
		data.TotalEarned = (data.TotalEarned or 0) + amount
	end
	updateStats(player)
end

local function walkSpeed(player: Player): number
	local speed = if carrying[player] then Config.CarrySpeed else Config.WalkSpeed
	if MonetizationService.OwnsPass(player, "SpeedCoil") then
		speed *= Config.SpeedCoilMultiplier
	end
	return speed
end

local function applySpeed(player: Player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = walkSpeed(player)
	end
end

---------------------------------------------------------------- slots

local function maxSlots(player: Player): number
	return Config.BaseSlots + (if MonetizationService.OwnsPass(player, "ExtraSlots") then Config.ExtraSlots else 0)
end

local function freeSlot(player: Player, limit: number?): number?
	local plot = playerPlot[player]
	if not plot then
		return nil
	end
	for i = 1, limit or maxSlots(player) do
		if not plot.Slots[i] then
			return i
		end
	end
	return nil
end

local function slotCFrame(rec): CFrame
	local height = rec.Model:GetAttribute("RootHeight") or 3
	return rec.Plot.SlotCFrames[rec.Slot] * CFrame.new(0, height, 0)
end

local function setPromptMode(rec)
	-- The client decides which prompts to show from these attributes (owners see Sell, others Steal).
	local mode = rec.State
	rec.Model:SetAttribute("State", mode)
	rec.Model:SetAttribute("OwnerId", if rec.Owner then rec.Owner.UserId else 0)
	rec.Model:SetAttribute("ReservedFor", if rec.ReservedFor then rec.ReservedFor.UserId else 0)
	local tag = rec.Root:FindFirstChild("Tag")
	if tag then
		tag.Price.Visible = mode == "Walking"
	end
end

local function destroyRecord(rec)
	records[rec.Uid] = nil
	if rec.Tween then
		rec.Tween:Cancel()
	end
	if rec.Plot and rec.Plot.Slots[rec.Slot] == rec then
		rec.Plot.Slots[rec.Slot] = nil
	end
	rec.Model:Destroy()
end

-- Places a record into a player's base and writes it into their save data.
local function assignToPlot(rec, player: Player, slot: number, animate: boolean)
	local plot = playerPlot[player]
	local data = DataService.Get(player)
	rec.Owner = player
	rec.Plot = plot
	rec.Slot = slot
	rec.ReservedFor = nil
	plot.Slots[slot] = rec
	data.Brainrots[rec.Uid] = { Id = rec.Info.Id, Slot = slot }
	data.Discovered[rec.Info.Id] = true
	if rec.Tween then
		rec.Tween:Cancel()
		rec.Tween = nil
	end
	local target = slotCFrame(rec)
	if animate then
		rec.State = "Moving"
		setPromptMode(rec)
		local tween = TweenService:Create(rec.Root, TweenInfo.new(1.4, Enum.EasingStyle.Quad), { CFrame = target })
		rec.Tween = tween
		tween.Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed and rec.State == "Moving" then
				rec.State = "Placed"
				rec.Tween = nil
				setPromptMode(rec)
			end
		end)
		tween:Play()
	else
		rec.Root.CFrame = target
		rec.State = "Placed"
		setPromptMode(rec)
	end
end

---------------------------------------------------------------- stealing

local function endCarry(rec)
	local thief = rec.Thief
	rec.Thief = nil
	if rec.CarryWeld then
		rec.CarryWeld:Destroy()
		rec.CarryWeld = nil
	end
	rec.Root.Anchored = true
	if thief then
		carrying[thief] = nil
		thief:SetAttribute("Carrying", nil)
		applySpeed(thief)
	end
	return thief
end

local function returnToOwner(rec, reason: string?)
	local thief = endCarry(rec)
	rec.State = "Placed"
	rec.Root.CFrame = slotCFrame(rec)
	setPromptMode(rec)
	if thief and reason then
		notify(thief, reason, Color3.fromRGB(255, 90, 90))
	end
end

local function completeSteal(rec)
	local thief = rec.Thief
	local victim = rec.Owner
	local slot = freeSlot(thief)
	if not slot then
		returnToOwner(rec, "Your base is full! The brainrot ran home.")
		return
	end
	endCarry(rec)
	local victimData = DataService.Get(victim)
	if victimData then
		victimData.Brainrots[rec.Uid] = nil
	end
	rec.Plot.Slots[rec.Slot] = nil
	assignToPlot(rec, thief, slot, false)
	local thiefData = DataService.Get(thief)
	thiefData.Steals = (thiefData.Steals or 0) + 1
	notify(thief, "You yoinked " .. rec.Info.Name .. "!", Color3.fromRGB(90, 255, 90))
	notify(victim, thief.DisplayName .. " yoinked your " .. rec.Info.Name .. "!", Color3.fromRGB(255, 90, 90))
end

local function startSteal(rec, thief: Player)
	local root = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	if rec.Tween then
		rec.Tween:Cancel()
		rec.Tween = nil
	end
	rec.State = "Carried"
	rec.Thief = thief
	rec.StealDeadline = os.clock() + Config.StealTimeout
	carrying[thief] = rec
	thief:SetAttribute("Carrying", rec.Info.Name)
	setPromptMode(rec)

	rec.Root.Anchored = false
	rec.Root.CanCollide = false
	rec.Root.Massless = true
	local w = Instance.new("Weld")
	w.Part0 = root
	w.Part1 = rec.Root
	w.C0 = CFrame.new(0, 3 + rec.Root.Size.Y / 2 + 1, 0)
	w.Parent = rec.Root
	rec.CarryWeld = w
	rec.Root:SetNetworkOwner(thief)
	applySpeed(thief)
	notify(thief, "Run back to your base!", Color3.fromRGB(255, 230, 80))
	notify(rec.Owner, thief.DisplayName .. " is stealing your " .. rec.Info.Name .. "! Tag them!", Color3.fromRGB(255, 60, 60))
end

---------------------------------------------------------------- records

local function newRecord(info, uid: string?)
	local model, root = Models.Create(info)
	local rec: any = {
		Uid = uid or HttpService:GenerateGUID(false),
		Info = info,
		Model = model,
		Root = root,
		State = "Walking",
	}
	records[rec.Uid] = rec

	local function prompt(name, action, key, hold)
		local p = Instance.new("ProximityPrompt")
		p.Name = name
		p.ActionText = action
		p.ObjectText = info.Name
		p.KeyboardKeyCode = key
		p.HoldDuration = hold
		p.MaxActivationDistance = 12
		p.RequiresLineOfSight = false
		p.Parent = root
		return p
	end
	rec.BuyPrompt = prompt("BuyPrompt", "Buy " .. Format.Cash(info.Price), Enum.KeyCode.E, 0)
	rec.SellPrompt = prompt("SellPrompt", "Sell " .. Format.Cash(info.Price * Config.SellRefund), Enum.KeyCode.F, 1)
	rec.StealPrompt = prompt("StealPrompt", "Steal", Enum.KeyCode.E, Config.StealHoldTime)

	rec.BuyPrompt.Triggered:Connect(function(player)
		if rec.State ~= "Walking" then
			return
		end
		if rec.ReservedFor and rec.ReservedFor ~= player and os.clock() < rec.ReservedUntil then
			notify(player, "This one is reserved for " .. rec.ReservedFor.DisplayName .. "!", Color3.fromRGB(255, 90, 90))
			return
		end
		local data = DataService.Get(player)
		if not data or not playerPlot[player] then
			return
		end
		if data.Cash < info.Price then
			notify(player, "Not enough cash! Need " .. Format.Cash(info.Price), Color3.fromRGB(255, 90, 90))
			return
		end
		local slot = freeSlot(player)
		if not slot then
			notify(player, "Your base is full! Sell something or get +5 Slots.", Color3.fromRGB(255, 90, 90))
			return
		end
		addCash(player, -info.Price)
		assignToPlot(rec, player, slot, true)
		if Config.RarityByName[info.Rarity].Luck then
			notify(nil, player.DisplayName .. " bought a " .. info.Rarity .. " " .. info.Name .. "!", Config.RarityByName[info.Rarity].Color)
		end
	end)

	rec.SellPrompt.Triggered:Connect(function(player)
		if rec.State ~= "Placed" or rec.Owner ~= player then
			return
		end
		local data = DataService.Get(player)
		if not data then
			return
		end
		data.Brainrots[rec.Uid] = nil
		destroyRecord(rec)
		addCash(player, math.floor(info.Price * Config.SellRefund))
		notify(player, "Sold " .. info.Name .. " for " .. Format.Cash(info.Price * Config.SellRefund), Color3.fromRGB(90, 255, 90))
	end)

	rec.StealPrompt.Triggered:Connect(function(player)
		if rec.State ~= "Placed" or rec.Owner == player or carrying[player] or not playerPlot[player] then
			return
		end
		if os.clock() < rec.Plot.LockedUntil then
			notify(player, "This base is locked!", Color3.fromRGB(255, 90, 90))
			return
		end
		if not freeSlot(player) then
			notify(player, "Your base is full!", Color3.fromRGB(255, 90, 90))
			return
		end
		startSteal(rec, player)
	end)

	setPromptMode(rec)
	model.Parent = brainrotFolder
	return rec
end

---------------------------------------------------------------- runway spawner

local function currentLuck(): number
	local luck = 1
	if (workspace:GetAttribute("ServerLuckUntil") or 0) > os.time() then
		luck *= 2
	end
	if (workspace:GetAttribute("EventUntil") or 0) > os.time() then
		luck *= 1.5
	end
	return luck
end

local function rollBrainrot()
	local luck = currentLuck()
	local total = 0
	for _, rarity in Config.Rarities do
		total += rarity.Weight * (if rarity.Luck then luck else 1)
	end
	local roll = math.random() * total
	local chosen = Config.Rarities[1]
	for _, rarity in Config.Rarities do
		roll -= rarity.Weight * (if rarity.Luck then luck else 1)
		if roll <= 0 then
			chosen = rarity
			break
		end
	end
	local pool = Config.ByRarity[chosen.Name]
	return pool[math.random(1, #pool)]
end

local function spawnWalker(info, reservedFor: Player?)
	local rec = newRecord(info)
	if reservedFor then
		rec.ReservedFor = reservedFor
		rec.ReservedUntil = os.clock() + 12
	end
	setPromptMode(rec)
	local height = rec.Model:GetAttribute("RootHeight") or 3
	local start = Map.RunwayStart + Vector3.new(0, height, 0)
	local finish = Map.RunwayEnd + Vector3.new(0, height, 0)
	rec.Root.CFrame = CFrame.lookAt(start, finish)
	local tween = TweenService:Create(rec.Root, TweenInfo.new(Config.WalkTime, Enum.EasingStyle.Linear), {
		CFrame = CFrame.lookAt(finish, finish + (finish - start).Unit),
	})
	rec.Tween = tween
	tween.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and rec.State == "Walking" then
			destroyRecord(rec)
		end
	end)
	tween:Play()
	if Config.RarityByName[info.Rarity].Luck and info.Rarity ~= "Epic" then
		notify(nil, "A " .. info.Rarity .. " " .. info.Name .. " appeared!", Config.RarityByName[info.Rarity].Color)
	end
	return rec
end

task.spawn(function()
	while true do
		local interval = Config.SpawnInterval
		if (workspace:GetAttribute("EventUntil") or 0) > os.time() then
			interval /= 2
		end
		task.wait(interval)
		spawnWalker(rollBrainrot())
	end
end)

-- Recurring "Brainrot Rush" event keeps players around.
task.spawn(function()
	while true do
		task.wait(Config.EventEvery)
		workspace:SetAttribute("EventUntil", os.time() + Config.EventDuration)
		notify(nil, "BRAINROT RUSH! 2x spawns + luck for 2 minutes!", Color3.fromRGB(255, 200, 0))
	end
end)

---------------------------------------------------------------- plots & players

local function lockPlot(plot, player: Player)
	local duration = Config.LockDuration * (if MonetizationService.OwnsPass(player, "VIP") then 2 else 1)
	local now = os.clock()
	plot.LockedUntil = math.max(plot.LockedUntil, now) + duration
	plot.LockCooldownUntil = plot.LockedUntil + Config.LockCooldown
	notify(player, "Base locked for " .. duration .. "s!", Color3.fromRGB(255, 130, 130))
end

local function playerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	return character and Players:GetPlayerFromCharacter(character)
end

for _, plot in plots do
	local collectDebounce = false
	plot.CollectPad.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if collectDebounce or not player or plot.Owner ~= player or plot.Uncollected < 1 then
			return
		end
		collectDebounce = true
		local amount = math.floor(plot.Uncollected)
		plot.Uncollected -= amount
		addCash(player, amount)
		notify(player, "+" .. Format.Cash(amount), Color3.fromRGB(90, 255, 90))
		task.wait(0.5)
		collectDebounce = false
	end)
	plot.LockPad.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if not player or plot.Owner ~= player then
			return
		end
		if os.clock() >= plot.LockCooldownUntil then
			lockPlot(plot, player)
		end
	end)
end

local function setupCharacter(player: Player, character: Model)
	local plot = playerPlot[player]
	local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if plot and root then
		task.wait()
		character:PivotTo(plot.SpawnCFrame)
	end
	applySpeed(player)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if humanoid then
		humanoid.Died:Connect(function()
			local rec = carrying[player]
			if rec then
				returnToOwner(rec, "You dropped it!")
			end
		end)
	end
end

local function claimPlot(player: Player, data)
	local plot
	for _, p in plots do
		if not p.Owner then
			plot = p
			break
		end
	end
	if not plot then
		notify(player, "Server is full of bases! Rejoin another server.", Color3.fromRGB(255, 90, 90))
		return
	end
	plot.Owner = player
	plot.Uncollected = 0
	plot.LockedUntil = 0
	plot.LockCooldownUntil = 0
	plot.SignLabel.Text = player.DisplayName .. "'s Base"
	playerPlot[player] = plot
	player:SetAttribute("PlotIndex", plot.Index)

	-- Restore saved brainrots into their slots.
	local limit = Config.BaseSlots + Config.ExtraSlots
	for uid, entry in data.Brainrots do
		local info = Config.ById[entry.Id]
		if not info then
			data.Brainrots[uid] = nil
			continue
		end
		local slot = entry.Slot
		if type(slot) ~= "number" or slot < 1 or slot > limit or plot.Slots[slot] then
			slot = freeSlot(player, limit)
		end
		if slot then
			local rec = newRecord(info, uid)
			assignToPlot(rec, player, slot, false)
		end
	end
end

local function onProfileLoaded(player: Player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = stats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = stats
	stats.Parent = player

	claimPlot(player, data)
	updateStats(player)

	if data.LastSave > 0 then
		local away = math.min(os.time() - data.LastSave, Config.OfflineCapSeconds)
		local earned = math.floor(away * income(player) * Config.OfflineRate)
		if earned > 0 then
			addCash(player, earned)
			task.delay(3, notify, player, "Welcome back! Your brainrots earned " .. Format.Cash(earned) .. " while you were gone.", Color3.fromRGB(90, 255, 90))
		end
	end

	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	if player.Character then
		task.spawn(setupCharacter, player, player.Character)
	end
end

local function releasePlayer(player: Player)
	local rec = carrying[player]
	if rec then
		returnToOwner(rec)
	end
	local plot = playerPlot[player]
	if not plot then
		return
	end
	for _, r in records do
		if r.Owner == player then
			if r.State == "Carried" then
				endCarry(r)
			end
			destroyRecord(r)
		end
	end
	plot.Owner = nil
	plot.Uncollected = 0
	plot.Slots = {}
	plot.SignLabel.Text = "Empty Base"
	plot.CollectLabel.Text = "COLLECT $0"
	plot.Barrier.Transparency = 1
	playerPlot[player] = nil
end

---------------------------------------------------------------- monetization

local function cashPack(name)
	return function(player: Player, _data)
		local pack = Config.CashPacks[name]
		local amount = math.max(pack.Min, math.floor(income(player) * pack.Seconds))
		addCash(player, amount)
		notify(player, "+" .. Format.Cash(amount) .. "! Thanks for the support!", Color3.fromRGB(90, 255, 90))
		return true
	end
end

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		CashSmall = cashPack("CashSmall"),
		CashMedium = cashPack("CashMedium"),
		CashLarge = cashPack("CashLarge"),
		ServerLuck = function(player)
			local current = math.max(workspace:GetAttribute("ServerLuckUntil") or 0, os.time())
			workspace:SetAttribute("ServerLuckUntil", current + Config.ServerLuckMinutes * 60)
			notify(nil, player.DisplayName .. " activated 2x SERVER LUCK! Thank them!", Color3.fromRGB(0, 255, 200))
			return true
		end,
		SpawnSecret = function(player)
			local pool = Config.ByRarity.Secret
			local info = pool[math.random(1, #pool)]
			spawnWalker(info, player)
			notify(nil, player.DisplayName .. " summoned a SECRET " .. info.Name .. "!", Color3.fromRGB(255, 0, 170))
			return true
		end,
		InstantLock = function(player)
			local plot = playerPlot[player]
			if not plot then
				return false
			end
			lockPlot(plot, player)
			return true
		end,
	},
	OnPassOwned = function(player, name)
		applySpeed(player)
		updateStats(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

RebirthRemote.OnServerInvoke = function(player)
	local data = DataService.Get(player)
	if not data then
		return false, "Still loading..."
	end
	local cost = Config.RebirthCost(data.Rebirths)
	if data.Cash < cost then
		return false, "You need " .. Format.Cash(cost) .. " to rebirth!"
	end
	local rec = carrying[player]
	if rec then
		returnToOwner(rec)
	end
	for _, r in records do
		if r.Owner == player then
			if r.State == "Carried" then
				endCarry(r)
			end
			destroyRecord(r)
		end
	end
	data.Brainrots = {}
	data.Cash = Config.StartingCash * (data.Rebirths + 2)
	data.Rebirths += 1
	local plot = playerPlot[player]
	if plot then
		plot.Uncollected = 0
	end
	updateStats(player)
	notify(nil, player.DisplayName .. " reached Rebirth " .. data.Rebirths .. "!", Color3.fromRGB(255, 215, 0))
	return true, "Rebirthed! Permanent " .. (1 + data.Rebirths * Config.RebirthBonus) .. "x cash."
end

DataService.ProfileLoaded:Connect(onProfileLoaded)
DataService.ProfileReleasing:Connect(function(player)
	-- Bank uncollected cash so it isn't lost on leave.
	local plot = playerPlot[player]
	local data = DataService.Get(player)
	if plot and data and plot.Owner == player then
		data.Cash += math.floor(plot.Uncollected)
		plot.Uncollected = 0
	end
end)
Players.PlayerRemoving:Connect(function(player)
	-- Let DataService bank & save first (it also listens to PlayerRemoving).
	task.defer(releasePlayer, player)
end)

DataService.Init("YoinkABrainrot_v1", {
	Cash = Config.StartingCash,
	Rebirths = 0,
	Brainrots = {},
	Discovered = {},
	TotalEarned = 0,
	Steals = 0,
})

---------------------------------------------------------------- game loops

-- Income tick
task.spawn(function()
	while true do
		task.wait(1)
		for player, plot in playerPlot do
			local perSecond = income(player)
			plot.Uncollected += perSecond
			plot.CollectLabel.Text = "COLLECT " .. Format.Cash(plot.Uncollected)
			player:SetAttribute("Income", perSecond)
		end
	end
end)

-- Steal tracking, base locks
task.spawn(function()
	while true do
		task.wait(0.15)
		local now = os.clock()
		for thief, rec in carrying do
			local root = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local humanoid = thief.Character and thief.Character:FindFirstChildOfClass("Humanoid")
			if not root or not humanoid or humanoid.Health <= 0 then
				returnToOwner(rec, "You dropped it!")
				continue
			end
			if now > rec.StealDeadline then
				returnToOwner(rec, "Too slow! It escaped.")
				continue
			end
			local owner = rec.Owner
			local ownerRoot = owner.Character and owner.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if ownerRoot and (ownerRoot.Position - root.Position).Magnitude < 7 then
				returnToOwner(rec, owner.DisplayName .. " caught you!")
				notify(owner, "You got your " .. rec.Info.Name .. " back!", Color3.fromRGB(90, 255, 90))
				continue
			end
			local home = playerPlot[thief]
			if home and Map.IsInPlot(home, root.Position) then
				completeSteal(rec)
			end
		end

		for _, plot in plots do
			local locked = now < plot.LockedUntil
			plot.Barrier.Transparency = if locked then 0.35 else 1
			if plot.Owner then
				if locked then
					plot.LockLabel.Text = "LOCKED " .. math.ceil(plot.LockedUntil - now) .. "s"
				elseif now < plot.LockCooldownUntil then
					plot.LockLabel.Text = "Cooldown " .. math.ceil(plot.LockCooldownUntil - now) .. "s"
				else
					plot.LockLabel.Text = "LOCK BASE"
				end
			end
			if locked then
				for _, player in Players:GetPlayers() do
					if player ~= plot.Owner then
						local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
						if root and Map.IsInPlot(plot, root.Position) then
							local localPos = plot.CFrame:PointToObjectSpace(root.Position)
							player.Character:PivotTo(plot.CFrame * CFrame.new(localPos.X, 4, -Map.PlotHalfZ - 6))
						end
					end
				end
			end
		end
	end
end)
