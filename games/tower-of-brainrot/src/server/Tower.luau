-- Builds a random tower out of stacked sections. Each section is a 40x40 floor area climbed via an obstacle.
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Tower = {}
Tower.Base = Vector3.new(0, 0, 0)

local folder: Folder
local rng: Random
local COLORS = {
	Color3.fromRGB(255, 99, 99), Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 230, 80), Color3.fromRGB(110, 230, 110),
	Color3.fromRGB(80, 200, 255), Color3.fromRGB(150, 110, 255), Color3.fromRGB(255, 120, 220),
}

local function part(props): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = folder
	return p
end
local function killer(props): BasePart
	props.Color = Color3.fromRGB(255, 30, 30)
	props.Material = Enum.Material.Neon
	local p = part(props)
	p:SetAttribute("Kill", true)
	return p
end

-- Every section is one lap around the shaft: it starts at the opening corner (-14, -14) on the floor and
-- climbs to just under the next floor's opening at the same corner, so any section order is beatable.
-- Default character: ~7 studs jump height, ~8 studs flat jump; all gaps below stay well inside that.
local H = Config.SectionHeight
local R = 14

local function lap(t: number): Vector3
	local d = (t % 1) * 8 * R -- perimeter distance
	if d < 2 * R then
		return Vector3.new(-R + d, 0, -R)
	elseif d < 4 * R then
		return Vector3.new(R, 0, -R + (d - 2 * R))
	elseif d < 6 * R then
		return Vector3.new(R - (d - 4 * R), 0, R)
	end
	return Vector3.new(-R, 0, R - (d - 6 * R))
end
local function rise(t: number): number
	return 1.5 + t * (H - 4)
end

-- Lava over the section floor, leaving the arrival corner (x, z < -6) safe.
local function lavaFloor(y: number)
	killer({ Size = Vector3.new(38, 0.4, 25), Position = Vector3.new(0, y + 0.3, 6.5) })
	killer({ Size = Vector3.new(25, 0.4, 13), Position = Vector3.new(6.5, y + 0.3, -12.5) })
end

local builders = {}

function builders.Stairs(y: number, color: Color3)
	for i = 1, 12 do
		local t = i / 12
		part({ Size = Vector3.new(5, 1, 5), Position = lap(t) + Vector3.new(0, y + rise(t), 0), Color = color })
	end
end
function builders.TinySteps(y: number, color: Color3)
	for i = 1, 16 do
		local t = i / 16
		part({ Size = Vector3.new(3, 1, 3), Position = lap(t) + Vector3.new(0, y + rise(t), 0), Color = color })
	end
	lavaFloor(y)
end
function builders.LavaJumps(y: number, color: Color3)
	for i = 1, 14 do
		local t = i / 14
		local wobble = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
		part({ Size = Vector3.new(4, 1, 4), Position = lap(t) + wobble * (if i == 14 then 0 else 1) + Vector3.new(0, y + rise(t), 0), Color = color })
	end
	lavaFloor(y)
end
function builders.Beams(y: number, color: Color3)
	local prev = lap(0) + Vector3.new(0, y + rise(0), 0)
	part({ Size = Vector3.new(4, 1, 4), Position = prev, Color = color })
	for i = 1, 8 do
		local t = i / 8
		local nextPos = lap(t) + Vector3.new(0, y + rise(t), 0)
		part({ Size = Vector3.new(1.4, 1, (nextPos - prev).Magnitude + 1), CFrame = CFrame.lookAt((prev + nextPos) / 2, nextPos), Color = color })
		part({ Size = Vector3.new(3, 1, 3), Position = nextPos, Color = color })
		prev = nextPos
	end
	lavaFloor(y)
end
function builders.Wallhops(y: number, color: Color3)
	for i = 1, 12 do
		local t = i / 12
		local pos = lap(t) + Vector3.new(0, y + rise(t), 0)
		part({ Size = Vector3.new(4, 1, 4), Position = pos, Color = color })
		if i < 12 then
			-- Post beside the jump line (pushed toward the shaft centre) to hop past.
			local mid = lap(t + 1 / 24)
			local inward = if mid.Magnitude > 0 then -mid.Unit * 2.6 else Vector3.zero
			part({ Size = Vector3.new(1, 6, 1), Position = mid + inward + Vector3.new(0, y + rise(t) + 3, 0), Color = Color3.fromRGB(60, 60, 70) })
		end
	end
end
function builders.Truss(y: number, color: Color3)
	-- Low walk to the far corner, climb a truss, then a flat walkway back at the top.
	for i = 1, 6 do
		local t = i / 12
		part({ Size = Vector3.new(5, 1, 5), Position = lap(t) + Vector3.new(0, y + 1.5, 0), Color = color })
	end
	local corner = lap(0.5)
	local t = Instance.new("TrussPart")
	t.Anchored = true
	t.Size = Vector3.new(2, H - 4, 2)
	t.Position = corner + Vector3.new(0, y + 2 + (H - 4) / 2, 2)
	t.Parent = folder
	for i = 6, 12 do
		local tt = i / 12
		part({ Size = Vector3.new(4, 1, 4), Position = lap(tt) + Vector3.new(0, y + H - 2.5, 0), Color = color })
	end
end

local ORDER = { "Stairs", "TinySteps", "Truss", "LavaJumps", "Wallhops", "Beams" }

-- Returns the top finish part.
function Tower.Build(): BasePart
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "Tower"
	folder.Parent = workspace
	rng = Random.new(os.time())
	part({ Name = "StartFloor", Size = Vector3.new(40, 1, 40), Position = Vector3.new(0, -0.5, 0), Color = Color3.fromRGB(230, 230, 240), Material = Enum.Material.Marble })
	for i = 0, Config.Sections - 1 do
		local y = i * H
		local color = COLORS[(i % #COLORS) + 1]
		builders[ORDER[rng:NextInteger(1, #ORDER)]](y, color)
		-- floor of the next section, with a 12x12 opening over the (-14, -14) corner where every lap ends
		part({ Size = Vector3.new(40, 1, 28), Position = Vector3.new(0, y + H - 0.5, 6), Color = color:Lerp(Color3.new(1, 1, 1), 0.3), Transparency = 0.2 })
		part({ Size = Vector3.new(28, 1, 12), Position = Vector3.new(6, y + H - 0.5, -14), Color = color:Lerp(Color3.new(1, 1, 1), 0.3), Transparency = 0.2 })
		-- glass shaft walls
		for _, s in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			part({ Size = if s[1] ~= 0 then Vector3.new(1, H, 40) else Vector3.new(40, H, 1), Position = Vector3.new(s[1] * 20.5, y + H / 2, s[2] * 20.5), Color = Color3.fromRGB(200, 230, 255), Transparency = 0.8, Material = Enum.Material.Glass })
		end
		local sign = part({ Size = Vector3.new(0.2, 0.2, 0.2), Position = Vector3.new(0, y + 3, -19), Transparency = 1, CanCollide = false })
		sign:SetAttribute("Section", i + 1)
	end
	local top = part({ Name = "Finish", Size = Vector3.new(40, 1, 40), Position = Vector3.new(0, Config.Sections * H + 0.5, 0), Color = Color3.fromRGB(255, 215, 0), Material = Enum.Material.Neon })
	return top
end

function Tower.Folder(): Folder
	return folder
end

return Tower
