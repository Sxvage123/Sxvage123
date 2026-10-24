-- A small single-process Roblox emulator for smoke-testing game scripts offline.
-- Server scripts, client scripts and one or more fake players share one instance tree.
-- Every property/event/enum is validated against the real API dump (REFLECTION).
local D = require("./datatypes")

local R = {}
R.errors = {}
R.warnings = {}
R.now = 0
R.unimplemented = {}

local REFLECTION -- set by R.init

---------------------------------------------------------------- scheduler

local queue = {}
local function report(err, co)
	local msg = debug.traceback(co, tostring(err))
	table.insert(R.errors, msg)
end
local function resume(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		report(err, co)
	end
end

local task = {}
function task.spawn(fn, ...)
	local co = if type(fn) == "thread" then fn else coroutine.create(fn)
	resume(co, ...)
	return co
end
function task.defer(fn, ...)
	local co = if type(fn) == "thread" then fn else coroutine.create(fn)
	table.insert(queue, { co = co, wake = R.now, args = table.pack(...) })
	return co
end
function task.delay(t, fn, ...)
	local co = if type(fn) == "thread" then fn else coroutine.create(fn)
	table.insert(queue, { co = co, wake = R.now + (t or 0), args = table.pack(...) })
	return co
end
function task.wait(t)
	local co = coroutine.running()
	assert(coroutine.isyieldable(), "task.wait called from a non-yieldable context")
	t = math.max(t or 0, 1 / 60)
	table.insert(queue, { co = co, wake = R.now + t, args = table.pack(t) })
	return coroutine.yield()
end
function task.cancel(co)
	for i = #queue, 1, -1 do
		if queue[i].co == co then
			table.remove(queue, i)
		end
	end
end
R.task = task

local function runDue()
	while true do
		local bestIndex, best = nil, nil
		for i, item in queue do
			if item.wake <= R.now and (best == nil or item.wake < best.wake) then
				bestIndex, best = i, item
			end
		end
		if not bestIndex then
			return
		end
		table.remove(queue, bestIndex)
		if coroutine.status(best.co) == "suspended" then
			resume(best.co, table.unpack(best.args, 1, best.args.n))
		end
	end
end

task.__runDue = function()
	runDue()
end

---------------------------------------------------------------- signals

local Signal = {}
Signal.__index = Signal
Signal.__type = "RBXScriptSignal"
function Signal.new(name)
	return setmetatable({ handlers = {}, waiting = {}, name = name }, Signal)
end
function Signal:Connect(fn)
	assert(type(fn) == "function", "Attempt to connect failed: Passed value is not a function")
	local conn
	conn = setmetatable({ Connected = true }, { __type = "RBXScriptConnection" })
	function conn.Disconnect()
		conn.Connected = false
		local i = table.find(self.handlers, fn)
		if i then
			table.remove(self.handlers, i)
		end
	end
	table.insert(self.handlers, fn)
	return conn
end
function Signal:Once(fn)
	local conn
	conn = self:Connect(function(...)
		conn:Disconnect()
		fn(...)
	end)
	return conn
end
function Signal:Wait()
	table.insert(self.waiting, coroutine.running())
	return coroutine.yield()
end
function Signal:Fire(...)
	for _, fn in table.clone(self.handlers) do
		task.spawn(fn, ...)
	end
	local waiting = self.waiting
	self.waiting = {}
	for _, co in waiting do
		resume(co, ...)
	end
end
R.Signal = Signal

---------------------------------------------------------------- enums

local enumTypes = {}
local EnumItemMT = { __type = "EnumItem" }
EnumItemMT.__index = EnumItemMT
EnumItemMT.__tostring = function(e)
	return "Enum." .. e.EnumType.Name .. "." .. e.Name
end
local EnumTypeMT = { __type = "Enum" }
EnumTypeMT.__index = function(t, k)
	if k == "GetEnumItems" then
		return function()
			local list = {}
			for _, item in t.items do
				table.insert(list, item)
			end
			return list
		end
	end
	local item = t.items[k]
	if not item then
		error(tostring(k) .. " is not a valid member of Enum." .. t.Name, 2)
	end
	return item
end
local Enum = setmetatable({}, {
	__index = function(_, name)
		local cached = enumTypes[name]
		if cached then
			return cached
		end
		local def = REFLECTION.Enums[name]
		if not def then
			error(tostring(name) .. " is not a valid EnumItem", 2)
		end
		local t = setmetatable({ Name = name, items = {} }, EnumTypeMT)
		for itemName, value in def do
			t.items[itemName] = setmetatable({ Name = itemName, Value = value, EnumType = t }, EnumItemMT)
		end
		enumTypes[name] = t
		return t
	end,
})
R.Enum = Enum

---------------------------------------------------------------- reflection helpers

local memberCache = {}
local function member(className, name)
	local key = className .. "." .. name
	local cached = memberCache[key]
	if cached ~= nil then
		return cached or nil
	end
	local c = className
	local found = false
	while c and c ~= "" do
		local def = REFLECTION.Classes[c]
		if not def then
			break
		end
		if def.P[name] then
			found = { kind = "Property", vtype = def.P[name] }
			break
		elseif def.E[name] then
			found = { kind = "Event" }
			break
		elseif def.F[name] then
			found = { kind = "Function" }
			break
		elseif def.CB[name] then
			found = { kind = "Callback" }
			break
		end
		c = def.S
	end
	memberCache[key] = found
	return found or nil
end

local function isA(className, target)
	local c = className
	while c and c ~= "" do
		if c == target then
			return true
		end
		local def = REFLECTION.Classes[c]
		c = def and def.S
	end
	return false
end

---------------------------------------------------------------- instances

local state = setmetatable({}, { __mode = "k" })
local InstanceMT = { __type = "Instance" }
local methods = {}
local classMethods = {}
local defaults = {}
local nextDebugId = 0

local function S(inst)
	local s = state[inst]
	if not s then
		error("not an Instance", 3)
	end
	return s
end

local function deepCopyArg(v, seen)
	if type(v) ~= "table" or getmetatable(v) ~= nil then
		return v
	end
	seen = seen or {}
	if seen[v] then
		error("Cyclic table passed through a remote", 3)
	end
	seen[v] = true
	local c = {}
	for k, x in v do
		c[k] = deepCopyArg(x, seen)
	end
	return c
end

local function defaultFor(className, name, vtype)
	for c, overrides in defaults do
		if overrides[name] ~= nil and isA(className, c) then
			local v = overrides[name]
			if type(v) == "function" then
				return v()
			end
			return v
		end
	end
	local category, typeName = string.match(vtype, "^(%w*):(%w*)")
	if category == "Primitive" then
		if typeName == "bool" then
			return false
		elseif typeName == "string" then
			return ""
		end
		return 0
	elseif category == "DataType" then
		if typeName == "Vector3" then
			return D.Vector3.zero
		elseif typeName == "Vector2" then
			return D.Vector2.zero
		elseif typeName == "CFrame" then
			return D.CFrame.identity
		elseif typeName == "Color3" then
			return D.Color3.new(0.64, 0.64, 0.65)
		elseif typeName == "UDim2" then
			return D.UDim2.new(0, 0, 0, 0)
		elseif typeName == "UDim" then
			return D.UDim.new(0, 0)
		elseif typeName == "Content" or typeName == "ContentId" then
			return ""
		elseif typeName == "NumberRange" then
			return D.NumberRange.new(0)
		end
		return nil
	elseif category == "Enum" then
		local items = Enum[typeName]:GetEnumItems()
		table.sort(items, function(a, b)
			return a.Value < b.Value
		end)
		return items[1]
	end
	return nil
end

local function checkType(className, name, vtype, value)
	local category, typeName = string.match(vtype, "^(%w*):(%w*)")
	local t = D.typeof(value)
	local ok = true
	if category == "Primitive" then
		if typeName == "bool" then
			ok = t == "boolean"
		elseif typeName == "string" then
			ok = t == "string" or t == "number"
		else
			ok = t == "number"
		end
	elseif category == "DataType" then
		if typeName == "Content" or typeName == "ContentId" then
			ok = t == "string"
		elseif typeName == "Font" or typeName == "PhysicalProperties" or typeName == "Rect" or typeName == "Faces" or typeName == "Axes" then
			ok = true
		else
			ok = t == typeName
		end
	elseif category == "Enum" then
		if t == "EnumItem" then
			ok = value.EnumType.Name == typeName
		else
			ok = t == "string" or t == "number"
		end
	elseif category == "Class" then
		ok = value == nil or (t == "Instance" and isA(value.ClassName, typeName))
	end
	if not ok then
		error(string.format("Unable to assign property %s.%s. %s expected, got %s", className, name, typeName, t), 3)
	end
end

local newInstance

local function fireChanged(inst, name)
	local s = state[inst]
	local sig = s.propSignals[name]
	if sig then
		sig:Fire()
	end
	local changed = s.signals.Changed
	if changed then
		changed:Fire(name)
	end
end

local function signalFor(inst, name)
	local s = S(inst)
	local sig = s.signals[name]
	if not sig then
		sig = Signal.new(name)
		s.signals[name] = sig
	end
	return sig
end
R.signalFor = signalFor

local function setParent(inst, parent)
	local s = S(inst)
	if s.destroyed then
		error("The Parent property of " .. s.props.Name .. " is locked", 3)
	end
	if parent ~= nil and D.typeof(parent) ~= "Instance" then
		error("Parent must be an Instance", 3)
	end
	local old = s.parent
	if old == parent then
		return
	end
	if old then
		local os_ = state[old]
		local i = table.find(os_.children, inst)
		if i then
			table.remove(os_.children, i)
		end
		if os_.signals.ChildRemoved then
			os_.signals.ChildRemoved:Fire(inst)
		end
	end
	s.parent = parent
	if parent then
		table.insert(state[parent].children, inst)
		if state[parent].signals.ChildAdded then
			state[parent].signals.ChildAdded:Fire(inst)
		end
		local a = parent
		while a do
			local as = state[a]
			if as.signals.DescendantAdded then
				as.signals.DescendantAdded:Fire(inst)
			end
			a = as.parent
		end
	end
	if s.signals.AncestryChanged then
		s.signals.AncestryChanged:Fire(inst, parent)
	end
end

InstanceMT.__index = function(inst, k)
	local s = state[inst]
	if k == "ClassName" then
		return s.className
	elseif k == "Parent" then
		return s.parent
	elseif k == "Name" then
		return s.props.Name
	end
	local c = s.className
	while c and c ~= "" do
		local cmeth = classMethods[c]
		if cmeth and cmeth.get and cmeth.get[k] then
			return cmeth.get[k](inst, s)
		end
		local def = REFLECTION.Classes[c]
		c = def and def.S
	end
	local m = member(s.className, k)
	if m then
		if m.kind == "Property" then
			local v = s.props[k]
			if v == nil and not s.nilProps[k] then
				v = defaultFor(s.className, k, m.vtype)
			end
			return v
		elseif m.kind == "Event" then
			return signalFor(inst, k)
		elseif m.kind == "Function" then
			local c = s.className
			while c and c ~= "" do
				local cmeth = classMethods[c]
				if cmeth and cmeth[k] then
					return cmeth[k]
				end
				local def = REFLECTION.Classes[c]
				c = def and def.S
			end
			if methods[k] then
				return methods[k]
			end
			return function()
				R.unimplemented[s.className .. ":" .. k] = true
				return nil
			end
		elseif m.kind == "Callback" then
			return s.props[k]
		end
	end
	for _, child in s.children do
		if state[child].props.Name == k then
			return child
		end
	end
	error(tostring(k) .. " is not a valid member of " .. s.className .. ' "' .. tostring(s.props.Name) .. '"', 2)
end

InstanceMT.__newindex = function(inst, k, v)
	local s = state[inst]
	if s.destroyed and k ~= "Parent" then
		-- Roblox allows setting properties on destroyed instances; just ignore.
	end
	if k == "Parent" then
		setParent(inst, v)
		return
	elseif k == "Name" then
		s.props.Name = tostring(v)
		fireChanged(inst, "Name")
		return
	end
	local cm = classMethods[s.className]
	local m = member(s.className, k)
	if not m or (m.kind ~= "Property" and m.kind ~= "Callback") then
		error(tostring(k) .. " is not a valid member of " .. s.className, 2)
	end
	if m.kind == "Property" then
		if string.sub(m.vtype, -2) == ":R" then
			error("Unable to assign property " .. k .. ". Property is read only", 2)
		end
		checkType(s.className, k, m.vtype, v)
	end
	-- class-specific setters (e.g. BasePart Position <-> CFrame)
	local c = s.className
	while c and c ~= "" do
		local cmeth = classMethods[c]
		if cmeth and cmeth.set and cmeth.set[k] then
			cmeth.set[k](inst, s, v)
			fireChanged(inst, k)
			return
		end
		local def = REFLECTION.Classes[c]
		c = def and def.S
	end
	s.props[k] = v
	s.nilProps[k] = v == nil or nil
	fireChanged(inst, k)
	if cm and cm.after and cm.after[k] then
		cm.after[k](inst, s, v)
	end
end
InstanceMT.__tostring = function(inst)
	return state[inst].props.Name
end

newInstance = function(className, isService)
	local def = REFLECTION.Classes[className]
	if not def then
		error("Unable to create an Instance of type \"" .. tostring(className) .. "\"", 3)
	end
	if not isService and (def.NC or def.SV) then
		error("Unable to create an Instance of type \"" .. className .. "\" (not creatable)", 3)
	end
	local inst = setmetatable({}, InstanceMT)
	nextDebugId += 1
	state[inst] = {
		className = className,
		props = { Name = className },
		nilProps = {},
		children = {},
		parent = nil,
		attributes = {},
		signals = {},
		propSignals = {},
		attrSignals = {},
		destroyed = false,
		id = nextDebugId,
	}
	local init = classMethods[className] and classMethods[className].init
	local c = className
	while c and c ~= "" do
		local cmeth = classMethods[c]
		if cmeth and cmeth.init then
			cmeth.init(inst, state[inst])
		end
		local d = REFLECTION.Classes[c]
		c = d and d.S
	end
	local _ = init
	return inst
end
R.newInstance = newInstance

---------------------------------------------------------------- generic Instance methods

function methods.Destroy(inst)
	local s = S(inst)
	if s.destroyed then
		return -- Roblox allows destroying twice
	end
	if s.signals.Destroying then
		s.signals.Destroying:Fire()
	end
	for _, child in table.clone(s.children) do
		child:Destroy()
	end
	setParent(inst, nil)
	s.destroyed = true
	for _, sig in s.signals do
		table.clear(sig.handlers)
	end
end
function methods.ClearAllChildren(inst)
	for _, child in table.clone(S(inst).children) do
		child:Destroy()
	end
end
function methods.GetChildren(inst)
	return table.clone(S(inst).children)
end
function methods.GetDescendants(inst)
	local out = {}
	local function walk(i)
		for _, child in state[i].children do
			table.insert(out, child)
			walk(child)
		end
	end
	walk(inst)
	return out
end
function methods.FindFirstChild(inst, name, recursive)
	assert(name ~= nil, "Argument 1 missing or nil")
	for _, child in S(inst).children do
		if state[child].props.Name == name then
			return child
		end
	end
	if recursive then
		for _, child in S(inst).children do
			local found = child:FindFirstChild(name, true)
			if found then
				return found
			end
		end
	end
	return nil
end
function methods.FindFirstChildOfClass(inst, className)
	for _, child in S(inst).children do
		if state[child].className == className then
			return child
		end
	end
	return nil
end
function methods.FindFirstChildWhichIsA(inst, className, recursive)
	for _, child in S(inst).children do
		if isA(state[child].className, className) then
			return child
		end
	end
	if recursive then
		for _, child in S(inst).children do
			local found = child:FindFirstChildWhichIsA(className, true)
			if found then
				return found
			end
		end
	end
	return nil
end
function methods.FindFirstAncestor(inst, name)
	local a = S(inst).parent
	while a do
		if state[a].props.Name == name then
			return a
		end
		a = state[a].parent
	end
	return nil
end
function methods.FindFirstAncestorOfClass(inst, className)
	local a = S(inst).parent
	while a do
		if state[a].className == className then
			return a
		end
		a = state[a].parent
	end
	return nil
end
function methods.FindFirstAncestorWhichIsA(inst, className)
	local a = S(inst).parent
	while a do
		if isA(state[a].className, className) then
			return a
		end
		a = state[a].parent
	end
	return nil
end
function methods.IsA(inst, className)
	return isA(S(inst).className, className)
end
function methods.IsDescendantOf(inst, other)
	local a = S(inst).parent
	while a do
		if a == other then
			return true
		end
		a = state[a].parent
	end
	return false
end
function methods.IsAncestorOf(inst, other)
	return other:IsDescendantOf(inst)
end
function methods.GetFullName(inst)
	local parts = {}
	local a = inst
	while a and state[a].className ~= "DataModel" do
		table.insert(parts, 1, state[a].props.Name)
		a = state[a].parent
	end
	return table.concat(parts, ".")
end
function methods.WaitForChild(inst, name, timeout)
	local start = R.now
	local warned = false
	while true do
		local child = inst:FindFirstChild(name)
		if child then
			return child
		end
		if timeout and R.now - start >= timeout then
			return nil
		end
		if not warned and R.now - start >= 5 then
			warned = true
			table.insert(R.warnings, "Infinite yield possible on '" .. inst:GetFullName() .. ":WaitForChild(\"" .. tostring(name) .. "\")'")
		end
		task.wait(0.1)
	end
end
local function validAttribute(v)
	local t = D.typeof(v)
	return v == nil
		or t == "boolean"
		or t == "number"
		or t == "string"
		or t == "Vector3"
		or t == "Vector2"
		or t == "CFrame"
		or t == "Color3"
		or t == "UDim"
		or t == "UDim2"
		or t == "NumberRange"
		or t == "NumberSequence"
		or t == "ColorSequence"
		or t == "EnumItem"
end
function methods.SetAttribute(inst, name, value)
	assert(type(name) == "string", "Attribute name must be a string")
	if not validAttribute(value) then
		error("SetAttribute: type " .. D.typeof(value) .. " is not supported for attribute " .. name, 2)
	end
	local s = S(inst)
	if s.attributes[name] == value then
		return
	end
	s.attributes[name] = value
	local sig = s.attrSignals[name]
	if sig then
		sig:Fire()
	end
	if s.signals.AttributeChanged then
		s.signals.AttributeChanged:Fire(name)
	end
end
function methods.GetAttribute(inst, name)
	return S(inst).attributes[name]
end
function methods.GetAttributes(inst)
	return table.clone(S(inst).attributes)
end
function methods.GetAttributeChangedSignal(inst, name)
	local s = S(inst)
	local sig = s.attrSignals[name]
	if not sig then
		sig = Signal.new("attr:" .. name)
		s.attrSignals[name] = sig
	end
	return sig
end
function methods.GetPropertyChangedSignal(inst, name)
	local s = S(inst)
	if not member(s.className, name) then
		error(name .. " is not a valid property name.", 2)
	end
	local sig = s.propSignals[name]
	if not sig then
		sig = Signal.new("prop:" .. name)
		s.propSignals[name] = sig
	end
	return sig
end
function methods.Clone(inst)
	local s = S(inst)
	local copy = newInstance(s.className, true)
	local cs = state[copy]
	for k, v in s.props do
		cs.props[k] = v
	end
	for k, v in s.attributes do
		cs.attributes[k] = v
	end
	for _, child in s.children do
		child:Clone().Parent = copy
	end
	return copy
end
function methods.GetDebugId(inst)
	return tostring(S(inst).id)
end
R.methods = methods

---------------------------------------------------------------- class behaviors

local function cm(className)
	classMethods[className] = classMethods[className] or { get = {}, set = {}, after = {} }
	return classMethods[className]
end

-- BasePart: CFrame is the source of truth for Position.
cm("BasePart").get.Position = function(_, s)
	return (s.props.CFrame or D.CFrame.identity).Position
end
cm("BasePart").set.Position = function(_, s, v)
	local old = s.props.CFrame or D.CFrame.identity
	s.props.CFrame = old - old.Position + v
end
cm("BasePart").get.Orientation = function()
	return D.Vector3.zero
end
cm("BasePart").set.Orientation = function() end
cm("BasePart").SetNetworkOwner = function(inst)
	if inst.Anchored then
		error("Network Ownership API cannot be called on Anchored parts or parts welded to Anchored parts", 2)
	end
	if not inst:IsDescendantOf(R.game.Workspace) then
		error("Can only call Network Ownership API on a part that is descendent of Workspace", 2)
	end
end
cm("BasePart").GetNetworkOwner = function()
	return nil
end
cm("BasePart").GetPivot = function(inst)
	return inst.CFrame
end
cm("BasePart").PivotTo = function(inst, cframe)
	inst.CFrame = cframe
end
cm("BasePart").GetTouchingParts = function()
	return {}
end
cm("BasePart").GetMass = function()
	return 1
end
cm("BasePart").ApplyImpulse = function() end

defaults.BasePart = { Size = function()
	return D.Vector3.new(4, 1.2, 2)
end, Transparency = 0, CanCollide = true, CanTouch = true, CanQuery = true, Anchored = false }
defaults.Part = { Shape = function()
	return Enum.PartType.Block
end }
defaults.Humanoid = { Health = 100, MaxHealth = 100, WalkSpeed = 16, JumpPower = 50, HipHeight = 2, UseJumpPower = true }
defaults.GuiObject = { Visible = true }
defaults.LayerCollector = { Enabled = true }
defaults.ProximityPrompt = { Enabled = true, MaxActivationDistance = 10 }
defaults.Camera = { ViewportSize = function()
	return D.Vector2.new(1280, 720)
end }
defaults.Workspace = { Gravity = 196.2 }
defaults.Beam = { Enabled = true }
defaults.ParticleEmitter = { Enabled = true }

-- Models
local function firstPart(model)
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			return d
		end
	end
	return nil
end
cm("PVInstance").GetPivot = function(inst)
	local p = firstPart(inst)
	return if p then p.CFrame else D.CFrame.identity
end
cm("PVInstance").PivotTo = function(inst, cframe)
	assert(D.typeof(cframe) == "CFrame", "PivotTo expects a CFrame")
	local p = firstPart(inst)
	if not p then
		return
	end
	local delta = cframe * p.CFrame:Inverse()
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			d.CFrame = delta * d.CFrame
		end
	end
end
cm("Model").GetBoundingBox = function(inst)
	return inst:GetPivot(), D.Vector3.new(4, 4, 4)
end
cm("Model").GetExtentsSize = function()
	return D.Vector3.new(4, 4, 4)
end
cm("Model").SetPrimaryPartCFrame = function(inst, cframe)
	inst:PivotTo(cframe)
end

-- Humanoid
cm("Humanoid").after.Health = function(inst, s, v)
	if v <= 0 and not s.dead then
		s.dead = true
		signalFor(inst, "Died"):Fire()
		-- Roblox respawns after RespawnTime (5s).
		local character = inst.Parent
		local player = character and R.playerFromCharacter(character)
		if player then
			task.delay(5, function()
				if player.Parent and player.Character == character then
					R.spawnCharacter(player)
				end
			end)
		end
	end
end
cm("Humanoid").MoveTo = function() end
cm("Humanoid").SetStateEnabled = function() end
cm("Humanoid").ChangeState = function() end
cm("Humanoid").TakeDamage = function(inst, amount)
	inst.Health -= amount
end
cm("Humanoid").GetState = function()
	return Enum.HumanoidStateType.Running
end

-- Remotes (single process: client and server share them)
cm("RemoteEvent").FireServer = function(inst, ...)
	assert(R.localPlayer, "FireServer can only be called from the client")
	local args = deepCopyArg(table.pack(...))
	signalFor(inst, "OnServerEvent"):Fire(R.localPlayer, table.unpack(args, 1, args.n))
end
cm("RemoteEvent").FireClient = function(inst, player, ...)
	assert(D.typeof(player) == "Instance" and player:IsA("Player"), "FireClient: player argument must be a Player")
	if player == R.localPlayer then
		signalFor(inst, "OnClientEvent"):Fire(...)
	end
end
cm("RemoteEvent").FireAllClients = function(inst, ...)
	if R.localPlayer then
		signalFor(inst, "OnClientEvent"):Fire(...)
	end
end
cm("RemoteFunction").InvokeServer = function(inst, ...)
	local cb = state[inst].props.OnServerInvoke
	local waited = 0
	while not cb do
		task.wait(0.1)
		waited += 0.1
		cb = state[inst].props.OnServerInvoke
		if waited > 10 then
			error("InvokeServer on " .. inst:GetFullName() .. " never got an OnServerInvoke", 2)
		end
	end
	local args = deepCopyArg(table.pack(...))
	return cb(R.localPlayer, table.unpack(args, 1, args.n))
end
cm("BindableEvent").Fire = function(inst, ...)
	signalFor(inst, "Event"):Fire(...)
end

-- Sounds, tweens etc.
cm("Sound").Play = function() end
cm("Sound").Stop = function() end
cm("ParticleEmitter").Emit = function() end

-- Terrain
cm("Terrain").FillBlock = function(_, cframe, size, material)
	assert(D.typeof(cframe) == "CFrame" and D.typeof(size) == "Vector3" and D.typeof(material) == "EnumItem", "FillBlock(CFrame, Vector3, Material)")
end
cm("Terrain").FillBall = function() end

-- Player
cm("Player").Kick = function(inst, msg)
	state[inst].kicked = msg or ""
	table.insert(R.warnings, "Player kicked: " .. tostring(msg))
end
cm("Player").LoadCharacter = function(inst)
	R.spawnCharacter(inst)
end
cm("Player").GetMouse = function(inst)
	assert(inst == R.localPlayer, "GetMouse can only be called on the LocalPlayer")
	return R.mouse
end

R.state = state
R.classMethods = classMethods
R.cm = cm
R.isA = isA
R.member = member
R.deepCopyArg = deepCopyArg

function R.init(reflection)
	REFLECTION = reflection
end

R.D = D
return R
