-- Brainrot Disaster Survival server: lobby -> random disaster on a rebuilt island town -> survivors get coins.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotModels = require(ReplicatedStorage.Common.BrainrotModels)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)

Lighting.ClockTime = 14
Lighting.Brightness = 2.5

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local function remote(className: string, name: string): any
	local r = Instance.new(className)
	r.Name = name
	r.Parent = remotes
	return r
end
local NotifyRemote = remote("RemoteEvent", "Notify")
local ChooseRemote = remote("RemoteEvent", "Choose")
local UpgradeRemote = remote("RemoteFunction", "Upgrade")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

local function part(props, parent: Instance): BasePart
	local p = Instance.new(props.ClassName or "Part")
	props.ClassName = nil
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p :: BasePart
end

---------------------------------------------------------------- static world

local world = Instance.new("Folder")
world.Name = "World"
world.Parent = workspace
part({ Name = "Island", Size = Vector3.new(220, 4, 220), Position = Vector3.new(0, -2, 0), Color = Color3.fromRGB(90, 170, 80), Material = Enum.Material.Grass }, world)
part({ Name = "Sea", Size = Vector3.new(900, 1, 900), Position = Vector3.new(0, -6, 0), Color = Color3.fromRGB(40, 110, 200), Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false }, world)
part({ Name = "Road", Size = Vector3.new(14, 0.2, 200), Position = Vector3.new(0, 0.1, 0), Color = Color3.fromRGB(60, 60, 65) }, world)
part({ Name = "Road2", Size = Vector3.new(200, 0.2, 14), Position = Vector3.new(0, 0.1, 0), Color = Color3.fromRGB(60, 60, 65) }, world)

-- Lobby floats above the island so players can watch.
local LOBBY = Vector3.new(0, 160, -170)
part({ Name = "Lobby", Size = Vector3.new(70, 2, 50), Position = LOBBY - Vector3.new(0, 1, 0), Color = Color3.fromRGB(240, 240, 250), Material = Enum.Material.SmoothPlastic }, world)
for _, x in { -35, 35 } do
	part({ Size = Vector3.new(1, 6, 50), Position = LOBBY + Vector3.new(x, 3, 0), Transparency = 0.7, Color = Color3.fromRGB(150, 200, 255) }, world)
end
part({ Size = Vector3.new(70, 6, 1), Position = LOBBY + Vector3.new(0, 3, 25), Transparency = 0.7, Color = Color3.fromRGB(150, 200, 255) }, world)
part({ Size = Vector3.new(70, 6, 1), Position = LOBBY + Vector3.new(0, 3, -25), Transparency = 0.7, Color = Color3.fromRGB(150, 200, 255) }, world)
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = LOBBY + Vector3.new(0, 0.5, 0)
spawn.Neutral = true
spawn.Color = Color3.fromRGB(255, 200, 0)
spawn.Parent = world

---------------------------------------------------------------- town (rebuilt every round)

local town = Instance.new("Folder")
town.Name = "Town"
town.Parent = workspace

local function house(pos: Vector3, w: number, d: number, h: number, color: Color3)
	local t = 1
	part({ Name = "Wall", Size = Vector3.new(w, h, t), Position = pos + Vector3.new(0, h / 2, -d / 2), Color = color }, town)
	-- Front wall with a door gap
	local side = (w - 6) / 2
	part({ Name = "Wall", Size = Vector3.new(side, h, t), Position = pos + Vector3.new(-(3 + side / 2), h / 2, d / 2), Color = color }, town)
	part({ Name = "Wall", Size = Vector3.new(side, h, t), Position = pos + Vector3.new(3 + side / 2, h / 2, d / 2), Color = color }, town)
	part({ Name = "Wall", Size = Vector3.new(6, h - 8, t), Position = pos + Vector3.new(0, 8 + (h - 8) / 2, d / 2), Color = color }, town)
	part({ Name = "Wall", Size = Vector3.new(t, h, d), Position = pos + Vector3.new(-w / 2, h / 2, 0), Color = color }, town)
	part({ Name = "Wall", Size = Vector3.new(t, h, d), Position = pos + Vector3.new(w / 2, h / 2, 0), Color = color }, town)
	part({ Name = "Roof", Size = Vector3.new(w + 2, 1, d + 2), Position = pos + Vector3.new(0, h + 0.5, 0), Color = Color3.fromRGB(150, 60, 50), Material = Enum.Material.Slate }, town)
	part({ ClassName = "TrussPart", Name = "Ladder", Size = Vector3.new(2, h + 2, 2), Position = pos + Vector3.new(w / 2 + 1.5, (h + 2) / 2, 0), Color = Color3.fromRGB(120, 120, 130) }, town)
end

local function tower(pos: Vector3)
	local h = 34
	for i = 0, 3 do
		local a = i * math.pi / 2
		part({ Name = "Leg", Size = Vector3.new(2, h, 2), Position = pos + Vector3.new(math.cos(a) * 7, h / 2, math.sin(a) * 7), Color = Color3.fromRGB(200, 60, 60) }, town)
	end
	part({ Name = "Deck", Size = Vector3.new(18, 1.5, 18), Position = pos + Vector3.new(0, h, 0), Color = Color3.fromRGB(230, 230, 235) }, town)
	part({ Name = "Deck", Size = Vector3.new(16, 1, 16), Position = pos + Vector3.new(0, h / 2, 0), Color = Color3.fromRGB(230, 230, 235) }, town)
	part({ Name = "Cap", Size = Vector3.new(18, 1, 18), Position = pos + Vector3.new(0, h + 9, 0), Color = Color3.fromRGB(200, 60, 60) }, town)
	part({ ClassName = "TrussPart", Name = "Ladder", Size = Vector3.new(2, h + 2, 2), Position = pos + Vector3.new(0, (h + 2) / 2, 10), Color = Color3.fromRGB(120, 120, 130) }, town)
end

local function buildTown()
	town:ClearAllChildren()
	house(Vector3.new(-45, 0, -45), 26, 22, 12, Color3.fromRGB(240, 220, 170))
	house(Vector3.new(45, 0, -45), 22, 22, 14, Color3.fromRGB(170, 210, 240))
	house(Vector3.new(-45, 0, 45), 30, 20, 10, Color3.fromRGB(240, 180, 200))
	house(Vector3.new(45, 0, 45), 24, 24, 16, Color3.fromRGB(200, 240, 180))
	house(Vector3.new(-80, 0, 0), 18, 26, 12, Color3.fromRGB(250, 240, 200))
	tower(Vector3.new(75, 0, 0))
	tower(Vector3.new(0, 0, 80))
	for _, p in { Vector3.new(20, 0, -20), Vector3.new(-20, 0, 20), Vector3.new(25, 0, 25) } do
		local trunk = part({ Name = "Trunk", Size = Vector3.new(2, 10, 2), Position = p + Vector3.new(0, 5, 0), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.Wood }, town)
		part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(10, 10, 10), Position = trunk.Position + Vector3.new(0, 7, 0), Color = Color3.fromRGB(60, 150, 60), Material = Enum.Material.Grass }, town)
	end
end
buildTown()

---------------------------------------------------------------- state

local state = { Stage = "Lobby", Disaster = "" }
local chosen: string? = nil
local chosenBy = ""
local pendingChoice: { [Player]: string } = {}
local hazards = Instance.new("Folder")
hazards.Name = "Hazards"
hazards.Parent = workspace

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function inRound(): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("InRound") and rootOf(p) then
			table.insert(list, p)
		end
	end
	return list
end

local function hurt(player: Player, amount: number)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:TakeDamage(amount)
	end
end

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("Wins", data.Wins)
	player:SetAttribute("HealthLevel", data.HealthLevel)
	player:SetAttribute("SpeedLevel", data.SpeedLevel)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		(ls :: any).Survived.Value = data.Wins;
		(ls :: any).Coins.Value = data.Coins
	end
end

local function applyStats(player: Player)
	local data = DataService.Get(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not data or not humanoid then
		return
	end
	local maxHealth = 100 + data.HealthLevel * Config.HealthPerLevel
	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth
	humanoid.WalkSpeed = 16 + data.SpeedLevel * Config.SpeedPerLevel
	humanoid.UseJumpPower = true
	humanoid.JumpPower = if MonetizationService.OwnsPass(player, "Balloon") then 95 else 50
end

local function randomSpot(): CFrame
	return CFrame.new(math.random(-90, 90), 4, math.random(-90, 90))
end

---------------------------------------------------------------- disasters
-- Each runs for `duration` seconds and checks hazards every 0.2s. They clean up via the Hazards folder.

local excludeParams = RaycastParams.new()
excludeParams.FilterType = Enum.RaycastFilterType.Exclude
excludeParams.FilterDescendantsInstances = { hazards }

local function characters(): { Instance }
	local list: { Instance } = { hazards }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	return list
end

local function loopFor(duration: number, step: (dt: number, elapsed: number) -> ())
	local start = os.clock()
	local last = start
	while os.clock() - start < duration and #inRound() > 0 do
		task.wait(0.2)
		local now = os.clock()
		workspace:SetAttribute("TimeLeft", math.max(0, math.ceil(duration - (now - start))))
		step(now - last, now - start)
		last = now
	end
end

local Disasters = {}

function Disasters.Flood(duration: number)
	local water = part({ Name = "Water", Size = Vector3.new(230, 1, 230), Position = Vector3.new(0, -2, 0), Color = Color3.fromRGB(40, 120, 230), Material = Enum.Material.Glass, Transparency = 0.35, CanCollide = false }, hazards)
	local top = -1
	loopFor(duration, function(dt)
		top = math.min(19, top + dt * 0.6)
		water.Size = Vector3.new(230, top + 3, 230)
		water.Position = Vector3.new(0, (top - 3) / 2, 0)
		for _, p in inRound() do
			local root = rootOf(p) :: BasePart
			if root.Position.Y < top + 1 then
				hurt(p, 14 * dt)
			end
		end
	end)
end

function Disasters.Meteors(duration: number)
	local falling: { { Part: BasePart, Target: Vector3 } } = {}
	local nextSpawn = 0
	loopFor(duration, function(dt, elapsed)
		if elapsed >= nextSpawn then
			nextSpawn = elapsed + 0.5
			local x, z = math.random(-100, 100), math.random(-100, 100)
			-- Bias meteors toward players so nobody can stand still.
			local targets = inRound()
			if #targets > 0 and math.random() < 0.4 then
				local r = rootOf(targets[math.random(1, #targets)]) :: BasePart
				x, z = r.Position.X + math.random(-8, 8), r.Position.Z + math.random(-8, 8)
			end
			local hit = workspace:Raycast(Vector3.new(x, 150, z), Vector3.new(0, -200, 0), excludeParams)
			local target = if hit then hit.Position else Vector3.new(x, 0, z)
			local rock = part({ Name = "Meteor", Shape = Enum.PartType.Ball, Size = Vector3.new(5, 5, 5), Position = Vector3.new(x, 150, z), Color = Color3.fromRGB(255, 100, 30), Material = Enum.Material.Neon, CanCollide = false }, hazards)
			table.insert(falling, { Part = rock, Target = target })
		end
		for i = #falling, 1, -1 do
			local m = falling[i]
			local pos = m.Part.Position - Vector3.new(0, 110 * dt, 0)
			if pos.Y <= m.Target.Y then
				m.Part:Destroy()
				table.remove(falling, i)
				for _, p in inRound() do
					if ((rootOf(p) :: BasePart).Position - m.Target).Magnitude < 11 then
						hurt(p, 55)
					end
				end
				for _, b in town:GetChildren() do
					if b:IsA("BasePart") and (b.Position - m.Target).Magnitude < 7 then
						b:Destroy()
					end
				end
				part({ Name = "Scorch", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 10, 10), CFrame = CFrame.new(m.Target + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(40, 30, 30), CanCollide = false }, hazards)
			else
				m.Part.Position = pos
			end
		end
	end)
end

function Disasters.Tornado(duration: number)
	local center = Vector3.new(math.random(-60, 60), 0, -100)
	local goal = Vector3.new(math.random(-90, 90), 0, math.random(-90, 90))
	local funnel = {}
	for i = 0, 6 do
		table.insert(funnel, part({ Name = "Funnel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(8, 6 + i * 4, 6 + i * 4), Color = Color3.fromRGB(150, 150, 155), Material = Enum.Material.SmoothPlastic, Transparency = 0.45, CanCollide = false, CanTouch = false }, hazards))
	end
	local spin = 0
	loopFor(duration, function(dt)
		if (goal - center).Magnitude < 5 then
			goal = Vector3.new(math.random(-90, 90), 0, math.random(-90, 90))
		end
		center += (goal - center).Unit * math.min((goal - center).Magnitude, 14 * dt)
		spin += dt * 8
		for i, f in funnel do
			f.CFrame = CFrame.new(center + Vector3.new(0, 4 + (i - 1) * 8, 0)) * CFrame.Angles(0, spin + i, math.rad(90))
		end
		for _, p in inRound() do
			local root = rootOf(p) :: BasePart
			local d = Vector3.new(root.Position.X - center.X, 0, root.Position.Z - center.Z)
			if d.Magnitude < 16 then
				hurt(p, 30 * dt)
				local out = if d.Magnitude > 0.1 then d.Unit else Vector3.new(1, 0, 0)
				root.AssemblyLinearVelocity = out * 60 + Vector3.new(0, 70, 0)
			end
		end
		for _, b in town:GetChildren() do
			if b:IsA("BasePart") then
				local d = Vector3.new(b.Position.X - center.X, 0, b.Position.Z - center.Z)
				if d.Magnitude < 10 and math.random() < 0.3 then
					b:Destroy()
				end
			end
		end
	end)
end

function Disasters.AcidRain(duration: number)
	local oldColor, oldEnd = Lighting.FogColor, Lighting.FogEnd
	Lighting.FogColor = Color3.fromRGB(120, 200, 80)
	Lighting.FogEnd = 250
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	loopFor(duration, function(dt)
		params.FilterDescendantsInstances = characters()
		for _ = 1, 6 do
			local drop = part({ Name = "Drop", Size = Vector3.new(0.3, 3, 0.3), Position = Vector3.new(math.random(-100, 100), math.random(10, 60), math.random(-100, 100)), Color = Color3.fromRGB(120, 255, 60), Material = Enum.Material.Neon, CanCollide = false, CanTouch = false, CanQuery = false }, hazards)
			task.delay(0.6, function()
				drop:Destroy()
			end)
		end
		for _, p in inRound() do
			local root = rootOf(p) :: BasePart
			if not workspace:Raycast(root.Position, Vector3.new(0, 120, 0), params) then
				hurt(p, 7 * dt)
			end
		end
	end)
	Lighting.FogColor, Lighting.FogEnd = oldColor, oldEnd
end

function Disasters.Stampede(duration: number)
	local runners: { { Model: Model, Pos: Vector3, Dir: number } } = {}
	local nextWave = 0
	loopFor(duration, function(dt, elapsed)
		if elapsed >= nextWave then
			nextWave = elapsed + 5
			local dir = if math.random() < 0.5 then 1 else -1
			for _ = 1, 6 do
				local model = BrainrotModels.Build("tung", { Scale = 1.3 })
				local h = (model:GetAttribute("RootHeight") :: number?) or 4
				local pos = Vector3.new(-120 * dir, h, math.random(-100, 100))
				model.Parent = hazards
				table.insert(runners, { Model = model, Pos = pos, Dir = dir })
			end
		end
		for i = #runners, 1, -1 do
			local r = runners[i]
			r.Pos += Vector3.new(r.Dir * 45 * dt, 0, 0)
			if math.abs(r.Pos.X) > 125 then
				r.Model:Destroy()
				table.remove(runners, i)
			else
				r.Model:PivotTo(CFrame.lookAt(r.Pos, r.Pos + Vector3.new(r.Dir, 0, 0)))
				for _, p in inRound() do
					local root = rootOf(p) :: BasePart
					local d = Vector3.new(root.Position.X - r.Pos.X, 0, root.Position.Z - r.Pos.Z)
					if d.Magnitude < 6 and root.Position.Y < 9 then
						hurt(p, 45)
						root.AssemblyLinearVelocity = Vector3.new(r.Dir * 80, 50, 0)
					end
				end
			end
		end
	end)
end

function Disasters.Lava(duration: number)
	local lava = part({ Name = "Lava", Size = Vector3.new(220, 0.4, 220), Position = Vector3.new(0, 0.3, 0), Color = Color3.fromRGB(255, 80, 20), Material = Enum.Material.Neon, Transparency = 0.6, CanCollide = false }, hazards)
	notify(nil, "The floor turns to lava in 6 seconds!", Color3.fromRGB(255, 80, 20))
	loopFor(duration, function(dt, elapsed)
		if elapsed < 6 then
			return
		end
		lava.Transparency = 0.1
		for _, p in inRound() do
			local root = rootOf(p) :: BasePart
			if root.Position.Y < 4.5 then
				hurt(p, 25 * dt)
			end
		end
	end)
end

---------------------------------------------------------------- round loop

local function medkitLoop()
	while true do
		task.wait(1)
		if state.Stage == "Disaster" then
			for _, p in inRound() do
				if MonetizationService.OwnsPass(p, "Medkit") then
					local humanoid = (p.Character :: Model):FindFirstChildOfClass("Humanoid") :: Humanoid
					humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 3)
				end
			end
		end
	end
end
task.spawn(medkitLoop)

task.spawn(function()
	while true do
		state.Stage = "Lobby"
		workspace:SetAttribute("Stage", "Lobby")
		for t = Config.Intermission, 1, -1 do
			workspace:SetAttribute("TimeLeft", t)
			task.wait(1)
		end
		local players = {}
		for _, p in Players:GetPlayers() do
			if DataService.Get(p) and rootOf(p) then
				table.insert(players, p)
			end
		end
		if #players == 0 then
			continue
		end
		buildTown()
		local info = Config.Disasters[math.random(1, #Config.Disasters)]
		if chosen then
			for _, d in Config.Disasters do
				if d.Id == chosen then
					info = d
				end
			end
		end
		local picker = chosenBy
		chosen, chosenBy = nil, ""
		for _, p in players do
			p:SetAttribute("InRound", true)
			p.Character:PivotTo(randomSpot())
			applyStats(p)
		end
		state.Stage = "Warning"
		workspace:SetAttribute("Stage", "Warning")
		workspace:SetAttribute("TimeLeft", 8)
		notify(nil, "Get ready... something is coming!", Color3.fromRGB(255, 255, 255))
		task.wait(8)
		state.Stage = "Disaster"
		state.Disaster = info.Id
		workspace:SetAttribute("Stage", "Disaster")
		workspace:SetAttribute("Disaster", info.Name)
		notify(nil, "⚠️ " .. info.Name:upper() .. "! " .. info.Tip .. (if picker ~= "" then " (picked by " .. picker .. ")" else ""), info.Color)
		;(Disasters :: any)[info.Id](Config.DisasterTime)
		hazards:ClearAllChildren()
		workspace:SetAttribute("Disaster", nil)
		local survivors = inRound()
		for _, p in survivors do
			local data = DataService.Get(p)
			if data then
				local m = 1
				if MonetizationService.OwnsPass(p, "DoubleCoins") then
					m *= 2
				end
				if MonetizationService.OwnsPass(p, "VIP") then
					m *= 1.5
				end
				local coins = math.floor(Config.SurviveCoins * m)
				data.Wins += 1
				data.Coins += coins
				sync(p)
				notify(p, "You survived the " .. info.Name .. "! +" .. coins .. " coins", Color3.fromRGB(90, 255, 90))
			end
			p.Character:PivotTo(CFrame.new(LOBBY + Vector3.new(math.random(-15, 15), 4, math.random(-10, 10))))
		end
		for _, p in Players:GetPlayers() do
			p:SetAttribute("InRound", false)
		end
		notify(nil, #survivors .. " survived the " .. info.Name .. "!", info.Color)
		task.wait(2)
	end
end)

---------------------------------------------------------------- remotes + players

ChooseRemote.OnServerEvent:Connect(function(player, id)
	for _, d in Config.Disasters do
		if d.Id == id then
			pendingChoice[player] = id
		end
	end
end)

UpgradeRemote.OnServerInvoke = function(player, kind)
	local data = DataService.Get(player)
	if not data or (kind ~= "Health" and kind ~= "Speed") then
		return false
	end
	local key = kind .. "Level"
	local level = data[key]
	if level >= Config.MaxLevel then
		return false
	end
	local cost = Config.UpgradeCost(level)
	if data.Coins < cost then
		notify(player, "Need " .. cost .. " coins!", Color3.fromRGB(255, 90, 90))
		return false
	end
	data.Coins -= cost
	data[key] = level + 1
	sync(player)
	if state.Stage == "Lobby" then
		applyStats(player)
	end
	return true
end

DataService.ProfileLoaded:Connect(function(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, name in { "Survived", "Coins" } do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = ls
	end
	ls.Parent = player
	sync(player)
	local function onCharacter(character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait()
		applyStats(player)
		if player:GetAttribute("InRound") and state.Stage ~= "Lobby" then
			character:PivotTo(randomSpot())
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				if player:GetAttribute("InRound") then
					player:SetAttribute("InRound", false)
					notify(nil, player.DisplayName .. " didn't make it!", Color3.fromRGB(255, 90, 90))
				end
			end)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	pendingChoice[player] = nil
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		Revive = function(player, data)
			if state.Stage ~= "Lobby" and not player:GetAttribute("InRound") then
				player:SetAttribute("InRound", true)
				player:LoadCharacter()
				notify(nil, player.DisplayName .. " REVIVED!", Color3.fromRGB(90, 255, 90))
			else
				data.Coins += 300
				sync(player)
				notify(player, "Nothing to revive from, so you got 300 coins!", Color3.fromRGB(255, 215, 0))
			end
			return true
		end,
		ChooseDisaster = function(player)
			local pick = pendingChoice[player] or Config.Disasters[math.random(1, #Config.Disasters)].Id
			chosen = pick
			chosenBy = player.DisplayName
			for _, d in Config.Disasters do
				if d.Id == pick then
					notify(nil, player.DisplayName .. " picked the next disaster: " .. d.Name .. "!", d.Color)
				end
			end
			return true
		end,
		Coins = function(player, data)
			data.Coins += 1500
			sync(player)
			return true
		end,
	},
	OnPassOwned = function(player, name)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and name == "Balloon" then
			humanoid.JumpPower = 95
		end
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("BrainrotDisasterSurvival_v1", {
	Coins = 0,
	Wins = 0,
	HealthLevel = 0,
	SpeedLevel = 0,
})
