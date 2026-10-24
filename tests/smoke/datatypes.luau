-- Pure-Luau implementations of the Roblox datatypes our games use (for offline smoke tests).
local D = {}

local function typed(name: string, mt)
	mt.__type = name
	mt.__index = mt.__index or mt
	return mt
end

---------------------------------------------------------------- Vector3
local V3 = typed("Vector3", {})
local function v3(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3)
end
V3.__index = function(v, k)
	if k == "Magnitude" then
		return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
	elseif k == "Unit" then
		local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
		if m == 0 then
			return v3(0 / 0, 0 / 0, 0 / 0)
		end
		return v3(v.X / m, v.Y / m, v.Z / m)
	elseif k == "x" or k == "y" or k == "z" then
		return rawget(v, string.upper(k))
	end
	local f = rawget(V3, k)
	if f then
		return f
	end
	error(tostring(k) .. " is not a valid member of Vector3", 2)
end
V3.__add = function(a, b)
	return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
V3.__sub = function(a, b)
	return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
V3.__mul = function(a, b)
	if type(a) == "number" then
		return v3(a * b.X, a * b.Y, a * b.Z)
	elseif type(b) == "number" then
		return v3(a.X * b, a.Y * b, a.Z * b)
	end
	return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	if type(b) == "number" then
		return v3(a.X / b, a.Y / b, a.Z / b)
	end
	return v3(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
V3.__unm = function(a)
	return v3(-a.X, -a.Y, -a.Z)
end
V3.__eq = function(a, b)
	return a.X == b.X and a.Y == b.Y and a.Z == b.Z
end
V3.__tostring = function(v)
	return string.format("%g, %g, %g", v.X, v.Y, v.Z)
end
function V3.Dot(a, b)
	return a.X * b.X + a.Y * b.Y + a.Z * b.Z
end
function V3.Cross(a, b)
	return v3(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
end
function V3.Lerp(a, b, t)
	return a + (b - a) * t
end
function V3.Abs(a)
	return v3(math.abs(a.X), math.abs(a.Y), math.abs(a.Z))
end
D.Vector3 = {
	new = v3,
	zero = v3(0, 0, 0),
	one = v3(1, 1, 1),
	xAxis = v3(1, 0, 0),
	yAxis = v3(0, 1, 0),
	zAxis = v3(0, 0, 1),
}

---------------------------------------------------------------- Vector2
local V2 = typed("Vector2", {})
local function v2(x, y)
	return setmetatable({ X = x or 0, Y = y or 0 }, V2)
end
V2.__index = function(v, k)
	if k == "Magnitude" then
		return math.sqrt(v.X * v.X + v.Y * v.Y)
	end
	local f = rawget(V2, k)
	if f then
		return f
	end
	error(tostring(k) .. " is not a valid member of Vector2", 2)
end
V2.__add = function(a, b)
	return v2(a.X + b.X, a.Y + b.Y)
end
V2.__sub = function(a, b)
	return v2(a.X - b.X, a.Y - b.Y)
end
V2.__mul = function(a, b)
	if type(b) == "number" then
		return v2(a.X * b, a.Y * b)
	end
	return v2(a.X * b.X, a.Y * b.Y)
end
D.Vector2 = { new = v2, zero = v2(0, 0) }

---------------------------------------------------------------- CFrame (position + 3x3 rotation, row-major)
local CF = typed("CFrame", {})
local function cf(p, r)
	return setmetatable({ p = p, r = r }, CF)
end
local IDENT = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
local function matmul(a, b)
	local o = {}
	for i = 0, 2 do
		for j = 0, 2 do
			o[i * 3 + j + 1] = a[i * 3 + 1] * b[j + 1] + a[i * 3 + 2] * b[3 + j + 1] + a[i * 3 + 3] * b[6 + j + 1]
		end
	end
	return o
end
local function rotate(r, v)
	return v3(r[1] * v.X + r[2] * v.Y + r[3] * v.Z, r[4] * v.X + r[5] * v.Y + r[6] * v.Z, r[7] * v.X + r[8] * v.Y + r[9] * v.Z)
end
local function transpose(r)
	return { r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9] }
end
CF.__index = function(c, k)
	if k == "Position" or k == "p" then
		return c.p
	elseif k == "X" then
		return c.p.X
	elseif k == "Y" then
		return c.p.Y
	elseif k == "Z" then
		return c.p.Z
	elseif k == "LookVector" then
		return -v3(c.r[3], c.r[6], c.r[9])
	elseif k == "RightVector" then
		return v3(c.r[1], c.r[4], c.r[7])
	elseif k == "UpVector" then
		return v3(c.r[2], c.r[5], c.r[8])
	elseif k == "Rotation" then
		return cf(v3(), c.r)
	end
	local f = rawget(CF, k)
	if f then
		return f
	end
	error(tostring(k) .. " is not a valid member of CFrame", 2)
end
CF.__mul = function(a, b)
	if getmetatable(b) == V3 then
		return a.p + rotate(a.r, b)
	end
	return cf(a.p + rotate(a.r, b.p), matmul(a.r, b.r))
end
CF.__add = function(a, b)
	return cf(a.p + b, a.r)
end
CF.__sub = function(a, b)
	return cf(a.p - b, a.r)
end
CF.__eq = function(a, b)
	if a.p ~= b.p then
		return false
	end
	for i = 1, 9 do
		if a.r[i] ~= b.r[i] then
			return false
		end
	end
	return true
end
CF.__tostring = function(c)
	return "CFrame(" .. tostring(c.p) .. ")"
end
function CF.Inverse(c)
	local rt = transpose(c.r)
	return cf(-rotate(rt, c.p), rt)
end
function CF.PointToObjectSpace(c, v)
	return rotate(transpose(c.r), v - c.p)
end
function CF.PointToWorldSpace(c, v)
	return c * v
end
function CF.VectorToWorldSpace(c, v)
	return rotate(c.r, v)
end
function CF.VectorToObjectSpace(c, v)
	return rotate(transpose(c.r), v)
end
function CF.ToObjectSpace(a, b)
	return a:Inverse() * b
end
function CF.Lerp(a, b, t)
	-- Position lerp + snap rotation at the end (good enough for tests).
	return cf(a.p:Lerp(b.p, t), if t < 1 then a.r else b.r)
end
function CF.GetComponents(c)
	return c.p.X, c.p.Y, c.p.Z, table.unpack(c.r)
end
local function angles(rx, ry, rz)
	local cx, sx = math.cos(rx), math.sin(rx)
	local cy, sy = math.cos(ry), math.sin(ry)
	local cz, sz = math.cos(rz), math.sin(rz)
	local Rx = { 1, 0, 0, 0, cx, -sx, 0, sx, cx }
	local Ry = { cy, 0, sy, 0, 1, 0, -sy, 0, cy }
	local Rz = { cz, -sz, 0, sz, cz, 0, 0, 0, 1 }
	return matmul(matmul(Rx, Ry), Rz)
end
D.CFrame = {
	new = function(a, b, c, ...)
		if a == nil then
			return cf(v3(), IDENT)
		elseif type(a) == "number" then
			if select("#", ...) >= 9 then
				return cf(v3(a, b, c), { ... })
			end
			return cf(v3(a, b, c), IDENT)
		elseif b ~= nil then
			return D.CFrame.lookAt(a, b)
		end
		return cf(a, IDENT)
	end,
	Angles = function(rx, ry, rz)
		return cf(v3(), angles(rx, ry, rz))
	end,
	fromEulerAnglesXYZ = function(rx, ry, rz)
		return cf(v3(), angles(rx, ry, rz))
	end,
	lookAt = function(at, target, up)
		up = up or v3(0, 1, 0)
		local look = target - at
		if look.Magnitude < 1e-9 then
			return cf(at, IDENT)
		end
		local back = (-look).Unit
		local right = up:Cross(back)
		if right.Magnitude < 1e-6 then
			right = v3(1, 0, 0)
		end
		right = right.Unit
		local upv = back:Cross(right)
		return cf(at, { right.X, upv.X, back.X, right.Y, upv.Y, back.Y, right.Z, upv.Z, back.Z })
	end,
	identity = cf(v3(), IDENT),
}

---------------------------------------------------------------- Color3
local C3 = typed("Color3", {})
local function c3(r, g, b)
	return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3)
end
C3.__index = function(c, k)
	local f = rawget(C3, k)
	if f then
		return f
	end
	error(tostring(k) .. " is not a valid member of Color3", 2)
end
C3.__eq = function(a, b)
	return a.R == b.R and a.G == b.G and a.B == b.B
end
function C3.Lerp(a, b, t)
	return c3(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end
function C3.ToHex(c)
	return string.format("%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255)
end
D.Color3 = {
	new = c3,
	fromRGB = function(r, g, b)
		assert(type(r) == "number" and type(g) == "number" and type(b) == "number", "Color3.fromRGB expects numbers")
		return c3(r / 255, g / 255, b / 255)
	end,
	fromHSV = function(h, s, v)
		assert(type(h) == "number" and type(s) == "number" and type(v) == "number", "Color3.fromHSV expects numbers")
		local i = math.floor(h * 6)
		local f = h * 6 - i
		local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
		local m = i % 6
		if m == 0 then
			return c3(v, t, p)
		elseif m == 1 then
			return c3(q, v, p)
		elseif m == 2 then
			return c3(p, v, t)
		elseif m == 3 then
			return c3(p, q, v)
		elseif m == 4 then
			return c3(t, p, v)
		end
		return c3(v, p, q)
	end,
}

---------------------------------------------------------------- UDim / UDim2
local UD = typed("UDim", {})
local function udim(s, o)
	return setmetatable({ Scale = s or 0, Offset = o or 0 }, UD)
end
UD.__add = function(a, b)
	return udim(a.Scale + b.Scale, a.Offset + b.Offset)
end
UD.__sub = function(a, b)
	return udim(a.Scale - b.Scale, a.Offset - b.Offset)
end
D.UDim = { new = udim }

local U2 = typed("UDim2", {})
local function udim2(xs, xo, ys, yo)
	return setmetatable({ X = udim(xs, xo), Y = udim(ys, yo) }, U2)
end
U2.__index = function(u, k)
	if k == "Width" then
		return u.X
	elseif k == "Height" then
		return u.Y
	end
	local f = rawget(U2, k)
	if f then
		return f
	end
	error(tostring(k) .. " is not a valid member of UDim2", 2)
end
U2.__add = function(a, b)
	return udim2(a.X.Scale + b.X.Scale, a.X.Offset + b.X.Offset, a.Y.Scale + b.Y.Scale, a.Y.Offset + b.Y.Offset)
end
U2.__sub = function(a, b)
	return udim2(a.X.Scale - b.X.Scale, a.X.Offset - b.X.Offset, a.Y.Scale - b.Y.Scale, a.Y.Offset - b.Y.Offset)
end
function U2.Lerp(a, b, t)
	return udim2(
		a.X.Scale + (b.X.Scale - a.X.Scale) * t,
		a.X.Offset + (b.X.Offset - a.X.Offset) * t,
		a.Y.Scale + (b.Y.Scale - a.Y.Scale) * t,
		a.Y.Offset + (b.Y.Offset - a.Y.Offset) * t
	)
end
D.UDim2 = {
	new = function(xs, xo, ys, yo)
		if type(xs) == "table" then
			return setmetatable({ X = xs, Y = xo }, U2)
		end
		return udim2(xs, xo, ys, yo)
	end,
	fromOffset = function(x, y)
		return udim2(0, x or 0, 0, y or 0)
	end,
	fromScale = function(x, y)
		return udim2(x or 0, 0, y or 0, 0)
	end,
}

---------------------------------------------------------------- sequences, ranges, misc
local function simple(name)
	local mt = typed(name, {})
	return function(fields)
		return setmetatable(fields, mt)
	end
end
local mkNS = simple("NumberSequence")
local mkNSK = simple("NumberSequenceKeypoint")
local mkCS = simple("ColorSequence")
local mkCSK = simple("ColorSequenceKeypoint")
local mkNR = simple("NumberRange")
local mkTI = simple("TweenInfo")
local mkRP = simple("RaycastParams")

D.NumberSequence = {
	new = function(a, b)
		if type(a) == "table" then
			return mkNS({ Keypoints = a })
		end
		return mkNS({ Keypoints = { mkNSK({ Time = 0, Value = a }), mkNSK({ Time = 1, Value = b or a }) } })
	end,
}
D.NumberSequenceKeypoint = {
	new = function(t, v)
		return mkNSK({ Time = t, Value = v })
	end,
}
D.ColorSequence = {
	new = function(a, b)
		if type(a) == "table" and getmetatable(a) ~= C3 then
			return mkCS({ Keypoints = a })
		end
		assert(getmetatable(a) == C3, "ColorSequence.new expects Color3")
		return mkCS({ Keypoints = { mkCSK({ Time = 0, Value = a }), mkCSK({ Time = 1, Value = b or a }) } })
	end,
}
D.ColorSequenceKeypoint = {
	new = function(t, v)
		assert(getmetatable(v) == C3, "ColorSequenceKeypoint expects Color3")
		return mkCSK({ Time = t, Value = v })
	end,
}
D.NumberRange = {
	new = function(a, b)
		return mkNR({ Min = a, Max = b or a })
	end,
}
D.TweenInfo = {
	new = function(time, style, direction, repeatCount, reverses, delay)
		return mkTI({ Time = time or 1, EasingStyle = style, EasingDirection = direction, RepeatCount = repeatCount or 0, Reverses = reverses, DelayTime = delay or 0 })
	end,
}
D.RaycastParams = {
	new = function()
		return mkRP({ FilterDescendantsInstances = {}, IgnoreWater = false })
	end,
}

local RandomMT = typed("Random", {})
function RandomMT.NextNumber(self, a, b)
	if a then
		return a + math.random() * (b - a)
	end
	return math.random()
end
function RandomMT.NextInteger(self, a, b)
	return math.random(a, b)
end
D.Random = {
	new = function()
		return setmetatable({}, RandomMT)
	end,
}

function D.typeof(v)
	if type(v) == "table" then
		local mt = getmetatable(v)
		if type(mt) == "table" and rawget(mt, "__type") then
			return mt.__type
		end
	end
	return type(v)
end

return D
