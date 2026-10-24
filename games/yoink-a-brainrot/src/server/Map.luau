-- Builds the whole map in code: grass, the brainrot runway and 8 player bases.
local Lighting = game:GetService("Lighting")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Map = {}

Map.RunwayStart = Vector3.new(-170, 0.5, 0)
Map.RunwayEnd = Vector3.new(170, 0.5, 0)
Map.PlotHalfX = 35
Map.PlotHalfZ = 30

local PLOT_COLORS = {
	Color3.fromRGB(255, 99, 99),
	Color3.fromRGB(99, 160, 255),
	Color3.fromRGB(110, 230, 110),
	Color3.fromRGB(255, 200, 70),
	Color3.fromRGB(200, 110, 255),
	Color3.fromRGB(255, 150, 60),
	Color3.fromRGB(80, 230, 220),
	Color3.fromRGB(255, 120, 200),
}

local function part(props, parent): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function padLabel(pad: BasePart, text: string, color: Color3): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 60)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.MaxDistance = 90
	gui.Parent = pad
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Parent = label
	label.Parent = gui
	return label
end

function Map.Build()
	local world = Instance.new("Folder")
	world.Name = "World"
	world.Parent = workspace

	Lighting.ClockTime = 14
	Lighting.Brightness = 2.5
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 170)

	part({
		Name = "Ground",
		Size = Vector3.new(700, 2, 500),
		Position = Vector3.new(0, -1, 0),
		Color = Color3.fromRGB(90, 190, 90),
		Material = Enum.Material.Grass,
	}, world)

	local runwayLength = (Map.RunwayEnd - Map.RunwayStart).Magnitude + 20
	part({
		Name = "Runway",
		Size = Vector3.new(runwayLength, 0.6, 16),
		Position = Vector3.new(0, 0.2, 0),
		Color = Color3.fromRGB(50, 50, 60),
		Material = Enum.Material.SmoothPlastic,
	}, world)
	for _, side in { -1, 1 } do
		part({
			Name = "RunwayEdge",
			Size = Vector3.new(runwayLength, 1, 1),
			Position = Vector3.new(0, 0.5, side * 8.5),
			Color = Color3.fromRGB(255, 220, 0),
			Material = Enum.Material.Neon,
			CanCollide = false,
		}, world)
	end
	local portal = part({
		Name = "SpawnPortal",
		Size = Vector3.new(2, 16, 18),
		Position = Map.RunwayStart + Vector3.new(-6, 8, 0),
		Color = Color3.fromRGB(170, 0, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.3,
		CanCollide = false,
	}, world)
	local portalGui = padLabel(portal, "BRAINROTS INCOMING!", Color3.fromRGB(255, 255, 255)).Parent :: BillboardGui
	portalGui.StudsOffset = Vector3.new(0, 11, 0)

	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 0.5, 120)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Parent = world

	local plots = {}
	local xs = { -135, -45, 45, 135 }
	local index = 0
	for _, zSide in { 1, -1 } do
		for _, x in xs do
			index += 1
			local center = Vector3.new(x, 0, zSide * 62)
			local cf = CFrame.lookAt(center, Vector3.new(x, 0, 0))
			local color = PLOT_COLORS[index]
			local model = Instance.new("Model")
			model.Name = "Plot" .. index
			model.Parent = world

			part({
				Name = "Floor",
				Size = Vector3.new(Map.PlotHalfX * 2, 1, Map.PlotHalfZ * 2),
				CFrame = cf * CFrame.new(0, 0.5, 0),
				Color = color:Lerp(Color3.new(1, 1, 1), 0.55),
				Material = Enum.Material.WoodPlanks,
			}, model)
			-- Walls on the sides and back; the front faces the runway.
			local wallH = 11
			for _, sx in { -1, 1 } do
				part({
					Name = "Wall",
					Size = Vector3.new(1.5, wallH, Map.PlotHalfZ * 2),
					CFrame = cf * CFrame.new(sx * Map.PlotHalfX, wallH / 2 + 1, 0),
					Color = color,
				}, model)
			end
			part({
				Name = "Wall",
				Size = Vector3.new(Map.PlotHalfX * 2, wallH, 1.5),
				CFrame = cf * CFrame.new(0, wallH / 2 + 1, Map.PlotHalfZ),
				Color = color,
			}, model)
			local barrier = part({
				Name = "Barrier",
				Size = Vector3.new(Map.PlotHalfX * 2, wallH, 0.6),
				CFrame = cf * CFrame.new(0, wallH / 2 + 1, -Map.PlotHalfZ),
				Color = Color3.fromRGB(255, 40, 40),
				Material = Enum.Material.ForceField,
				Transparency = 1,
				CanCollide = false,
			}, model)

			local sign = part({
				Name = "Sign",
				Size = Vector3.new(30, 7, 1),
				CFrame = cf * CFrame.new(0, wallH + 5, Map.PlotHalfZ),
				Color = color,
			}, model)
			local signGui = Instance.new("SurfaceGui")
			signGui.Face = Enum.NormalId.Front
			signGui.Parent = sign
			local signLabel = Instance.new("TextLabel")
			signLabel.Size = UDim2.fromScale(1, 1)
			signLabel.BackgroundTransparency = 1
			signLabel.Font = Enum.Font.FredokaOne
			signLabel.TextScaled = true
			signLabel.TextColor3 = Color3.new(1, 1, 1)
			signLabel.Text = "Empty Base"
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 4
			stroke.Parent = signLabel
			signLabel.Parent = signGui

			local slotCFrames = {}
			local total = Config.BaseSlots + Config.ExtraSlots
			for i = 1, total do
				local row = math.floor((i - 1) / 5)
				local col = (i - 1) % 5
				local slotCF = cf * CFrame.new((col - 2) * 12, 1, 2 + row * 9)
				-- Brainrots face the entrance.
				slotCFrames[i] = slotCF
				part({
					Name = "Slot" .. i,
					Size = Vector3.new(8, 0.3, 7),
					CFrame = slotCF * CFrame.new(0, 0.15, 0),
					Color = if i > Config.BaseSlots then Color3.fromRGB(255, 215, 0) else color,
					Material = Enum.Material.SmoothPlastic,
					CanCollide = false,
				}, model)
			end

			local collectPad = part({
				Name = "CollectPad",
				Size = Vector3.new(10, 1, 10),
				CFrame = cf * CFrame.new(-24, 1.2, -20),
				Color = Color3.fromRGB(40, 220, 80),
				Material = Enum.Material.Neon,
			}, model)
			local collectLabel = padLabel(collectPad, "COLLECT $0", Color3.fromRGB(120, 255, 120))

			local lockPad = part({
				Name = "LockPad",
				Size = Vector3.new(8, 1, 8),
				CFrame = cf * CFrame.new(24, 1.2, -20),
				Color = Color3.fromRGB(255, 60, 60),
				Material = Enum.Material.Neon,
			}, model)
			local lockLabel = padLabel(lockPad, "LOCK BASE", Color3.fromRGB(255, 130, 130))

			table.insert(plots, {
				Index = index,
				CFrame = cf,
				Model = model,
				SlotCFrames = slotCFrames,
				CollectPad = collectPad,
				CollectLabel = collectLabel,
				LockPad = lockPad,
				LockLabel = lockLabel,
				Barrier = barrier,
				SignLabel = signLabel,
				SpawnCFrame = cf * CFrame.new(0, 4, -18),
				Owner = nil,
				Uncollected = 0,
				Slots = {},
				LockedUntil = 0,
				LockCooldownUntil = 0,
			})
		end
	end
	return plots
end

function Map.IsInPlot(plot, position: Vector3): boolean
	local localPos = plot.CFrame:PointToObjectSpace(position)
	return math.abs(localPos.X) <= Map.PlotHalfX and math.abs(localPos.Z) <= Map.PlotHalfZ and localPos.Y < 40
end

return Map
