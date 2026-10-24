-- Brainrot Hotel server: endless numbered rooms generated as players open doors, drawers with knobs,
-- closets to hide in, and Sahur rushing through the hallway. Everyone dead = new run from door 0.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotModels = require(ReplicatedStorage.Common.BrainrotModels)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)

Lighting.ClockTime = 0
Lighting.Brightness = 0
Lighting.Ambient = Color3.fromRGB(25, 20, 20)
Lighting.OutdoorAmbient = Color3.fromRGB(25, 20, 20)

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
local WarnRemote = remote("RemoteEvent", "Warn")
local UpgradeRemote = remote("RemoteFunction", "Upgrade")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

local function part(props, parent: Instance): BasePart
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

local L, W, H = Config.RoomLength, Config.RoomWidth, Config.RoomHeight
local hotel = Instance.new("Folder")
hotel.Name = "Hotel"
hotel.Parent = workspace

-- Spectator room for dead players.
local GHOST = CFrame.new(0, 205, -200)
local ghostFolder = Instance.new("Folder")
ghostFolder.Name = "Spectate"
ghostFolder.Parent = workspace
part({ Name = "GhostFloor", Size = Vector3.new(40, 2, 40), Position = Vector3.new(0, 200, -200), Color = Color3.fromRGB(60, 40, 70), Material = Enum.Material.ForceField }, ghostFolder)
local ghostLight = Instance.new("PointLight")
ghostLight.Range = 40
ghostLight.Parent = ghostFolder:FindFirstChild("GhostFloor") :: BasePart

local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = Vector3.new(0, 0.5, L / 2)
spawn.Neutral = true
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Parent = workspace

---------------------------------------------------------------- state

type Room = { Index: number, Model: Folder, Door: BasePart, Lights: { PointLight }, Opened: boolean }
local rooms: { [number]: Room } = {}
local run = { Latest = 0, Rushing = false, Id = 0 }
local dead: { [Player]: boolean } = {}
local hiding: { [Player]: BasePart? } = {}
local crucifixUsed: { [Player]: boolean } = {}
local freeReviveUsed: { [Player]: boolean } = {}
local bestRoom: { [Player]: number } = {}

local function roomOfZ(z: number): number
	return math.floor(z / L)
end

local function rootOf(player: Player): BasePart?
	if dead[player] then
		return nil
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function alive(): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		if DataService.Get(p) and rootOf(p) then
			table.insert(list, p)
		end
	end
	return list
end

local function knobMult(player: Player): number
	local m = 1
	if MonetizationService.OwnsPass(player, "DoubleKnobs") then
		m *= 2
	end
	if MonetizationService.OwnsPass(player, "VIP") then
		m *= 1.5
	end
	return m
end

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Knobs", data.Knobs)
	player:SetAttribute("BestDoor", data.BestDoor)
	player:SetAttribute("Upgrades", table.concat(data.Upgrades, ","))
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		(ls :: any)["Best Door"].Value = data.BestDoor;
		(ls :: any).Knobs.Value = data.Knobs
	end
end

local function hasUpgrade(player: Player, id: string): boolean
	local data = DataService.Get(player)
	return data ~= nil and table.find(data.Upgrades, id) ~= nil
end

local function applyStats(player: Player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = if hiding[player] then 0 elseif hasUpgrade(player, "Boots") then 19 else 16
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root and MonetizationService.OwnsPass(player, "Lantern") and not root:FindFirstChild("Lantern") then
		local light = Instance.new("PointLight")
		light.Name = "Lantern"
		light.Color = Color3.fromRGB(255, 200, 120)
		light.Range = 22
		light.Brightness = 1.5
		light.Parent = root
	end
end

---------------------------------------------------------------- rooms

local PALETTES = {
	{ Wall = Color3.fromRGB(120, 60, 50), Floor = Color3.fromRGB(70, 45, 35) },
	{ Wall = Color3.fromRGB(90, 80, 120), Floor = Color3.fromRGB(55, 45, 40) },
	{ Wall = Color3.fromRGB(60, 95, 80), Floor = Color3.fromRGB(60, 45, 35) },
	{ Wall = Color3.fromRGB(130, 110, 80), Floor = Color3.fromRGB(80, 55, 40) },
}

local function buildRoom(i: number): Room
	local folder = Instance.new("Folder")
	folder.Name = "Room" .. i
	local z0 = i * L
	local pal = PALETTES[(i % #PALETTES) + 1]
	part({ Name = "Floor", Size = Vector3.new(W, 1, L), Position = Vector3.new(0, -0.5, z0 + L / 2), Color = pal.Floor, Material = Enum.Material.WoodPlanks }, folder)
	part({ Name = "Carpet", Size = Vector3.new(8, 0.1, L - 4), Position = Vector3.new(0, 0.05, z0 + L / 2), Color = Color3.fromRGB(140, 30, 40), Material = Enum.Material.Fabric }, folder)
	part({ Name = "Ceiling", Size = Vector3.new(W, 1, L), Position = Vector3.new(0, H + 0.5, z0 + L / 2), Color = Color3.fromRGB(40, 35, 35) }, folder)
	for _, sx in { -1, 1 } do
		part({ Name = "Wall", Size = Vector3.new(1, H, L), Position = Vector3.new(sx * (W / 2 + 0.5), H / 2, z0 + L / 2), Color = pal.Wall, Material = Enum.Material.Fabric }, folder)
	end
	-- Back wall with the door frame (the door itself blocks the gap until opened).
	local side = (W - 8) / 2
	for _, sx in { -1, 1 } do
		part({ Name = "EndWall", Size = Vector3.new(side, H, 1), Position = Vector3.new(sx * (4 + side / 2), H / 2, z0 + L), Color = pal.Wall, Material = Enum.Material.Fabric }, folder)
	end
	part({ Name = "EndWall", Size = Vector3.new(8, H - 11, 1), Position = Vector3.new(0, 11 + (H - 11) / 2, z0 + L), Color = pal.Wall }, folder)
	local door = part({ Name = "Door", Size = Vector3.new(8, 11, 0.8), Position = Vector3.new(0, 5.5, z0 + L), Color = Color3.fromRGB(90, 55, 30), Material = Enum.Material.Wood }, folder)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(200, 100)
	gui.Parent = door
	local plate = Instance.new("TextLabel")
	plate.Size = UDim2.fromScale(1, 0.4)
	plate.BackgroundTransparency = 1
	plate.Text = string.format("%04d", i + 1)
	plate.TextScaled = true
	plate.Font = Enum.Font.Antique
	plate.TextColor3 = Color3.fromRGB(255, 215, 120)
	plate.Parent = gui

	-- Lamps
	local lights = {}
	for k = 1, 2 do
		local lamp = part({ Name = "Lamp", Size = Vector3.new(2, 0.6, 2), Position = Vector3.new(0, H - 0.3, z0 + k * L / 3), Color = Color3.fromRGB(255, 220, 160), Material = Enum.Material.Neon }, folder)
		local light = Instance.new("PointLight")
		light.Range = 30
		light.Brightness = 1.2
		light.Color = Color3.fromRGB(255, 210, 150)
		light.Parent = lamp
		table.insert(lights, light)
	end
	-- Some rooms are dark: more knobs, more danger.
	if i > 6 and math.random() < 0.2 then
		for _, light in lights do
			light.Enabled = false
		end
	end

	-- Drawers (loot) and closets (hiding spots), alternating sides.
	for k = 1, 3 do
		local sx = if k % 2 == 0 then 1 else -1
		local dz = z0 + k * L / 4
		if (k + i) % 2 == 0 then
			local drawer = part({ Name = "Drawer", Size = Vector3.new(3, 4, 5), Position = Vector3.new(sx * (W / 2 - 1.5), 2, dz), Color = Color3.fromRGB(110, 70, 40), Material = Enum.Material.Wood }, folder)
			local pp = Instance.new("ProximityPrompt")
			pp.Name = "SearchPrompt"
			pp.ActionText = "Search"
			pp.ObjectText = "Drawer"
			pp.HoldDuration = 0.4
			pp.RequiresLineOfSight = false
			pp.MaxActivationDistance = 8
			pp.Parent = drawer
			pp.Triggered:Connect(function(player)
				local data = DataService.Get(player)
				if not data or dead[player] or not pp.Enabled then
					return
				end
				pp.Enabled = false
				local amount = math.random(0, 12) + math.floor(i / 5)
				if hasUpgrade(player, "Pockets") then
					amount = math.floor(amount * 1.5)
				end
				amount = math.floor(amount * knobMult(player))
				if amount > 0 then
					data.Knobs += amount
					sync(player)
					notify(player, "+" .. amount .. " knobs", Color3.fromRGB(255, 215, 120))
				else
					notify(player, "Empty...", Color3.fromRGB(180, 180, 180))
				end
			end)
		else
			local closet = part({ Name = "Closet", Size = Vector3.new(4, 9, 5), Position = Vector3.new(sx * (W / 2 - 2), 4.5, dz), Color = Color3.fromRGB(75, 50, 35), Material = Enum.Material.Wood, CanCollide = false }, folder)
			local pp = Instance.new("ProximityPrompt")
			pp.Name = "HidePrompt"
			pp.ActionText = "Hide"
			pp.ObjectText = "Closet"
			pp.HoldDuration = 0
			pp.RequiresLineOfSight = false
			pp.MaxActivationDistance = 8
			pp.Parent = closet
			pp.Triggered:Connect(function(player)
				local character = player.Character
				if dead[player] or not character then
					return
				end
				if hiding[player] == closet then
					hiding[player] = nil
					player:SetAttribute("Hiding", false)
					character:PivotTo(CFrame.new(closet.Position + Vector3.new(-sx * 5, 0, 0)))
				elseif not hiding[player] then
					for _, other in Players:GetPlayers() do
						if hiding[other] == closet then
							notify(player, "Someone is already in there!", Color3.fromRGB(255, 200, 0))
							return
						end
					end
					hiding[player] = closet
					player:SetAttribute("Hiding", true)
					character:PivotTo(CFrame.new(closet.Position))
				end
				applyStats(player)
			end)
		end
	end
	-- Random furniture
	if math.random() < 0.6 then
		part({ Name = "Table", Size = Vector3.new(6, 3, 4), Position = Vector3.new(math.random(-8, 8), 1.5, z0 + math.random(10, L - 10)), Color = Color3.fromRGB(100, 65, 40), Material = Enum.Material.Wood }, folder)
	end

	folder.Parent = hotel
	local room: Room = { Index = i, Model = folder, Door = door, Lights = lights, Opened = false }
	rooms[i] = room
	return room
end

local function ensureRoom(i: number)
	if i <= Config.FinalRoom and not rooms[i] then
		buildRoom(i)
	end
end

local function openDoor(i: number)
	local room = rooms[i]
	if not room or room.Opened then
		return
	end
	room.Opened = true
	room.Door.CanCollide = false
	room.Door.Transparency = 1
	run.Latest = math.max(run.Latest, i + 1)
	workspace:SetAttribute("Door", run.Latest)
	ensureRoom(i + 1)
	ensureRoom(i + 2)
end

local function clearHotel()
	for _, room in rooms do
		room.Model:Destroy()
	end
	table.clear(rooms)
	run.Latest = 0
	run.Id += 1
	workspace:SetAttribute("Door", 0)
	buildRoom(0)
	buildRoom(1)
end

---------------------------------------------------------------- Sahur rush

local entity, entityRoot = BrainrotModels.Build("tung", { Scale = 1.6 })
entity.Name = "Sahur"
local entityHeight = (entity:GetAttribute("RootHeight") :: number?) or 6
local glow = Instance.new("PointLight")
glow.Color = Color3.fromRGB(255, 40, 40)
glow.Range = 40
glow.Brightness = 5
glow.Parent = entityRoot
local PARKED = CFrame.new(0, -100, -300)
entity:PivotTo(PARKED)
entity.Parent = workspace

local function killed(player: Player, why: string)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or dead[player] then
		return
	end
	if hasUpgrade(player, "Crucifix") and not crucifixUsed[player] then
		crucifixUsed[player] = true
		notify(player, "Your Lucky Crucifix saved you! (once per run)", Color3.fromRGB(255, 215, 0))
		return
	end
	humanoid.Health = 0
	notify(nil, player.DisplayName .. " " .. why, Color3.fromRGB(255, 80, 80))
end

local function rush()
	if run.Rushing then
		return
	end
	run.Rushing = true
	local id = run.Id
	-- Warn everyone; Sixth Sense owners hear it earlier.
	for _, p in Players:GetPlayers() do
		if MonetizationService.OwnsPass(p, "SixthSense") then
			WarnRemote:FireClient(p, Config.RushWarning + 3)
		end
	end
	task.wait(3)
	for _, p in Players:GetPlayers() do
		if not MonetizationService.OwnsPass(p, "SixthSense") then
			WarnRemote:FireClient(p, Config.RushWarning)
		end
	end
	-- Lights flicker during the warning.
	local flickerEnd = os.clock() + Config.RushWarning
	while os.clock() < flickerEnd do
		for _, room in rooms do
			for _, light in room.Lights do
				light.Brightness = if math.random() < 0.5 then 0.1 else 1.2
			end
		end
		task.wait(0.15)
	end
	if run.Id ~= id then
		run.Rushing = false
		return
	end
	local minRoom = run.Latest
	for _, p in alive() do
		minRoom = math.min(minRoom, roomOfZ((rootOf(p) :: BasePart).Position.Z))
	end
	local z = math.max(0, minRoom - 1) * L
	local endZ = (run.Latest + 1) * L
	local hit: { [Player]: boolean } = {}
	local last = os.clock()
	while z < endZ and run.Id == id do
		task.wait(0.05)
		local now = os.clock()
		z += Config.RushSpeed * (now - last)
		last = now
		entity:PivotTo(CFrame.new(0, entityHeight, z))
		for _, p in alive() do
			local root = rootOf(p) :: BasePart
			if not hit[p] and not hiding[p] and math.abs(root.Position.Z - z) < 10 then
				hit[p] = true
				killed(p, "was caught by Sahur!")
			end
		end
	end
	entity:PivotTo(PARKED)
	-- Rooms it passed through go dark for a moment and then come back.
	for _, room in rooms do
		for _, light in room.Lights do
			light.Brightness = 1.2
		end
	end
	run.Rushing = false
end

---------------------------------------------------------------- run loop

local function endRun(reason: string, won: boolean)
	for _, p in Players:GetPlayers() do
		local data = DataService.Get(p)
		if data then
			local reached = bestRoom[p] or 0
			local knobs = math.floor(reached * Config.KnobsPerRoom * knobMult(p)) + (if won and not dead[p] then Config.FinishBonus else 0)
			data.Knobs += knobs
			if reached > data.BestDoor then
				data.BestDoor = reached
			end
			sync(p)
			notify(p, "Run over: door " .. reached .. ". +" .. knobs .. " knobs", Color3.fromRGB(255, 215, 120))
		end
	end
	notify(nil, reason, Color3.fromRGB(255, 120, 120))
	task.wait(4)
	clearHotel()
	for _, p in Players:GetPlayers() do
		dead[p] = false
		hiding[p] = nil
		crucifixUsed[p] = false
		freeReviveUsed[p] = false
		bestRoom[p] = 0
		p:SetAttribute("Dead", false)
		p:SetAttribute("Hiding", false)
		if p.Character then
			p.Character:PivotTo(CFrame.new(math.random(-6, 6), 4, L / 2))
			applyStats(p)
		end
	end
end

clearHotel()

task.spawn(function()
	while true do
		task.wait(0.25)
		local living = alive()
		for _, p in living do
			local root = rootOf(p) :: BasePart
			local r = roomOfZ(root.Position.Z)
			if r > (bestRoom[p] or 0) then
				bestRoom[p] = r
			end
			-- Open the door when someone walks up to it.
			local room = rooms[r]
			if room and not room.Opened and room.Door.Position.Z - root.Position.Z < 9 then
				openDoor(r)
				if r + 1 >= Config.FinalRoom then
					task.spawn(endRun, "Door " .. Config.FinalRoom .. " reached! The hotel is beaten!", true)
					break
				end
				if r + 1 >= Config.RushMinRoom and not run.Rushing and math.random() < Config.RushChance then
					task.spawn(rush)
				end
			end
		end
		-- Clean up rooms far behind everyone.
		local minRoom = run.Latest
		for _, p in living do
			minRoom = math.min(minRoom, roomOfZ((rootOf(p) :: BasePart).Position.Z))
		end
		for i, room in rooms do
			if i < minRoom - 3 then
				room.Model:Destroy()
				rooms[i] = nil
			end
		end
		if #Players:GetPlayers() > 0 and #living == 0 and next(dead) ~= nil then
			local anyDead = false
			for _, p in Players:GetPlayers() do
				if dead[p] then
					anyDead = true
				end
			end
			if anyDead then
				endRun("Everyone died! The hotel resets...", false)
			end
		end
	end
end)

---------------------------------------------------------------- players

local function revive(player: Player)
	dead[player] = false
	hiding[player] = nil
	player:SetAttribute("Dead", false)
	player:SetAttribute("Hiding", false)
	local character = player.Character
	if character then
		character:PivotTo(CFrame.new(0, 4, run.Latest * L + 8))
		applyStats(player)
	end
end

DataService.ProfileLoaded:Connect(function(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, name in { "Best Door", "Knobs" } do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = ls
	end
	ls.Parent = player
	bestRoom[player] = 0
	-- Late joiners start at the newest door.
	dead[player] = false
	sync(player)
	local function onCharacter(character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait()
		hiding[player] = nil
		player:SetAttribute("Hiding", false)
		applyStats(player)
		if dead[player] then
			character:PivotTo(GHOST)
		elseif run.Latest > 0 then
			character:PivotTo(CFrame.new(0, 4, run.Latest * L + 8))
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				if dead[player] then
					return
				end
				if MonetizationService.OwnsPass(player, "VIP") and not freeReviveUsed[player] then
					freeReviveUsed[player] = true
					notify(player, "VIP free revive used! You'll be back at the newest door.", Color3.fromRGB(255, 215, 0))
					return
				end
				dead[player] = true
				player:SetAttribute("Dead", true)
			end)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	dead[player] = nil
	hiding[player] = nil
	crucifixUsed[player] = nil
	freeReviveUsed[player] = nil
	bestRoom[player] = nil
end)

UpgradeRemote.OnServerInvoke = function(player, id)
	local data = DataService.Get(player)
	if not data then
		return false
	end
	for _, u in Config.Upgrades do
		if u.Id == id and not table.find(data.Upgrades, id) then
			if data.Knobs < u.Cost then
				notify(player, "Need " .. u.Cost .. " knobs!", Color3.fromRGB(255, 90, 90))
				return false
			end
			data.Knobs -= u.Cost
			table.insert(data.Upgrades, id)
			sync(player)
			applyStats(player)
			notify(player, "Bought " .. u.Name .. "!", Color3.fromRGB(90, 255, 90))
			return true
		end
	end
	return false
end

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		Revive = function(player, data)
			if dead[player] then
				revive(player)
				notify(nil, player.DisplayName .. " was REVIVED!", Color3.fromRGB(90, 255, 90))
			else
				data.Knobs += 150
				sync(player)
				notify(player, "You're alive, so you got 150 knobs!", Color3.fromRGB(255, 215, 120))
			end
			return true
		end,
		Knobs = function(player, data)
			data.Knobs += 750
			sync(player)
			return true
		end,
		SkipRooms = function(player, data)
			if dead[player] then
				data.Knobs += 200
				sync(player)
				return true
			end
			local target = math.min(Config.FinalRoom - 1, run.Latest + 10)
			for i = run.Latest, target - 1 do
				ensureRoom(i)
				openDoor(i)
			end
			ensureRoom(target)
			local character = player.Character
			if character then
				character:PivotTo(CFrame.new(0, 4, target * L + 8))
			end
			notify(nil, player.DisplayName .. " skipped ahead to door " .. target .. "!", Color3.fromRGB(120, 200, 255))
			return true
		end,
		SummonSahur = function(player)
			notify(nil, player.DisplayName .. " SUMMONED SAHUR! HIDE!", Color3.fromRGB(255, 60, 60))
			task.spawn(rush)
			return true
		end,
	},
	OnPassOwned = function(player, name)
		applyStats(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("BrainrotHotel_v1", {
	Knobs = 0,
	BestDoor = 0,
	Upgrades = {},
})
