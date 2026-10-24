-- Builds the lobby and a village arena with walls to dodge around.
local BrainrotModels = require(game:GetService("ReplicatedStorage").Common.BrainrotModels)

local Arena = {}

Arena.Size = 220
Arena.Center = Vector3.new(0, 0, 400)
Arena.LobbySpawn = CFrame.new(0, 4, 0)

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

function Arena.Build()
	local folder = Instance.new("Folder")
	folder.Name = "Map"
	folder.Parent = workspace
	local rng = Random.new(42)

	-- Lobby
	part({ Name = "LobbyFloor", Size = Vector3.new(80, 2, 80), Position = Vector3.new(0, -1, 0), Color = Color3.fromRGB(230, 230, 240), Material = Enum.Material.Marble }, folder)
	for _, s in { { 40, 0, 1, 80 }, { -40, 0, 1, 80 }, { 0, 40, 80, 1 }, { 0, -40, 80, 1 } } do
		part({ Size = Vector3.new(s[3], 14, s[4]), Position = Vector3.new(s[1], 7, s[2]), Color = Color3.fromRGB(120, 90, 200), Transparency = 0.3 }, folder)
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Neutral = true
	spawn.Color = Color3.fromRGB(255, 200, 80)
	spawn.Parent = folder

	-- Arena floor + boundary walls (night village)
	local c = Arena.Center
	local s = Arena.Size
	part({ Name = "ArenaFloor", Size = Vector3.new(s, 2, s), Position = c - Vector3.new(0, 1, 0), Color = Color3.fromRGB(70, 110, 60), Material = Enum.Material.Grass }, folder)
	for _, side in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		part({
			Size = if side[1] ~= 0 then Vector3.new(2, 30, s) else Vector3.new(s, 30, 2),
			Position = c + Vector3.new(side[1] * s / 2, 15, side[2] * s / 2),
			Color = Color3.fromRGB(40, 30, 30),
			Transparency = 0.6,
		}, folder)
	end

	-- Houses and walls in a loose grid so there's room to run around them.
	local spawnPoints = {}
	for gx = -4, 4 do
		for gz = -4, 4 do
			local pos = c + Vector3.new(gx * 24, 0, gz * 24)
			if math.abs(gx) <= 1 and math.abs(gz) <= 1 then
				continue -- open plaza in the middle where Sahur spawns
			end
			local roll = rng:NextNumber()
			if roll < 0.35 then
				local w, d = rng:NextInteger(8, 14), rng:NextInteger(8, 14)
				local h = rng:NextInteger(9, 14)
				local color = Color3.fromHSV(rng:NextNumber(), 0.35, 0.85)
				part({ Size = Vector3.new(w, h, d), Position = pos + Vector3.new(0, h / 2, 0), Color = color, Material = Enum.Material.Brick }, folder)
				local roof = part({ Size = Vector3.new(w + 2, 2, d + 2), Position = pos + Vector3.new(0, h + 1, 0), Color = Color3.fromRGB(120, 40, 30) }, folder)
				roof.Material = Enum.Material.Slate
			elseif roll < 0.55 then
				local horizontal = rng:NextNumber() < 0.5
				part({
					Size = if horizontal then Vector3.new(18, 7, 2) else Vector3.new(2, 7, 18),
					Position = pos + Vector3.new(0, 3.5, 0),
					Color = Color3.fromRGB(150, 150, 150),
					Material = Enum.Material.Cobblestone,
				}, folder)
				table.insert(spawnPoints, pos + Vector3.new(if horizontal then 0 else 5, 3, if horizontal then 5 else 0))
			else
				table.insert(spawnPoints, pos + Vector3.new(0, 3, 0))
			end
		end
	end

	-- Street lamps for atmosphere
	for i = 1, 16 do
		local angle = i / 16 * math.pi * 2
		local pos = c + Vector3.new(math.cos(angle) * 30, 0, math.sin(angle) * 30)
		part({ Size = Vector3.new(0.6, 10, 0.6), Position = pos + Vector3.new(0, 5, 0), Color = Color3.fromRGB(30, 30, 30) }, folder)
		local bulb = part({ Size = Vector3.new(1.5, 1.5, 1.5), Position = pos + Vector3.new(0, 10.5, 0), Color = Color3.fromRGB(255, 220, 140), Material = Enum.Material.Neon }, folder)
		local light = Instance.new("PointLight")
		light.Range = 24
		light.Brightness = 2
		light.Color = Color3.fromRGB(255, 200, 120)
		light.Parent = bulb
	end
	return spawnPoints
end

-- Cartoon Tung Tung Sahur: tall log body, angry eyes, a bat. Uses a Humanoid so it can path.
function Arena.MakeSahur(position: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "TungTungSahur"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(3, 9, 3)
	root.Color = Color3.fromRGB(170, 115, 60)
	root.Material = Enum.Material.Wood
	root.CFrame = CFrame.new(position + Vector3.new(0, 7, 0))
	root.Parent = model
	model.PrimaryPart = root
	local function attach(props)
		local p = Instance.new("Part")
		p.CanCollide = false
		p.Massless = true
		for k, v in props do
			(p :: any)[k] = v
		end
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = p
		w.Parent = p
		p.Parent = model
		return p
	end
	for _, side in { -1, 1 } do
		attach({ Shape = Enum.PartType.Ball, Size = Vector3.one * 1.2, Color = Color3.new(1, 1, 1), CFrame = root.CFrame * CFrame.new(side * 0.7, 2.6, -1.5) })
		attach({ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.6, Color = Color3.new(0, 0, 0), CFrame = root.CFrame * CFrame.new(side * 0.7, 2.6, -2.05) })
		attach({ Size = Vector3.new(1.2, 0.25, 0.2), Color = Color3.new(0, 0, 0), CFrame = root.CFrame * CFrame.new(side * 0.7, 3.4, -1.6) * CFrame.Angles(0, 0, math.rad(side * -20)) })
		attach({ Size = Vector3.new(0.8, 3, 0.8), Color = Color3.fromRGB(140, 95, 50), CFrame = root.CFrame * CFrame.new(side * 0.8, -5.5, 0) })
	end
	attach({ Size = Vector3.new(1.6, 0.3, 0.2), Color = Color3.fromRGB(90, 0, 0), CFrame = root.CFrame * CFrame.new(0, 1.4, -1.55) })
	attach({ Size = Vector3.new(0.7, 6, 0.7), Color = Color3.fromRGB(110, 70, 30), Material = Enum.Material.Wood, CFrame = root.CFrame * CFrame.new(2.2, 1, -1) * CFrame.Angles(math.rad(-30), 0, 0) })

	local humanoid = Instance.new("Humanoid")
	humanoid.HipHeight = 2.5 -- legs are 2.5 studs below the root's bottom
	humanoid.WalkSpeed = 16
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.MaxHealth = 1e9
	humanoid.Health = 1e9
	humanoid.Parent = model
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 40)
	gui.StudsOffset = Vector3.new(0, 7, 0)
	gui.Parent = root
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 60, 60)
	label.Text = "TUNG TUNG TUNG SAHUR"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = label
	label.Parent = gui

	-- Swap the simple log for the detailed Tung Tung Sahur figure, welded to the (now invisible) root.
	if BrainrotModels.Has("tung") then
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.Transparency = 1
			end
		end
		local figure, froot = BrainrotModels.Build("tung", { Scale = 1.3, Anchored = false })
		froot.Massless = true
		froot.CFrame = root.CFrame * CFrame.new(0, -7 + figure:GetAttribute("RootHeight"), 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = froot
		weld.Parent = froot
		figure.Name = "Look"
		figure.Parent = model
	end

	local sound = Instance.new("Sound")
	sound.Name = "Footsteps"
	sound.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
	sound.Looped = true
	sound.RollOffMaxDistance = 80
	sound.Volume = 1
	sound.Parent = root
	return model
end

return Arena
