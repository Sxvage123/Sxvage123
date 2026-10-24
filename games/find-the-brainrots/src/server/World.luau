-- Builds every zone and returns hiding spots: { Position, Hint } in a fixed order.
local World = {}

local folder: Folder
local function part(props): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = folder
	return p
end

local function truss(bottom: Vector3, height: number)
	local t = Instance.new("TrussPart")
	t.Anchored = true
	t.Size = Vector3.new(2, height, 2)
	t.Position = bottom + Vector3.new(0, height / 2, 0)
	t.Parent = folder
end

local spots = {}
local function spot(position: Vector3, hint: string)
	table.insert(spots, { Position = position, Hint = hint })
end

-- Hollow house with a door gap, a roof you can reach by ladder.
local function house(center: Vector3, color: Color3, zone: string)
	local w, h = 16, 10
	part({ Size = Vector3.new(w, 1, w), Position = center + Vector3.new(0, 0.5, 0), Color = Color3.fromRGB(150, 120, 90), Material = Enum.Material.WoodPlanks })
	part({ Size = Vector3.new(w, h, 1), Position = center + Vector3.new(0, h / 2 + 1, w / 2), Color = color, Material = Enum.Material.Brick })
	part({ Size = Vector3.new(1, h, w), Position = center + Vector3.new(w / 2, h / 2 + 1, 0), Color = color, Material = Enum.Material.Brick })
	part({ Size = Vector3.new(1, h, w), Position = center + Vector3.new(-w / 2, h / 2 + 1, 0), Color = color, Material = Enum.Material.Brick })
	-- front wall with a door
	part({ Size = Vector3.new(5.5, h, 1), Position = center + Vector3.new(-5.25, h / 2 + 1, -w / 2), Color = color, Material = Enum.Material.Brick })
	part({ Size = Vector3.new(5.5, h, 1), Position = center + Vector3.new(5.25, h / 2 + 1, -w / 2), Color = color, Material = Enum.Material.Brick })
	part({ Size = Vector3.new(5, 3, 1), Position = center + Vector3.new(0, h - 0.5, -w / 2), Color = color, Material = Enum.Material.Brick })
	part({ Size = Vector3.new(w + 2, 1, w + 2), Position = center + Vector3.new(0, h + 1.5, 0), Color = Color3.fromRGB(140, 50, 40), Material = Enum.Material.Slate })
	truss(center + Vector3.new(w / 2 + 1.5, 0, 4), h + 2)
	spot(center + Vector3.new(4, 2.5, 5), "Inside a house in " .. zone)
	spot(center + Vector3.new(-4, h + 3.5, -4), "On a roof in " .. zone .. " (find the ladder!)")
end

local function tree(base: Vector3)
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(14, 3, 3), CFrame = CFrame.new(base + Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.Wood })
	part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 12, Position = base + Vector3.new(0, 16, 0), Color = Color3.fromRGB(60, 150, 60), Material = Enum.Material.Grass, CanCollide = false })
end

-- Stepped pyramid: 2-stud steps are easy to walk up.
local function pyramid(center: Vector3, layers: number, zone: string)
	for i = 0, layers - 1 do
		local size = (layers - i) * 6
		part({ Size = Vector3.new(size, 2, size), Position = center + Vector3.new(0, 1 + i * 2, 0), Color = Color3.fromRGB(225, 195, 120), Material = Enum.Material.Sandstone })
	end
	spot(center + Vector3.new(0, layers * 2 + 1.5, 0), "On top of a pyramid in the " .. zone)
end

local function tower(base: Vector3, height: number, zone: string, color: Color3)
	part({ Size = Vector3.new(8, height, 8), Position = base + Vector3.new(0, height / 2, 0), Color = color, Material = Enum.Material.Concrete })
	truss(base + Vector3.new(5, 0, 0), height)
	spot(base + Vector3.new(0, height + 1.5, 0), "On top of a tall tower in " .. zone)
end

function World.Build()
	folder = Instance.new("Folder")
	folder.Name = "World"
	folder.Parent = workspace
	local rng = Random.new(7)

	-- Ground for each land zone
	part({ Name = "TownGround", Size = Vector3.new(180, 2, 180), Position = Vector3.new(0, -1, 0), Color = Color3.fromRGB(110, 200, 100), Material = Enum.Material.Grass })
	part({ Name = "ForestGround", Size = Vector3.new(160, 2, 180), Position = Vector3.new(220, -1, 0), Color = Color3.fromRGB(70, 140, 60), Material = Enum.Material.Grass })
	part({ Name = "DesertGround", Size = Vector3.new(160, 2, 180), Position = Vector3.new(-220, -1, 0), Color = Color3.fromRGB(235, 210, 150), Material = Enum.Material.Sand })
	part({ Name = "Bridge", Size = Vector3.new(400, 1, 10), Position = Vector3.new(0, -0.5, 0), Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.WoodPlanks })

	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Neutral = true
	spawn.Color = Color3.fromRGB(255, 215, 0)
	spawn.Material = Enum.Material.Neon
	spawn.Parent = folder

	-- Town: 6 houses + a clock tower
	local colors = { Color3.fromRGB(240, 120, 120), Color3.fromRGB(120, 170, 240), Color3.fromRGB(250, 220, 120), Color3.fromRGB(150, 220, 150), Color3.fromRGB(220, 150, 230), Color3.fromRGB(240, 170, 110) }
	local housePositions = { Vector3.new(-50, 0, -50), Vector3.new(0, 0, -55), Vector3.new(50, 0, -50), Vector3.new(-50, 0, 50), Vector3.new(0, 0, 55), Vector3.new(50, 0, 50) }
	for i, pos in housePositions do
		house(pos, colors[i], "Town")
	end
	tower(Vector3.new(-65, 0, 0), 40, "Town", Color3.fromRGB(200, 200, 210))
	spot(Vector3.new(70, 1.5, 0), "Behind the fountain in Town")
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 14, 14), CFrame = CFrame.new(60, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(180, 180, 190), Material = Enum.Material.Marble })

	-- Forest: trees, a log cabin, a lookout tower
	for _ = 1, 40 do
		tree(Vector3.new(220 + rng:NextNumber(-70, 70), 0, rng:NextNumber(-80, 80)))
	end
	house(Vector3.new(200, 0, -40), Color3.fromRGB(130, 90, 60), "the Forest")
	house(Vector3.new(250, 0, 50), Color3.fromRGB(110, 80, 55), "the Forest")
	tower(Vector3.new(270, 0, -60), 55, "the Forest", Color3.fromRGB(120, 90, 60))
	for i = 1, 5 do
		spot(Vector3.new(220 + rng:NextNumber(-60, 60), 1.5, rng:NextNumber(-70, 70)), "Hidden between the trees in the Forest (#" .. i .. ")")
	end

	-- Desert: pyramids and a ruin
	pyramid(Vector3.new(-200, 0, -40), 9, "Desert")
	pyramid(Vector3.new(-250, 0, 40), 6, "Desert")
	pyramid(Vector3.new(-170, 0, 60), 4, "Desert")
	house(Vector3.new(-260, 0, -60), Color3.fromRGB(200, 170, 110), "the Desert")
	for i = 1, 4 do
		local base = Vector3.new(-220 + rng:NextNumber(-60, 60), 0, rng:NextNumber(-80, 80))
		part({ Size = Vector3.new(2, 8, 2), Position = base + Vector3.new(0, 4, 0), Color = Color3.fromRGB(70, 160, 70), Material = Enum.Material.Grass })
		spot(base + Vector3.new(2, 1.5, 0), "Next to a cactus in the Desert (#" .. i .. ")")
	end

	-- Pond: real water, brainrots on the bottom and on a little island
	workspace.Terrain:FillBlock(CFrame.new(0, -6, 150), Vector3.new(100, 12, 100), Enum.Material.Water)
	part({ Name = "PondFloor", Size = Vector3.new(100, 2, 100), Position = Vector3.new(0, -13, 150), Color = Color3.fromRGB(190, 170, 130), Material = Enum.Material.Sand })
	for _, rim in {
		{ Vector3.new(120, 2, 10), Vector3.new(0, -1, 95) },
		{ Vector3.new(120, 2, 10), Vector3.new(0, -1, 205) },
		{ Vector3.new(10, 2, 120), Vector3.new(-55, -1, 150) },
		{ Vector3.new(10, 2, 120), Vector3.new(55, -1, 150) },
	} do
		part({ Name = "PondRim", Size = rim[1], Position = rim[2], Color = Color3.fromRGB(110, 200, 100), Material = Enum.Material.Grass })
	end
	part({ Name = "Island", Shape = Enum.PartType.Cylinder, Size = Vector3.new(14, 16, 16), CFrame = CFrame.new(20, -5, 160) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(110, 200, 100), Material = Enum.Material.Grass })
	spot(Vector3.new(20, 3.5, 160), "On the tiny island in the Pond")
	spot(Vector3.new(-30, -10.5, 170), "At the bottom of the Pond (swim down!)")
	spot(Vector3.new(30, -10.5, 120), "Deep in the Pond near the shore")

	-- Sky Islands: a staircase of floating platforms going up
	local pos = Vector3.new(0, 2, -110)
	part({ Size = Vector3.new(20, 1, 20), Position = Vector3.new(0, -0.5, -100), Color = Color3.fromRGB(200, 200, 255) })
	for i = 1, 24 do
		pos += Vector3.new(rng:NextNumber(-5, 5), 3.5, -9)
		local size = if i % 6 == 0 then 14 else 7
		part({ Size = Vector3.new(size, 1, size), Position = pos, Color = Color3.fromHSV(i / 24, 0.5, 1), Material = Enum.Material.SmoothPlastic })
		if i % 6 == 0 then
			spot(pos + Vector3.new(0, 2, 0), "Sky Islands, floating platform " .. i)
		end
	end
	spot(pos + Vector3.new(3, 2, 0), "At the very top of the Sky Islands")

	return spots
end

return World
