-- Session-locked DataStore saving shared by every game.
-- Keeps each player's data in memory, autosaves, and never lets two servers
-- write the same player at once (prevents item duplication / rollbacks).
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataService = {}

local AUTOSAVE_INTERVAL = 90
local LOCK_EXPIRE = 600
local LOAD_ATTEMPTS = 6

local profiles: { [Player]: { [string]: any } } = {}
local loadedEvent = Instance.new("BindableEvent")
local releasingEvent = Instance.new("BindableEvent")
DataService.ProfileLoaded = loadedEvent.Event -- (player, data)
DataService.ProfileReleasing = releasingEvent.Event -- (player, data) fired before the final save

local store: DataStore? = nil
local memoryStore: { [string]: any } = {}
local template: { [string]: any } = {}
local initialized = false

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value do
		copy[k] = deepCopy(v)
	end
	return copy
end
DataService.DeepCopy = deepCopy

local function reconcile(data, tmpl)
	for key, value in tmpl do
		if data[key] == nil then
			data[key] = deepCopy(value)
		elseif type(value) == "table" and type(data[key]) == "table" and next(value) ~= nil and #value == 0 then
			reconcile(data[key], value)
		end
	end
end

local function update(key: string, transform: (any) -> any): (boolean, any)
	if not store then
		local result = transform(memoryStore[key])
		if result ~= nil then
			memoryStore[key] = deepCopy(result)
		end
		return true, result
	end
	local ok, result = pcall(function()
		return (store :: DataStore):UpdateAsync(key, transform)
	end)
	return ok, result
end

local function keyFor(player: Player): string
	return "Player_" .. player.UserId
end

local function loadProfile(player: Player)
	local key = keyFor(player)
	for attempt = 1, LOAD_ATTEMPTS do
		local stealLock = attempt == LOAD_ATTEMPTS
		local lockedElsewhere = false
		local ok, result = update(key, function(stored)
			stored = stored or { Data = deepCopy(template) }
			local lock = stored.Lock
			if lock and lock.JobId ~= game.JobId and os.time() - lock.Time < LOCK_EXPIRE and not stealLock then
				lockedElsewhere = true
				return nil
			end
			stored.Lock = { JobId = game.JobId, Time = os.time() }
			return stored
		end)
		if ok and result and not lockedElsewhere then
			local data = result.Data or deepCopy(template)
			reconcile(data, template)
			return data
		end
		if not ok then
			warn("[DataService] load failed for", player.Name, result)
		end
		task.wait(lockedElsewhere and 5 or 2)
		if not player.Parent then
			return nil
		end
	end
	return nil
end

-- Saves the player's data. `release` clears the session lock (used on leave).
function DataService.Save(player: Player, release: boolean?): boolean
	local data = profiles[player]
	if not data then
		return false
	end
	data.LastSave = os.time()
	local snapshot = deepCopy(data)
	local ok, err = update(keyFor(player), function(stored)
		stored = stored or {}
		if stored.Lock and stored.Lock.JobId ~= game.JobId then
			-- Another server took over this player; never overwrite its data.
			return nil
		end
		stored.Data = snapshot
		stored.Lock = if release then nil else { JobId = game.JobId, Time = os.time() }
		return stored
	end)
	if not ok then
		warn("[DataService] save failed for", player.Name, err)
	end
	return ok
end

function DataService.Get(player: Player): { [string]: any }?
	return profiles[player]
end

function DataService.WaitFor(player: Player, timeout: number?): { [string]: any }?
	local deadline = os.clock() + (timeout or 15)
	while not profiles[player] and player.Parent and os.clock() < deadline do
		task.wait(0.1)
	end
	return profiles[player]
end

local function onPlayerAdded(player: Player)
	local data = loadProfile(player)
	if not player.Parent then
		if data then
			profiles[player] = data
			DataService.Save(player, true)
			profiles[player] = nil
		end
		return
	end
	if not data then
		player:Kick("Your data could not load. Please rejoin in a moment!")
		return
	end
	data.LoginCount = (data.LoginCount or 0) + 1
	profiles[player] = data
	loadedEvent:Fire(player, data)
end

local function onPlayerRemoving(player: Player)
	local data = profiles[player]
	if not data then
		return
	end
	releasingEvent:Fire(player, data)
	DataService.Save(player, true)
	profiles[player] = nil
end

function DataService.Init(storeName: string, dataTemplate: { [string]: any })
	assert(not initialized, "DataService already initialized")
	initialized = true
	template = dataTemplate
	template.LastSave = template.LastSave or 0
	template.LoginCount = template.LoginCount or 0
	template.Receipts = template.Receipts or {}
	template.RobuxSpent = template.RobuxSpent or 0

	local ok, result = pcall(function()
		local s = DataStoreService:GetDataStore(storeName)
		if RunService:IsStudio() then
			-- Throws when "Enable Studio Access to API Services" is off.
			s:GetAsync("__probe")
		end
		return s
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStores unavailable, using memory only (turn on API access in Game Settings to save):", result)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in profiles do
				task.spawn(DataService.Save, player, false)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				releasingEvent:Fire(player, profiles[player])
				DataService.Save(player, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
