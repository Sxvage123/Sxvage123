-- Brainrot Jump Rope server: the rope sweeps the floor each rotation; anyone on the ground in the rope's
-- path at that moment is out. Last one jumping wins.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotModels = require(ReplicatedStorage.Common.BrainrotModels)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local NotifyRemote = Instance.new("RemoteEvent")
NotifyRemote.Name = "Notify"
NotifyRemote.Parent = remotes
local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

local world = Instance.new("Folder")
world.Name = "World"
world.Parent = workspace
local function part(props): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = world
	return p
end

local ROPE_LEN, ARENA_W, AXIS_Y = 70, 24, 9
part({ Name = "Arena", Size = Vector3.new(ROPE_LEN, 1, ARENA_W), Position = Vector3.new(0, -0.5, 0), Color = Color3.fromRGB(240, 120, 160), Material = Enum.Material.SmoothPlastic })
part({ Name = "Lobby", Size = Vector3.new(ROPE_LEN, 1, 30), Position = Vector3.new(0, -0.5, -40), Color = Color3.fromRGB(120, 200, 240) })
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = Vector3.new(0, 0.5, -40)
spawn.Neutral = true
spawn.Parent = world
-- Fence between lobby and arena so only players in the round are on the rope floor.
part({ Name = "Fence", Size = Vector3.new(ROPE_LEN, 6, 1), Position = Vector3.new(0, 3, -ARENA_W / 2 - 2), Transparency = 0.6, Color = Color3.new(1, 1, 1) })
for _, sx in { -1, 1 } do
	local m, _ = BrainrotModels.Build(if sx < 0 then "tung" else "chimpanzini", { Scale = 1.8 })
	m:PivotTo(CFrame.new(sx * (ROPE_LEN / 2 + 4), (m:GetAttribute("RootHeight") :: number?) or 6, 0) * CFrame.Angles(0, sx * math.pi / 2, 0))
	m.Parent = world
end
local rope = part({ Name = "Rope", Shape = Enum.PartType.Cylinder, Size = Vector3.new(ROPE_LEN, 0.9, 0.9), Color = Color3.fromRGB(255, 230, 60), Material = Enum.Material.Neon, CanCollide = false, CanTouch = false })
local function placeRope(angle: number)
	-- The rope circles the axis (x-axis at height AXIS_Y); angle 0 = touching the floor.
	local offset = Vector3.new(0, -math.cos(angle) * (AXIS_Y - 0.6), math.sin(angle) * (AXIS_Y - 0.6))
	rope.CFrame = CFrame.new(Vector3.new(0, AXIS_Y, 0) + offset)
end
placeRope(math.pi)

local state = { Stage = "Lobby", Turbo = 0 }
local shieldUsed: { [Player]: boolean } = {}

local function rootOf(p: Player): BasePart?
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil
	end
	return (p.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart?
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
local function sync(p: Player)
	local data = DataService.Get(p)
	if not data then
		return
	end
	p:SetAttribute("Coins", data.Coins)
	p:SetAttribute("Wins", data.Wins)
	p:SetAttribute("BestJumps", data.BestJumps)
	local ls = p:FindFirstChild("leaderstats")
	if ls then
		(ls :: any).Wins.Value = data.Wins;
		(ls :: any)["Best Jumps"].Value = data.BestJumps
	end
end
local function give(p: Player, coins: number)
	local data = DataService.Get(p)
	if data then
		local m = (if MonetizationService.OwnsPass(p, "DoubleCoins") then 2 else 1) * (if MonetizationService.OwnsPass(p, "VIP") then 1.5 else 1)
		data.Coins += math.floor(coins * m)
		sync(p)
	end
end
local function arenaSpot(): CFrame
	return CFrame.new(math.random(-ROPE_LEN / 2 + 8, ROPE_LEN / 2 - 8), 4, math.random(-6, 6))
end
local function out(p: Player)
	p:SetAttribute("InRound", false)
	notify(nil, p.DisplayName .. " tripped on the rope! (" .. tostring(p:GetAttribute("Jumps") or 0) .. " jumps)", Color3.fromRGB(255, 90, 90))
	local character = p.Character :: Model
	character:PivotTo(CFrame.new(0, 4, -40))
end
local function applyJump(p: Player)
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.UseJumpPower = true
		hum.JumpPower = if MonetizationService.OwnsPass(p, "SuperJump") then 62 else 50
	end
end

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
		state.Stage = "Round"
		state.Turbo = 0
		workspace:SetAttribute("Stage", "Round")
		table.clear(shieldUsed)
		for _, p in players do
			p:SetAttribute("InRound", true)
			p:SetAttribute("Jumps", 0)
			p.Character:PivotTo(arenaSpot())
			applyJump(p)
		end
		task.wait(3)
		local angle, spin, rotations = math.pi, Config.StartSpin, 0
		local start, last = os.clock(), os.clock()
		while #inRound() > 0 and os.clock() - start < Config.RoundMax do
			task.wait(0.03)
			local now = os.clock()
			local before = angle
			angle += (spin + state.Turbo) * (now - last)
			last = now
			placeRope(angle)
			workspace:SetAttribute("Jumps", rotations)
			-- The rope hits the floor each time the angle crosses a multiple of 2*pi.
			if math.floor(before / (2 * math.pi)) ~= math.floor(angle / (2 * math.pi)) then
				rotations += 1
				spin = math.min(Config.MaxSpin, spin + Config.SpinGrowth)
				for _, p in inRound() do
					local root = rootOf(p) :: BasePart
					if root.Position.Y < 4.2 and math.abs(root.Position.Z) < ARENA_W / 2 + 2 then
						if MonetizationService.OwnsPass(p, "Shield") and not shieldUsed[p] then
							shieldUsed[p] = true
							notify(p, "Rope Shield saved you!", Color3.fromRGB(120, 200, 255))
						else
							out(p)
						end
					else
						p:SetAttribute("Jumps", (p:GetAttribute("Jumps") or 0) + 1)
						give(p, Config.CoinsPerJump)
					end
				end
				if #players > 1 and #inRound() <= 1 then
					break
				end
			end
		end
		placeRope(math.pi)
		for _, p in Players:GetPlayers() do
			local data = DataService.Get(p)
			local jumps = p:GetAttribute("Jumps") or 0
			if data and jumps > data.BestJumps then
				data.BestJumps = jumps
				sync(p)
			end
		end
		for _, p in inRound() do
			local data = DataService.Get(p)
			if data then
				data.Wins += 1
			end
			give(p, Config.WinCoins)
			notify(nil, p.DisplayName .. " WINS JUMP ROPE!", Color3.fromRGB(255, 215, 0))
			p.Character:PivotTo(CFrame.new(0, 4, -40))
		end
		for _, p in Players:GetPlayers() do
			p:SetAttribute("InRound", false)
		end
	end
end)

DataService.ProfileLoaded:Connect(function(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, n in { "Wins", "Best Jumps" } do
		local v = Instance.new("IntValue")
		v.Name = n
		v.Parent = ls
	end
	ls.Parent = player
	sync(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 10)
		applyJump(player)
	end)
	applyJump(player)
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		Revive = function(player, data)
			if state.Stage == "Round" and not player:GetAttribute("InRound") and player.Character then
				player:SetAttribute("InRound", true)
				player.Character:PivotTo(arenaSpot())
				notify(nil, player.DisplayName .. " REVIVED!", Color3.fromRGB(90, 255, 90))
			else
				data.Coins += 300
				sync(player)
			end
			return true
		end,
		Coins = function(player, data)
			data.Coins += 1000
			sync(player)
			return true
		end,
		SpeedUp = function(player)
			state.Turbo += 1.5
			notify(nil, player.DisplayName .. " activated TURBO ROPE!", Color3.fromRGB(255, 80, 80))
			return true
		end,
	},
	OnPassOwned = function(player, name)
		applyJump(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("BrainrotJumpRope_v1", { Coins = 0, Wins = 0, BestJumps = 0 })
