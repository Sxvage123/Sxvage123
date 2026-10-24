-- Minimal Roblox API mocks so the shared server modules can run under the plain `luau` CLI.
-- Virtual-time scheduler: task.wait never really sleeps.
local H = {}

local now = 0
local sleeping = {} -- { co, wake }
local function resume(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		error(debug.traceback(co, tostring(err)), 0)
	end
end

local task = {}
function task.spawn(fn, ...)
	local co = if type(fn) == "thread" then fn else coroutine.create(fn)
	resume(co, ...)
	return co
end
function task.defer(fn, ...)
	local args = table.pack(...)
	table.insert(sleeping, { co = coroutine.create(function()
		fn(table.unpack(args, 1, args.n))
	end), wake = now })
end
function task.delay(t, fn, ...)
	local args = table.pack(...)
	table.insert(sleeping, { co = coroutine.create(function()
		fn(table.unpack(args, 1, args.n))
	end), wake = now + t })
end
function task.wait(t)
	t = t or 0
	table.insert(sleeping, { co = coroutine.running(), wake = now + t })
	coroutine.yield()
	return t
end
H.task = task

-- Advance virtual time, running everything that wakes up.
function H.advance(seconds)
	local target = now + seconds
	while true do
		table.sort(sleeping, function(a, b)
			return a.wake < b.wake
		end)
		local nextItem = sleeping[1]
		if not nextItem or nextItem.wake > target then
			break
		end
		table.remove(sleeping, 1)
		now = math.max(now, nextItem.wake)
		resume(nextItem.co)
	end
	now = target
end
function H.clock()
	return now
end

-- Signals
local Signal = {}
Signal.__index = Signal
function Signal.new()
	return setmetatable({ handlers = {} }, Signal)
end
function Signal:Connect(fn)
	table.insert(self.handlers, fn)
	return { Disconnect = function() end }
end
function Signal:Fire(...)
	for _, fn in self.handlers do
		task.spawn(fn, ...)
	end
end
H.Signal = Signal

local Instance = {}
function Instance.new(className)
	local inst = { ClassName = className, Name = className }
	if className == "BindableEvent" then
		local sig = Signal.new()
		inst.Event = sig
		function inst:Fire(...)
			sig:Fire(...)
		end
	elseif className == "RemoteEvent" then
		inst.OnServerEvent = Signal.new()
	end
	return inst
end

-- DataStore
H.storeData = {}
H.failWrites = false
local function deepCopy(v)
	if type(v) ~= "table" then
		return v
	end
	local c = {}
	for k, x in v do
		c[k] = deepCopy(x)
	end
	return c
end
local DataStoreService = {}
function DataStoreService:GetDataStore(name)
	local store = {}
	function store:UpdateAsync(key, fn)
		if H.failWrites then
			error("DataStore request failed (mock)")
		end
		local full = name .. "/" .. key
		local result = fn(deepCopy(H.storeData[full]))
		if result ~= nil then
			H.storeData[full] = deepCopy(result)
		end
		return deepCopy(result)
	end
	function store:GetAsync(key)
		return deepCopy(H.storeData[name .. "/" .. key])
	end
	return store
end

-- Players
local Players = { PlayerAdded = Signal.new(), PlayerRemoving = Signal.new(), list = {} }
function Players:GetPlayers()
	local l = {}
	for _, p in self.list do
		table.insert(l, p)
	end
	return l
end
function Players:GetPlayerByUserId(id)
	for _, p in self.list do
		if p.UserId == id then
			return p
		end
	end
	return nil
end
function H.newPlayer(userId)
	local p = { Name = "Player" .. userId, DisplayName = "Player" .. userId, UserId = userId, Parent = Players, attrs = {}, kicked = nil }
	function p:SetAttribute(k, v)
		self.attrs[k] = v
	end
	function p:GetAttribute(k)
		return self.attrs[k]
	end
	function p:Kick(msg)
		self.kicked = msg
	end
	return p
end
function H.join(p)
	table.insert(Players.list, p)
	Players.PlayerAdded:Fire(p)
end
function H.leave(p)
	local i = table.find(Players.list, p)
	if i then
		table.remove(Players.list, i)
	end
	Players.PlayerRemoving:Fire(p)
	p.Parent = nil
end

local Enum = {
	ProductPurchaseDecision = { PurchaseGranted = "PurchaseGranted", NotProcessedYet = "NotProcessedYet" },
}

local MarketplaceService = { PromptGamePassPurchaseFinished = Signal.new(), owned = {} }
function MarketplaceService:UserOwnsGamePassAsync(userId, passId)
	return self.owned[userId .. ":" .. passId] == true
end

local ReplicatedStorage = {}
local RunService = {}
function RunService:IsStudio()
	return false
end

H.bindToClose = {}
local game = { JobId = "job-A" }
function game:GetService(name)
	if name == "DataStoreService" then
		return DataStoreService
	elseif name == "Players" then
		return Players
	elseif name == "RunService" then
		return RunService
	elseif name == "MarketplaceService" then
		return MarketplaceService
	elseif name == "ReplicatedStorage" then
		return ReplicatedStorage
	end
	error("no mock for service " .. name)
end
function game:BindToClose(fn)
	table.insert(H.bindToClose, fn)
end
H.game = game
H.Players = Players
H.MarketplaceService = MarketplaceService
H.Enum = Enum

-- Simulates a fresh server (keeps DataStore contents, like real Roblox).
function H.newServer(jobId)
	Players.PlayerAdded = Signal.new()
	Players.PlayerRemoving = Signal.new()
	Players.list = {}
	MarketplaceService.PromptGamePassPurchaseFinished = Signal.new()
	MarketplaceService.ProcessReceipt = nil
	game.JobId = jobId
	H.bindToClose = {}
end

function H.shutdown()
	for _, fn in H.bindToClose do
		task.spawn(fn)
	end
end

-- Loads a module file with mocked globals. `siblings` maps script.Parent.X -> module value.
function H.load(path, siblings)
	-- tests/run.sh embeds the files into H.sources (the luau CLI has no file I/O).
	local src = H.sources[path]
	assert(src, "source not embedded: " .. path)
	local fn = assert(loadstring(src, "@" .. path))
	local parent = setmetatable({}, { __index = function(_, k)
		return { __module = k }
	end })
	-- Each loaded module sees the JobId of the server it was loaded on.
	local serverGame = setmetatable({ JobId = game.JobId }, { __index = game })
	local env = setmetatable({
		game = serverGame,
		Instance = Instance,
		Enum = Enum,
		task = task,
		script = { Parent = parent },
		require = function(m)
			local v = siblings and siblings[m.__module]
			assert(v ~= nil, "unmocked require " .. tostring(m.__module))
			return v
		end,
		os = setmetatable({ clock = H.clock, time = function()
			return 1_700_000_000 + math.floor(now)
		end }, { __index = os }),
		warn = function() end,
	}, { __index = _G })
	setfenv(fn, env)
	return fn()
end

return H
