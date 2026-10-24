-- Find the Brainrots server: collectibles, saving, hints, teleports, coils.
local BadgeService = game:GetService("BadgeService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)
local World = require(script.Parent.World)

-- Optional: put a Badge ID here to award when someone finds every brainrot.
local COMPLETION_BADGE_ID = 0

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
local GuideRemote = remote("RemoteEvent", "Guide")
local TeleportRemote = remote("RemoteEvent", "Teleport")

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

local spots = World.Build()
local TOTAL = math.min(#spots, #Config.Names)
workspace:SetAttribute("TotalBrainrots", TOTAL)

local collectFolder = Instance.new("Folder")
collectFolder.Name = "Collectibles"
collectFolder.Parent = workspace

local collectibles = {}

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local list, count = {}, 0
	for id in data.Found do
		table.insert(list, id)
		count += 1
	end
	player:SetAttribute("Found", table.concat(list, ","))
	player:SetAttribute("FoundCount", count)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Found.Value = count
	end
end

local function collect(player: Player, index: number)
	local data = DataService.Get(player)
	local key = tostring(index)
	if not data or data.Found[key] then
		return
	end
	data.Found[key] = true
	local count = 0
	for _ in data.Found do
		count += 1
	end
	notify(player, "Found " .. Config.Names[index] .. "! (" .. count .. "/" .. TOTAL .. ")", Color3.fromHSV(index / TOTAL, 0.7, 1))
	if count >= TOTAL then
		notify(nil, player.DisplayName .. " FOUND ALL " .. TOTAL .. " BRAINROTS!", Color3.fromRGB(255, 215, 0))
		if COMPLETION_BADGE_ID > 0 then
			pcall(BadgeService.AwardBadge, BadgeService, player.UserId, COMPLETION_BADGE_ID)
		end
	end
	sync(player)
end

for index = 1, TOTAL do
	local s = spots[index]
	local color = Color3.fromHSV(index / TOTAL, 0.7, 1)
	local model = Instance.new("Model")
	model.Name = "Brainrot" .. index
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.one * 2.6
	body.Color = color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Position = s.Position
	body.Parent = model
	for _, side in { -1, 1 } do
		local eye = Instance.new("Part")
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.one * 0.7
		eye.Color = Color3.new(1, 1, 1)
		eye.Anchored = false
		eye.Massless = true
		eye.CanCollide = false
		eye.CanTouch = false
		eye.Position = s.Position + Vector3.new(side * 0.5, 0.4, -1.1)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = eye
		weld.Parent = eye
		eye.Parent = model
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(160, 30)
	gui.StudsOffset = Vector3.new(0, 2.5, 0)
	gui.MaxDistance = 30
	gui.Parent = body
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = Config.Names[index]
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = label
	label.Parent = gui
	model.PrimaryPart = body
	model:SetAttribute("Index", index)
	model.Parent = collectFolder
	CollectionService:AddTag(model, "Collectible")
	collectibles[index] = body
	body.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			collect(player, index)
		end
	end)
end

local function applyCoils(player: Player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.UseJumpPower = true
		humanoid.WalkSpeed = if MonetizationService.OwnsPass(player, "SpeedCoil") then 28 else 16
		humanoid.JumpPower = if MonetizationService.OwnsPass(player, "GravityCoil") then 85 else 50
	end
end

TeleportRemote.OnServerEvent:Connect(function(player, zoneIndex)
	local zone = type(zoneIndex) == "number" and Config.ZoneSpawns[zoneIndex]
	if zone and MonetizationService.OwnsPass(player, "Teleporter") and player.Character then
		player.Character:PivotTo(CFrame.new(zone.Position))
	end
end)

local function unfound(data): { number }
	local list = {}
	for index = 1, TOTAL do
		if not data.Found[tostring(index)] then
			table.insert(list, index)
		end
	end
	return list
end

DataService.ProfileLoaded:Connect(function(player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local found = Instance.new("IntValue")
	found.Name = "Found"
	found.Parent = stats
	stats.Parent = player
	for key in data.Found do
		local n = tonumber(key)
		if not n or n > TOTAL then
			data.Found[key] = nil
		end
	end
	sync(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 10)
		applyCoils(player)
	end)
	if player.Character then
		applyCoils(player)
	end
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		Hint = function(player, data)
			local list = unfound(data)
			if #list == 0 then
				notify(player, "You already found them all!", Color3.fromRGB(255, 215, 0))
				return true
			end
			local index = list[math.random(1, #list)]
			GuideRemote:FireClient(player, collectibles[index].Position, 60, spots[index].Hint)
			return true
		end,
		AutoFind = function(player, data)
			local list = unfound(data)
			if #list > 0 then
				collect(player, list[math.random(1, #list)])
			end
			return true
		end,
	},
	OnPassOwned = function(player, name)
		applyCoils(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

-- Hints are public so the index can show them.
local hints = {}
for index = 1, TOTAL do
	hints[index] = spots[index].Hint
end
local hintsValue = Instance.new("StringValue")
hintsValue.Name = "Hints"
hintsValue.Value = game:GetService("HttpService"):JSONEncode(hints)
hintsValue.Parent = ReplicatedStorage

DataService.Init("FindTheBrainrots_v1", {
	Found = {},
})
