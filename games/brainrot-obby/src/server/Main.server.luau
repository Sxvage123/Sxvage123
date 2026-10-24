-- Escape the Brainrot Obby server: checkpoints, kill bricks, skips, coils, wins.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)
local Course = require(script.Parent.Course)

Lighting.ClockTime = 16
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
local SelectStageRemote = remote("RemoteEvent", "SelectStage")
local CoilRemote = remote("RemoteEvent", "ToggleCoil")
local FreeSkipRemote = remote("RemoteEvent", "FreeSkip")

local checkpoints = Course.Build()
local FINISH = Config.StageCount + 1

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("MaxStage", data.MaxStage)
	player:SetAttribute("Wins", data.Wins)
	player:SetAttribute("FreeSkips", data.FreeSkips)
	if not player:GetAttribute("Stage") then
		player:SetAttribute("Stage", data.MaxStage)
	end
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Stage.Value = player:GetAttribute("Stage")
		stats.Wins.Value = data.Wins
	end
end

local function teleportToStage(player: Player, stage: number)
	player:SetAttribute("Stage", stage)
	sync(player)
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		character:PivotTo(checkpoints[stage].CFrame * CFrame.new(0, 4, 0))
	end
end

local function applyMovement(player: Player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.UseJumpPower = true
	local speed = player:GetAttribute("SpeedOn") and MonetizationService.OwnsPass(player, "SpeedCoil")
	local gravity = player:GetAttribute("GravityOn") and MonetizationService.OwnsPass(player, "GravityCoil")
	humanoid.WalkSpeed = if speed then Config.SpeedCoilWalkSpeed else Config.NormalWalkSpeed
	humanoid.JumpPower = if gravity then Config.GravityCoilJump else Config.NormalJump
end

local function addTrail(player: Player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or root:FindFirstChild("VIPTrail") then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1, 0)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -1, 0)
	a1.Parent = root
	local trail = Instance.new("Trail")
	trail.Name = "VIPTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.6
	trail.LightEmission = 1
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255)),
	})
	trail.Parent = root
end

local function win(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local gained = if MonetizationService.OwnsPass(player, "DoubleWins") then 2 else 1
	data.Wins += gained
	data.MaxStage = 1
	if MonetizationService.OwnsPass(player, "VIP") then
		data.FreeSkips += 1
	end
	notify(nil, player.DisplayName .. " ESCAPED THE BRAINROT! (" .. data.Wins .. " wins)", Color3.fromRGB(255, 215, 0))
	task.delay(2, function()
		if player.Parent then
			teleportToStage(player, 1)
		end
	end)
	sync(player)
end

local function reachStage(player: Player, stage: number)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local current = player:GetAttribute("Stage") or 1
	if stage == FINISH then
		if current == Config.StageCount then
			player:SetAttribute("Stage", FINISH)
			win(player)
		end
		return
	end
	if stage == current + 1 then
		player:SetAttribute("Stage", stage)
		if stage > data.MaxStage then
			data.MaxStage = stage
			data.TotalStages += 1
		end
		sync(player)
	end
end

local function playerFromHit(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	return model and Players:GetPlayerFromCharacter(model)
end

for stage, cp in checkpoints do
	cp.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if player then
			reachStage(player, stage)
		end
	end)
end

for _, p in workspace.Course:GetDescendants() do
	if not p:IsA("BasePart") then
		continue
	end
	if p:GetAttribute("Kill") then
		p.Touched:Connect(function(hit)
			local model = hit:FindFirstAncestorOfClass("Model")
			local humanoid = model and model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
			end
		end)
	end
	local fade = p:GetAttribute("Fade")
	if fade then
		local busy = false
		p.Touched:Connect(function(hit)
			if busy or not playerFromHit(hit) then
				return
			end
			busy = true
			p.Transparency = 0.5
			task.wait(fade)
			p.Transparency = 0.9
			p.CanCollide = false
			task.wait(2)
			p.Transparency = 0
			p.CanCollide = true
			busy = false
		end)
	end
end

-- Falling off the world just respawns you at your checkpoint.
workspace.FallenPartsDestroyHeight = -100

local function skip(player: Player, amount: number): boolean
	local data = DataService.Get(player)
	if not data then
		return false
	end
	local current = player:GetAttribute("Stage") or 1
	local target = math.min(current + amount, Config.StageCount)
	if target <= current then
		-- Already on the last stage: send them over the finish line.
		player:SetAttribute("Stage", Config.StageCount)
		reachStage(player, FINISH)
		return true
	end
	data.MaxStage = math.max(data.MaxStage, target)
	teleportToStage(player, target)
	return true
end

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		SkipStage = function(player)
			return skip(player, 1)
		end,
		Skip5 = function(player)
			return skip(player, 5)
		end,
		SkipToEnd = function(player)
			return skip(player, Config.StageCount)
		end,
	},
	OnPassOwned = function(player, name)
		if name == "VIP" then
			addTrail(player)
		end
		if name == "SpeedCoil" then
			player:SetAttribute("SpeedOn", true)
		elseif name == "GravityCoil" then
			player:SetAttribute("GravityOn", true)
		end
		applyMovement(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

SelectStageRemote.OnServerEvent:Connect(function(player, stage)
	local data = DataService.Get(player)
	if data and type(stage) == "number" and stage % 1 == 0 and stage >= 1 and stage <= data.MaxStage then
		teleportToStage(player, stage)
	end
end)

CoilRemote.OnServerEvent:Connect(function(player, name)
	if name == "Speed" then
		player:SetAttribute("SpeedOn", not player:GetAttribute("SpeedOn"))
	elseif name == "Gravity" then
		player:SetAttribute("GravityOn", not player:GetAttribute("GravityOn"))
	end
	applyMovement(player)
end)

FreeSkipRemote.OnServerEvent:Connect(function(player)
	local data = DataService.Get(player)
	if data and data.FreeSkips > 0 then
		data.FreeSkips -= 1
		skip(player, 1)
	end
end)

DataService.ProfileLoaded:Connect(function(player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local stage = Instance.new("IntValue")
	stage.Name = "Stage"
	stage.Parent = stats
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Parent = stats
	stats.Parent = player
	sync(player)
	local function onCharacter(character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait()
		teleportToStage(player, player:GetAttribute("Stage") or data.MaxStage)
		applyMovement(player)
		if MonetizationService.OwnsPass(player, "VIP") then
			addTrail(player)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end)

DataService.Init("BrainrotObby_v1", {
	MaxStage = 1,
	Wins = 0,
	FreeSkips = 0,
	TotalStages = 0,
})
