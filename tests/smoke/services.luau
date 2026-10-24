-- Service behaviors, the DataModel, script loading and fake players for the smoke tests.
local R = require("./roblox")
local D = R.D
local task = R.task
local Signal = R.Signal
local cm = R.cm
local Enum = R.Enum

local game
local services = {}

local function service(className)
	local s = services[className]
	if not s then
		s = R.newInstance(className, true)
		s.Name = className
		s.Parent = game
		services[className] = s
	end
	return s
end

---------------------------------------------------------------- DataModel

function R.createGame()
	game = R.newInstance("DataModel", true)
	game.Name = "Game"
	R.game = game
	R.bindToClose = {}
	for _, name in { "Workspace", "Players", "Lighting", "ReplicatedStorage", "ServerScriptService", "ServerStorage", "StarterPlayer", "StarterGui", "StarterPack", "SoundService", "Teams", "TextChatService" } do
		service(name)
	end
	local terrain = R.newInstance("Terrain", true)
	terrain.Name = "Terrain"
	terrain.Parent = services.Workspace
	local camera = R.newInstance("Camera")
	camera.Name = "Camera"
	camera.Parent = services.Workspace
	services.Workspace.CurrentCamera = camera
	local sps = R.newInstance("StarterPlayerScripts", true)
	sps.Name = "StarterPlayerScripts"
	sps.Parent = services.StarterPlayer
	return game
end

cm("DataModel").GetService = function(_, name)
	local def = R.member("DataModel", "GetService")
	local _ = def
	local ok = pcall(function()
		return R.isA(name, "Instance")
	end)
	assert(ok, "bad service name")
	return service(name)
end
cm("ServiceProvider").GetService = cm("DataModel").GetService
cm("DataModel").BindToClose = function(_, fn)
	table.insert(R.bindToClose, fn)
end
cm("DataModel").get.JobId = function()
	return "smoke-job"
end
cm("DataModel").get.PlaceId = function()
	return 0
end
cm("DataModel").get.Workspace = function()
	return service("Workspace")
end

---------------------------------------------------------------- Workspace

cm("Workspace").get.Terrain = function(inst)
	return inst:FindFirstChild("Terrain")
end

R.raycastHandler = nil
cm("WorldRoot").Raycast = function(_, origin, direction, params)
	assert(D.typeof(origin) == "Vector3" and D.typeof(direction) == "Vector3", "Raycast(origin: Vector3, direction: Vector3)")
	if params ~= nil then
		assert(D.typeof(params) == "RaycastParams", "Raycast params must be RaycastParams")
	end
	if R.raycastHandler then
		return R.raycastHandler(origin, direction, params)
	end
	return nil
end
cm("WorldRoot").GetPartBoundsInRadius = function()
	return {}
end
cm("WorldRoot").GetPartsInPart = function()
	return {}
end

---------------------------------------------------------------- RunService

cm("RunService").IsStudio = function()
	return true
end
cm("RunService").IsServer = function()
	return R.context ~= "client"
end
cm("RunService").IsClient = function()
	return R.context == "client"
end
cm("RunService").BindToRenderStep = function() end

---------------------------------------------------------------- TweenService

local TweenMT = { __type = "Instance" }
cm("TweenService").Create = function(_, inst, info, goals)
	assert(D.typeof(inst) == "Instance", "TweenService:Create expects an Instance")
	assert(D.typeof(info) == "TweenInfo", "TweenService:Create expects TweenInfo")
	assert(type(goals) == "table", "TweenService:Create expects a goal table")
	-- Validate goal properties now (Roblox errors at Create time too).
	for k, v in goals do
		local m = R.member(inst.ClassName, k)
		assert(m and m.kind == "Property", "TweenService:Create no property named '" .. tostring(k) .. "' for object '" .. inst.Name .. "'")
		assert(D.typeof(v) == D.typeof(inst[k]), "TweenService:Create property " .. k .. " type mismatch")
	end
	local tween = R.newInstance("Tween", true)
	local completed = R.signalFor(tween, "Completed")
	local playing = false
	local token = 0
	local tw = {}
	function tw.Play()
		playing = true
		token += 1
		local my = token
		task.delay(info.Time + (info.DelayTime or 0), function()
			if playing and my == token then
				playing = false
				for k, v in goals do
					inst[k] = v
				end
				completed:Fire(Enum.PlaybackState.Completed)
			end
		end)
	end
	function tw.Cancel()
		if playing then
			playing = false
			completed:Fire(Enum.PlaybackState.Cancelled)
		end
	end
	function tw.Pause()
		playing = false
	end
	return setmetatable({}, {
		__type = "Instance",
		__index = function(_, k)
			if k == "Play" or k == "Cancel" or k == "Pause" then
				return function()
					tw[k]()
				end
			elseif k == "Completed" then
				return completed
			end
			return tween[k]
		end,
	})
end
local _ = TweenMT

---------------------------------------------------------------- MarketplaceService

R.prompts = {}
cm("MarketplaceService").PromptGamePassPurchase = function(_, player, id)
	assert(D.typeof(player) == "Instance" and type(id) == "number", "PromptGamePassPurchase(player, id)")
	table.insert(R.prompts, { "Pass", id })
end
cm("MarketplaceService").PromptProductPurchase = function(_, player, id)
	assert(D.typeof(player) == "Instance" and type(id) == "number", "PromptProductPurchase(player, id)")
	table.insert(R.prompts, { "Product", id })
end
cm("MarketplaceService").UserOwnsGamePassAsync = function(_, userId, id)
	assert(type(userId) == "number" and type(id) == "number", "UserOwnsGamePassAsync(userId, passId)")
	return false
end
cm("MarketplaceService").GetProductInfo = function()
	return { Name = "Item", PriceInRobux = 0 }
end

---------------------------------------------------------------- DataStoreService

R.storeData = {}
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
-- Validate DataStore values the way Roblox does (JSON-able, no mixed tables, no Instances/userdata).
local function validateStorable(v, path)
	local t = D.typeof(v)
	if t == "table" then
		local hasArray, hasHash = false, false
		for k in v do
			if type(k) == "number" then
				hasArray = true
			else
				hasHash = true
				if type(k) ~= "string" then
					error("DataStore: non-string key at " .. path)
				end
			end
			validateStorable(v[k], path .. "." .. tostring(k))
		end
		if hasArray and hasHash then
			error("DataStore: mixed array/dictionary table at " .. path)
		end
		if hasArray and #v ~= (function()
			local n = 0
			for _ in v do
				n += 1
			end
			return n
		end)() then
			error("DataStore: sparse array at " .. path)
		end
	elseif t ~= "number" and t ~= "string" and t ~= "boolean" and t ~= "nil" then
		error("DataStore: cannot store " .. t .. " at " .. path)
	end
end
cm("DataStoreService").GetDataStore = function(_, name)
	assert(type(name) == "string", "GetDataStore(name)")
	local store = {}
	function store.UpdateAsync(_, key, fn)
		task.wait(0.05)
		local full = name .. "/" .. key
		local result = fn(deepCopy(R.storeData[full]))
		if result ~= nil then
			validateStorable(result, key)
			R.storeData[full] = deepCopy(result)
		end
		return deepCopy(result)
	end
	function store.GetAsync(_, key)
		return deepCopy(R.storeData[name .. "/" .. key])
	end
	function store.SetAsync(_, key, value)
		validateStorable(value, key)
		R.storeData[name .. "/" .. key] = deepCopy(value)
	end
	return store
end

---------------------------------------------------------------- HttpService (tiny JSON)

local guid = 0
cm("HttpService").GenerateGUID = function(_, braces)
	guid += 1
	local s = string.format("%08x-0000-4000-8000-%012x", guid, guid)
	return if braces == false then s else "{" .. s .. "}"
end
local function encode(v)
	local t = type(v)
	if t == "table" then
		if #v > 0 or next(v) == nil then
			local parts = {}
			for _, x in ipairs(v) do
				table.insert(parts, encode(x))
			end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		local parts = {}
		for k, x in v do
			table.insert(parts, encode(tostring(k)) .. ":" .. encode(x))
		end
		return "{" .. table.concat(parts, ",") .. "}"
	elseif t == "string" then
		return '"' .. v:gsub('[%c"\\]', function(c)
			return string.format("\\u%04x", string.byte(c))
		end) .. '"'
	elseif t == "number" or t == "boolean" then
		return tostring(v)
	elseif v == nil then
		return "null"
	end
	error("JSONEncode: can't encode " .. t)
end
local function decode(str)
	local i = 1
	local function ws()
		i = string.find(str, "%S", i) or #str + 1
	end
	local value
	local function parseString()
		local out = {}
		i += 1
		while true do
			local c = string.sub(str, i, i)
			if c == '"' then
				i += 1
				return table.concat(out)
			elseif c == "\\" then
				local n = string.sub(str, i + 1, i + 1)
				if n == "u" then
					table.insert(out, utf8.char(tonumber(string.sub(str, i + 2, i + 5), 16) :: number))
					i += 6
				else
					local map = { n = "\n", t = "\t", r = "\r", b = "\b", f = "\f" }
					table.insert(out, map[n] or n)
					i += 2
				end
			else
				table.insert(out, c)
				i += 1
			end
		end
	end
	function value()
		ws()
		local c = string.sub(str, i, i)
		if c == "{" then
			local obj = {}
			i += 1
			ws()
			if string.sub(str, i, i) == "}" then
				i += 1
				return obj
			end
			while true do
				ws()
				local k = parseString()
				ws()
				i += 1 -- :
				obj[k] = value()
				ws()
				local d = string.sub(str, i, i)
				i += 1
				if d == "}" then
					return obj
				end
			end
		elseif c == "[" then
			local arr = {}
			i += 1
			ws()
			if string.sub(str, i, i) == "]" then
				i += 1
				return arr
			end
			while true do
				table.insert(arr, value())
				ws()
				local d = string.sub(str, i, i)
				i += 1
				if d == "]" then
					return arr
				end
			end
		elseif c == '"' then
			return parseString()
		elseif string.sub(str, i, i + 3) == "true" then
			i += 4
			return true
		elseif string.sub(str, i, i + 4) == "false" then
			i += 5
			return false
		elseif string.sub(str, i, i + 3) == "null" then
			i += 4
			return nil
		end
		local num = string.match(str, "^-?[%d%.eE+-]+", i)
		i += #num
		return tonumber(num)
	end
	return value()
end
cm("HttpService").JSONEncode = function(_, v)
	return encode(v)
end
cm("HttpService").JSONDecode = function(_, s)
	return decode(s)
end

---------------------------------------------------------------- CollectionService, Debris, Badges, Pathfinding

local tags = {}
cm("CollectionService").AddTag = function(_, inst, tag)
	tags[tag] = tags[tag] or {}
	if not table.find(tags[tag], inst) then
		table.insert(tags[tag], inst)
	end
end
cm("CollectionService").RemoveTag = function(_, inst, tag)
	local list = tags[tag]
	local i = list and table.find(list, inst)
	if i then
		table.remove(list, i)
	end
end
cm("CollectionService").HasTag = function(_, inst, tag)
	return tags[tag] ~= nil and table.find(tags[tag], inst) ~= nil
end
cm("CollectionService").GetTagged = function(_, tag)
	local out = {}
	for _, inst in tags[tag] or {} do
		if inst.Parent then
			table.insert(out, inst)
		end
	end
	return out
end
cm("Debris").AddItem = function(_, inst, t)
	task.delay(t or 10, function()
		inst:Destroy()
	end)
end
cm("BadgeService").AwardBadge = function()
	return true
end
cm("PathfindingService").CreatePath = function(_, params)
	assert(params == nil or type(params) == "table", "CreatePath(params)")
	local target = D.Vector3.zero
	return {
		Status = Enum.PathStatus.Success,
		ComputeAsync = function(_, from, to)
			assert(D.typeof(from) == "Vector3" and D.typeof(to) == "Vector3", "ComputeAsync(Vector3, Vector3)")
			target = to
		end,
		GetWaypoints = function()
			return { { Position = target, Action = Enum.PathWaypointAction.Walk }, { Position = target, Action = Enum.PathWaypointAction.Walk } }
		end,
		Blocked = Signal.new("Blocked"),
	}
end

---------------------------------------------------------------- Players

local players = {}
local nextCharacterPos = 0
function R.playerFromCharacter(character)
	for _, p in players do
		if p.Character == character then
			return p
		end
	end
	return nil
end
cm("Players").GetPlayers = function()
	local out = {}
	for _, p in players do
		if p.Parent then
			table.insert(out, p)
		end
	end
	return out
end
cm("Players").GetPlayerByUserId = function(_, id)
	for _, p in players do
		if p.UserId == id and p.Parent then
			return p
		end
	end
	return nil
end
cm("Players").GetPlayerFromCharacter = function(_, character)
	return R.playerFromCharacter(character)
end
cm("Players").get.LocalPlayer = function()
	return R.localPlayer
end

-- Player has internal props we set directly (UserId etc. are read-only in the API).
function R.addPlayer(userId)
	local p = R.newInstance("Player", true)
	local s = R.state[p]
	s.props.Name = "Player" .. userId
	s.props.DisplayName = "Player" .. userId
	s.props.UserId = userId
	local backpack = R.newInstance("Backpack", true)
	backpack.Name = "Backpack"
	backpack.Parent = p
	local gui = R.newInstance("PlayerGui", true)
	gui.Name = "PlayerGui"
	gui.Parent = p
	local scripts = R.newInstance("PlayerScripts", true)
	scripts.Name = "PlayerScripts"
	scripts.Parent = p
	table.insert(players, p)
	p.Parent = service("Players")
	R.signalFor(service("Players"), "PlayerAdded"):Fire(p)
	return p
end

function R.removePlayer(p)
	R.signalFor(service("Players"), "PlayerRemoving"):Fire(p)
	if p.Character then
		p.Character:Destroy()
	end
	p.Parent = nil
end

function R.spawnCharacter(p)
	local old = p.Character
	if old then
		old:Destroy()
	end
	local character = R.newInstance("Model")
	character.Name = p.Name
	local root = R.newInstance("Part")
	root.Name = "HumanoidRootPart"
	root.Size = D.Vector3.new(2, 2, 1)
	nextCharacterPos += 1
	root.CFrame = D.CFrame.new(nextCharacterPos * 3, 5, 0)
	root.Parent = character
	for _, spec in { { "Head", D.Vector3.new(2, 1, 1), 1.5 }, { "RightHand", D.Vector3.new(1, 0.3, 1), -1 }, { "UpperTorso", D.Vector3.new(2, 2, 1), 0 } } do
		local part = R.newInstance("Part")
		part.Name = spec[1]
		part.Size = spec[2]
		part.CFrame = root.CFrame * D.CFrame.new(0, spec[3], 0)
		part.Parent = character
	end
	local humanoid = R.newInstance("Humanoid")
	humanoid.Parent = character
	character.PrimaryPart = root
	character.Parent = service("Workspace")
	R.state[p].props.Character = character
	R.signalFor(p, "CharacterAdded"):Fire(character)
	return character
end

-- Fake mouse for the local player.
R.mouse = {
	Hit = D.CFrame.new(10, 0, 10),
	Target = nil,
	TargetFilter = nil,
	X = 640,
	Y = 360,
	Button1Down = Signal.new("Button1Down"),
	Button1Up = Signal.new("Button1Up"),
	Move = Signal.new("Move"),
}

---------------------------------------------------------------- Instance API exposed to scripts

local InstanceAPI = {
	new = function(className, parent)
		local inst = R.newInstance(className)
		if parent then
			inst.Parent = parent
		end
		return inst
	end,
}

---------------------------------------------------------------- script loading

R.sources = {}
local moduleCache = {}
function R.requireCached(m)
	local c = moduleCache[m]
	return c and c.value
end

local function makeEnv(scriptInst, context)
	local env
	env = setmetatable({
		script = scriptInst,
		game = game,
		workspace = service("Workspace"),
		Instance = InstanceAPI,
		Enum = Enum,
		Vector3 = D.Vector3,
		Vector2 = D.Vector2,
		CFrame = D.CFrame,
		Color3 = D.Color3,
		UDim = D.UDim,
		UDim2 = D.UDim2,
		NumberSequence = D.NumberSequence,
		NumberSequenceKeypoint = D.NumberSequenceKeypoint,
		ColorSequence = D.ColorSequence,
		ColorSequenceKeypoint = D.ColorSequenceKeypoint,
		NumberRange = D.NumberRange,
		TweenInfo = D.TweenInfo,
		RaycastParams = D.RaycastParams,
		Random = D.Random,
		task = task,
		typeof = D.typeof,
		tick = function()
			return R.now
		end,
		time = function()
			return R.now
		end,
		wait = task.wait,
		os = setmetatable({
			clock = function()
				return R.now
			end,
			time = function()
				return 1_700_000_000 + math.floor(R.now)
			end,
		}, { __index = os }),
		print = function() end,
		warn = function(...)
			local parts = {}
			for _, v in { ... } do
				table.insert(parts, tostring(v))
			end
			table.insert(R.warnings, "[" .. context .. "] " .. table.concat(parts, " "))
		end,
		require = function(m)
			assert(D.typeof(m) == "Instance" and m:IsA("ModuleScript"), "require expects a ModuleScript")
			local cached = moduleCache[m]
			if cached then
				return cached.value
			end
			local src = R.sources[m]
			assert(src, "no source for module " .. m:GetFullName())
			local fn, err = loadstring(src, "=" .. m:GetFullName())
			assert(fn, err)
			setfenv(fn, makeEnv(m, context))
			local value = fn()
			assert(value ~= nil, "Module " .. m:GetFullName() .. " did not return exactly one value")
			moduleCache[m] = { value = value }
			return value
		end,
	}, { __index = _G })
	return env
end

function R.runScript(scriptInst, context)
	local src = R.sources[scriptInst]
	local fn, err = loadstring(src, "=" .. scriptInst:GetFullName())
	if not fn then
		table.insert(R.errors, "compile error: " .. tostring(err))
		return
	end
	setfenv(fn, makeEnv(scriptInst, context))
	task.spawn(function()
		R.context = context
		fn()
	end)
end

-- Builds the instance tree from a manifest of { path = {...}, class = "...", source = "..." }.
function R.buildTree(manifest)
	for _, entry in manifest do
		local parent = game
		for i, name in entry.path do
			local child = parent:FindFirstChild(name)
			if not child then
				local isLast = i == #entry.path
				child = R.newInstance(if isLast then entry.class else "Folder", true)
				child.Name = name
				child.Parent = parent
			end
			parent = child
		end
		if entry.source then
			R.sources[parent] = entry.source
		end
	end
end

---------------------------------------------------------------- time

function R.advance(seconds, step)
	step = step or 1 / 20
	local target = R.now + seconds
	local runService = service("RunService")
	local heartbeat = R.signalFor(runService, "Heartbeat")
	local render = R.signalFor(runService, "RenderStepped")
	local stepped = R.signalFor(runService, "Stepped")
	while R.now < target do
		R.now = math.min(target, R.now + step)
		R.task.__runDue()
		stepped:Fire(R.now, step)
		heartbeat:Fire(step)
		if R.localPlayer then
			render:Fire(step)
		end
	end
	R.task.__runDue()
end

R.service = service
return R
