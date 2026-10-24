-- Procedurally builds a deterministic obby course. Each stage starts at a checkpoint.
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Course = {}

local THEMES = {
	Color3.fromRGB(255, 99, 99),
	Color3.fromRGB(255, 170, 60),
	Color3.fromRGB(255, 230, 80),
	Color3.fromRGB(110, 230, 110),
	Color3.fromRGB(80, 200, 255),
	Color3.fromRGB(150, 110, 255),
	Color3.fromRGB(255, 120, 220),
}
local MEMES = {
	"Tung Tung Tung Sahur is coming...",
	"Tralalero Tralala!",
	"Bombardiro Crocodilo",
	"Skibidi stage",
	"Sigma grindset",
	"Ohio level",
	"Only 1% beat this",
	"Brr Brr Patapim",
	"Chimpanzini Bananini",
	"Don't fall, gyatt",
}

local folder: Folder
local rng: Random

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

-- Each builder gets the stage start CFrame (on top of the checkpoint) + difficulty 0..1
-- and returns the CFrame where the next checkpoint goes.
local builders = {}

-- Default character: WalkSpeed 16, JumpPower 50 => ~8 stud flat jump, ~7 studs high.
-- Every gap below stays under that so the course is always beatable without passes.
function builders.Jumps(cf: CFrame, d: number, color: Color3): CFrame
	local size = 7 - d * 3.5
	local gap = 3.5 + d * 3
	local first = true
	for _ = 1, 5 do
		local step = if first then gap + size / 2 else gap + size
		first = false
		cf *= CFrame.new(rng:NextNumber(-2, 2), rng:NextNumber(-0.5, 1), -step)
		part({ Size = Vector3.new(size, 1, size), CFrame = cf, Color = color })
	end
	return cf * CFrame.new(0, 0, -(gap + size / 2 + 6))
end

function builders.Lava(cf: CFrame, d: number, color: Color3): CFrame
	local length = 70
	part({ Size = Vector3.new(10, 1, length), CFrame = cf * CFrame.new(0, 0, -length / 2), Color = color })
	local strips = 4 + math.floor(d * 5)
	for i = 1, strips do
		local z = -i * (length / (strips + 1))
		killer({ Size = Vector3.new(10, 1.2, 2 + d * 3), CFrame = cf * CFrame.new(0, 0.1, z) })
	end
	return cf * CFrame.new(0, 0, -length - 8)
end

function builders.Beams(cf: CFrame, d: number, color: Color3): CFrame
	local width = 2.2 - d * 1.2
	local z = 0
	local x = 0
	for _ = 1, 3 do
		local len = 22
		local turn = rng:NextNumber(-8, 8)
		local a = (cf * CFrame.new(x, 0, -z)).Position
		local b = (cf * CFrame.new(x + turn, 0, -z - len)).Position
		part({ Size = Vector3.new(width, 1, (b - a).Magnitude + width), CFrame = CFrame.lookAt((a + b) / 2, b), Color = color })
		x += turn
		z += len
	end
	killer({ Size = Vector3.new(50, 1, z + 10), CFrame = cf * CFrame.new(x / 2, -12, -z / 2) })
	return cf * CFrame.new(x, 0, -z - 6)
end

function builders.Spinner(cf: CFrame, d: number, color: Color3): CFrame
	local base = part({ Size = Vector3.new(30, 1, 30), CFrame = cf * CFrame.new(0, 0, -15), Color = color })
	local pivot = part({ Size = Vector3.new(3, 3, 3), CFrame = base.CFrame * CFrame.new(0, 2, 0), Color = Color3.fromRGB(40, 40, 40) })
	local bar = killer({ Size = Vector3.new(28, 1.4, 1.4), CFrame = pivot.CFrame * CFrame.new(0, 0.5, 0), Anchored = false, CanCollide = false })
	local a0 = Instance.new("Attachment")
	a0.CFrame = CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90))
	a0.Parent = pivot
	local a1 = Instance.new("Attachment")
	a1.CFrame = CFrame.Angles(0, 0, math.rad(90))
	a1.Parent = bar
	local hinge = Instance.new("HingeConstraint")
	hinge.Attachment0 = a0
	hinge.Attachment1 = a1
	hinge.ActuatorType = Enum.ActuatorType.Motor
	hinge.MotorMaxTorque = math.huge
	hinge.AngularVelocity = 1.5 + d * 2.5
	hinge.Parent = bar
	bar:SetNetworkOwner(nil)
	return cf * CFrame.new(0, 0, -36)
end

function builders.Climb(cf: CFrame, d: number, color: Color3): CFrame
	local height = 20 + d * 15
	part({ Size = Vector3.new(14, 1, 12), CFrame = cf * CFrame.new(0, 0, -6), Color = color })
	local truss = Instance.new("TrussPart")
	truss.Anchored = true
	truss.Size = Vector3.new(2, height, 2)
	truss.CFrame = cf * CFrame.new(0, height / 2, -13)
	truss.Color = Color3.fromRGB(200, 200, 200)
	truss.Parent = folder
	part({ Size = Vector3.new(8, 1, 8), CFrame = cf * CFrame.new(0, height, -18), Color = color })
	if d > 0.4 then
		killer({ Size = Vector3.new(1, height * 0.4, 1), CFrame = cf * CFrame.new(1.6, height * 0.35, -13) })
	end
	return cf * CFrame.new(0, height, -28)
end

function builders.Fading(cf: CFrame, d: number, color: Color3): CFrame
	for i = 1, 6 do
		local tile = part({
			Size = Vector3.new(7, 1, 7),
			CFrame = cf * CFrame.new(if i % 2 == 0 then 3 else -3, 0, -i * 9),
			Color = color:Lerp(Color3.new(1, 1, 1), 0.4),
			Material = Enum.Material.Glass,
		})
		tile:SetAttribute("Fade", 0.9 - d * 0.5)
	end
	killer({ Size = Vector3.new(30, 1, 60), CFrame = cf * CFrame.new(0, -12, -30) })
	return cf * CFrame.new(0, 0, -66)
end

function builders.WallHop(cf: CFrame, d: number, color: Color3): CFrame
	local rise = 0
	for i = 1, 5 do
		rise += 2.5 + d * 1.5
		part({ Size = Vector3.new(4, 1, 4 - d * 1.5), CFrame = cf * CFrame.new(if i % 2 == 0 then 3 else -3, rise, -i * 6), Color = color })
	end
	killer({ Size = Vector3.new(24, 1, 40), CFrame = cf * CFrame.new(0, -8, -18) })
	return cf * CFrame.new(0, rise, -39)
end

local ORDER = { "Jumps", "Lava", "Beams", "Spinner", "Climb", "Fading", "WallHop" }

local function sign(cf: CFrame, text: string, color: Color3)
	local board = part({ Size = Vector3.new(12, 4, 0.5), CFrame = cf * CFrame.new(0, 9, 4) * CFrame.Angles(0, math.pi, 0), Color = Color3.fromRGB(30, 30, 30), CanCollide = false })
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Back
	surface.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = surface
end

-- Returns array of checkpoint parts, index = stage number (1..StageCount+1, last is the finish).
function Course.Build(): { BasePart }
	folder = Instance.new("Folder")
	folder.Name = "Course"
	folder.Parent = workspace
	rng = Random.new(1337)

	local checkpoints = {}
	local cf = CFrame.new(0, 10, -40)
	part({ Name = "Lobby", Size = Vector3.new(60, 1, 60), CFrame = CFrame.new(0, 9.5, 0), Color = Color3.fromRGB(240, 240, 240), Material = Enum.Material.Marble })
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(0, 10.5, 10)
	spawn.Neutral = true
	spawn.Color = Color3.fromRGB(255, 220, 90)
	spawn.Parent = folder
	for stage = 1, Config.StageCount + 1 do
		local color = THEMES[(math.floor((stage - 1) / 5) % #THEMES) + 1]
		local isFinish = stage == Config.StageCount + 1
		local cp = part({
			Name = "Checkpoint" .. stage,
			Size = Vector3.new(12, 1, 12),
			CFrame = cf,
			Color = if isFinish then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(60, 60, 70),
			Material = if isFinish then Enum.Material.Neon else Enum.Material.Slate,
		})
		cp:SetAttribute("Stage", stage)
		checkpoints[stage] = cp
		sign(cp.CFrame, if isFinish then "YOU ESCAPED!" else "Stage " .. stage .. (if stage % 3 == 0 then " - " .. MEMES[(stage // 3 - 1) % #MEMES + 1] else ""), color)
		if isFinish then
			break
		end
		local d = (stage - 1) / Config.StageCount
		local kind = ORDER[(stage - 1) % #ORDER + 1]
		-- Builders start at the checkpoint's front edge.
		local stageStart = cf
		cf = CFrame.new(builders[kind](cf * CFrame.new(0, 0, -6), d, color).Position)
		-- Kill plane under the whole stage so falling respawns you instantly.
		local low = math.min(stageStart.Position.Y, cf.Position.Y) - 22
		local midZ = (stageStart.Position.Z + cf.Position.Z) / 2
		local length = math.abs(stageStart.Position.Z - cf.Position.Z) + 30
		local fallZone = part({
			Name = "FallZone",
			Size = Vector3.new(160, 2, length),
			CFrame = CFrame.new(cf.Position.X / 2 + stageStart.Position.X / 2, low, midZ),
			Transparency = 1,
			CanCollide = false,
		})
		fallZone:SetAttribute("Kill", true)
	end
	return checkpoints
end

return Course
