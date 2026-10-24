-- Builds cartoon brainrot characters out of parts so no assets are required.
-- Swap in real meshes later by putting Models named after each Id in ServerStorage.Brainrots.
local ServerStorage = game:GetService("ServerStorage")

local BrainrotModels = require(game:GetService("ReplicatedStorage").Common.BrainrotModels)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Format = require(game:GetService("ReplicatedStorage").Common.Format)

local Models = {}

local rarityIndex = {}
for i, rarity in Config.Rarities do
	rarityIndex[rarity.Name] = i
end

local function part(props): BasePart
	local p = Instance.new("Part")
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanTouch = false
	p.Massless = true
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

local function bodySize(shape: string, scale: number): Vector3
	if shape == "Tall" then
		return Vector3.new(3, 6, 3) * scale
	elseif shape == "Long" then
		return Vector3.new(3.5, 3, 7) * scale
	elseif shape == "Block" then
		return Vector3.new(4, 4, 4) * scale
	end
	return Vector3.new(4.5, 4.5, 4.5) * scale
end

local function buildProcedural(info): (Model, BasePart)
	local model = Instance.new("Model")
	local idx = rarityIndex[info.Rarity] or 1
	local scale = 1 + (idx - 1) * 0.18
	local size = bodySize(info.Shape, scale)
	local rarity = Config.RarityByName[info.Rarity]

	local root = part({
		Name = "Root",
		Size = size,
		Color = info.Color,
		Material = if idx >= 6 then Enum.Material.Neon else Enum.Material.SmoothPlastic,
		Shape = if info.Shape == "Ball" then Enum.PartType.Ball else Enum.PartType.Block,
		Anchored = true,
		Massless = false,
	})
	root.Parent = model
	model.PrimaryPart = root

	-- Eyes on the front (-Z) face.
	local eyeSize = 1.3 * scale
	for _, side in { -1, 1 } do
		local eye = part({
			Size = Vector3.new(eyeSize, eyeSize, eyeSize),
			Shape = Enum.PartType.Ball,
			Color = Color3.new(1, 1, 1),
			CFrame = root.CFrame * CFrame.new(side * size.X * 0.22, size.Y * 0.18, -size.Z / 2),
		})
		eye.Parent = model
		weld(root, eye)
		local pupil = part({
			Size = Vector3.new(eyeSize * 0.5, eyeSize * 0.5, eyeSize * 0.5),
			Shape = Enum.PartType.Ball,
			Color = Color3.new(0, 0, 0),
			CFrame = eye.CFrame * CFrame.new(0, 0, -eyeSize * 0.35),
		})
		pupil.Parent = model
		weld(root, pupil)
	end

	-- Mouth
	local mouth = part({
		Size = Vector3.new(size.X * 0.4, 0.3 * scale, 0.3),
		Color = Color3.fromRGB(120, 20, 20),
		CFrame = root.CFrame * CFrame.new(0, -size.Y * 0.15, -size.Z / 2),
	})
	mouth.Parent = model
	weld(root, mouth)

	-- Legs
	for _, side in { -1, 1 } do
		local leg = part({
			Size = Vector3.new(0.8, 1.6, 0.8) * scale,
			Color = info.Color:Lerp(Color3.new(0, 0, 0), 0.4),
			CFrame = root.CFrame * CFrame.new(side * size.X * 0.25, -size.Y / 2 - 0.8 * scale, 0),
		})
		leg.Parent = model
		weld(root, leg)
	end

	-- Rarity bling
	if idx >= 4 then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Color = ColorSequence.new(rarity.Color)
		sparkle.LightEmission = 1
		sparkle.Size = NumberSequence.new(0.4, 0)
		sparkle.Rate = 6 * idx
		sparkle.Lifetime = NumberRange.new(0.8, 1.4)
		sparkle.Speed = NumberRange.new(2, 4)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Parent = root
	end
	if idx >= 6 then
		local light = Instance.new("PointLight")
		light.Color = rarity.Color
		light.Range = 14
		light.Brightness = 2
		light.Parent = root
	end
	if info.Rarity == "Secret" then
		local crown = part({
			Size = Vector3.new(size.X * 0.6, 1, size.Z * 0.6),
			Color = Color3.fromRGB(255, 215, 0),
			Material = Enum.Material.Neon,
			CFrame = root.CFrame * CFrame.new(0, size.Y / 2 + 0.5, 0),
		})
		crown.Parent = model
		weld(root, crown)
	end

	model:SetAttribute("RootHeight", size.Y / 2 + 1.6 * scale)
	return model, root
end

local function buildFromTemplate(info): (Model?, BasePart?)
	local folder = ServerStorage:FindFirstChild("Brainrots")
	local template = folder and folder:FindFirstChild(info.Id)
	if not (template and template:IsA("Model") and template.PrimaryPart) then
		return nil, nil
	end
	local model = template:Clone()
	local root = model.PrimaryPart :: BasePart
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d ~= root then
			d.Anchored = false
			d.CanCollide = false
			d.Massless = true
			weld(root, d)
		end
	end
	root.Anchored = true
	root.CanCollide = false
	local _, extents = model:GetBoundingBox()
	model:SetAttribute("RootHeight", root.Position.Y - (model:GetPivot().Position.Y - extents.Y / 2))
	return model, root
end

-- Look-alike part model from the shared library, with rarity bling.
local function buildCharacter(info): (Model?, BasePart?)
	if not BrainrotModels.Has(info.Id) then
		return nil, nil
	end
	local idx = rarityIndex[info.Rarity] or 1
	local model, root = BrainrotModels.Build(info.Id, { Scale = 0.72 + (idx - 1) * 0.07 })
	local rarity = Config.RarityByName[info.Rarity]
	if idx >= 4 then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Color = ColorSequence.new(rarity.Color)
		sparkle.LightEmission = 1
		sparkle.Size = NumberSequence.new(0.4, 0)
		sparkle.Rate = 6 * idx
		sparkle.Lifetime = NumberRange.new(0.8, 1.4)
		sparkle.Speed = NumberRange.new(2, 4)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Parent = root
	end
	if idx >= 6 then
		local light = Instance.new("PointLight")
		light.Color = rarity.Color
		light.Range = 14
		light.Brightness = 2
		light.Parent = root
	end
	return model, root
end

function Models.Create(info): (Model, BasePart)
	local model, root = buildFromTemplate(info)
	if not model then
		model, root = buildCharacter(info)
	end
	if not model then
		model, root = buildProcedural(info)
	end
	model.Name = info.Id
	local rarity = Config.RarityByName[info.Rarity]

	local gui = Instance.new("BillboardGui")
	gui.Name = "Tag"
	gui.Size = UDim2.fromOffset(220, 90)
	gui.StudsOffsetWorldSpace = Vector3.new(0, (root :: BasePart).Size.Y / 2 + 3, 0)
	gui.MaxDistance = 120
	gui.AlwaysOnTop = false
	gui.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = gui

	local function line(name, text, color, height)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, height)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = color
		label.Text = text
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = if info.Rarity == "Secret" then Color3.new(1, 1, 1) else Color3.new(0, 0, 0)
		stroke.Parent = label
		label.Parent = gui
		return label
	end
	line("Rarity", info.Rarity, rarity.Color, 20)
	line("Name", info.Name, Color3.new(1, 1, 1), 26)
	line("Income", Format.Cash(info.Income) .. "/s", Color3.fromRGB(90, 255, 90), 22)
	line("Price", Format.Cash(info.Price), Color3.fromRGB(255, 230, 80), 22)

	return model, root :: BasePart
end

return Models
