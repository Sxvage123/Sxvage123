-- Brainrot Tycoon server: plots, droppers, conveyors, upgraders, purchase buttons, rebirths.
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local NotifyRemote = Instance.new("RemoteEvent")
NotifyRemote.Name = "Notify"
NotifyRemote.Parent = remotes
local RebirthRemote = Instance.new("RemoteFunction")
RebirthRemote.Name = "Rebirth"
RebirthRemote.Parent = remotes

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

Lighting.ClockTime = 14
Lighting.Brightness = 2.5

local world = Instance.new("Folder")
world.Name = "World"
world.Parent = workspace
local dropsFolder = Instance.new("Folder")
dropsFolder.Name = "Drops"
dropsFolder.Parent = workspace

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

local function billboard(adornee: BasePart, text: string, color: Color3, offset: number): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 60)
	gui.StudsOffset = Vector3.new(0, offset, 0)
	gui.MaxDistance = 70
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Parent = label
	label.Parent = gui
	return label
end

part({ Name = "Ground", Size = Vector3.new(500, 2, 400), Position = Vector3.new(0, -1, 0), Color = Color3.fromRGB(90, 190, 90), Material = Enum.Material.Grass }, world)
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = Vector3.new(0, 0.5, 0)
spawn.Neutral = true
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Parent = world

---------------------------------------------------------------- tycoon plots

local tycoons = {}
local playerTycoon: { [Player]: any } = {}

local function playerFromHit(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	return model and Players:GetPlayerFromCharacter(model)
end

local function multiplier(player: Player): number
	local data = DataService.Get(player)
	local m = Config.RebirthMult(data and data.Rebirths or 0)
	if MonetizationService.OwnsPass(player, "DoubleCash") then
		m *= 2
	end
	if data and data.GoldenUntil > os.time() then
		m *= 5
	end
	return m
end

local function updateStats(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Cash", data.Cash)
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("GoldenUntil", data.GoldenUntil)
	player:SetAttribute("CanRebirth", data.Purchased.golden == true)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Cash.Value = Format.Cash(data.Cash)
		stats.Rebirths.Value = data.Rebirths
	end
end

local function addCash(player: Player, amount: number)
	local data = DataService.Get(player)
	if data then
		data.Cash += amount
		if amount > 0 then
			data.TotalEarned += amount
		end
		updateStats(player)
	end
end

-- Theoretical $/sec: used for cash packs.
local function income(player: Player): number
	local t = playerTycoon[player]
	if not t then
		return 0
	end
	local upgrade = 1
	for _, mult in t.Upgraders do
		upgrade *= mult
	end
	local perDrop = 0
	for _, d in t.Droppers do
		perDrop += d.Item.Value
	end
	local interval = Config.DropInterval / (if MonetizationService.OwnsPass(player, "FastDroppers") then 2 else 1)
	return perDrop * upgrade * multiplier(player) / interval
end

local function buildItem(t, item)
	local cf = t.CFrame
	local folder = t.Built
	if item.Kind == "Dropper" then
		local x, side
		if item.Slot == 0 then
			x, side = -32, 0
		else
			x, side = Config.DropperX[item.Slot], Config.DropperSide[item.Slot]
		end
		local z = if side == 0 then 0 else side * 7
		part({ Size = Vector3.new(1.5, 8, 1.5), CFrame = cf * CFrame.new(x, 4, z), Color = Color3.fromRGB(60, 60, 70) }, folder)
		local box = part({ Size = Vector3.new(5, 4, 5), CFrame = cf * CFrame.new(x, 9, z), Color = item.Color }, folder)
		billboard(box, item.Name, Color3.new(1, 1, 1), 4)
		if side ~= 0 then
			part({ Size = Vector3.new(1.5, 1.5, 7), CFrame = cf * CFrame.new(x, 8, side * 3.5), Color = Color3.fromRGB(60, 60, 70) }, folder)
		end
		part({ Size = Vector3.new(2, 2, 2), CFrame = cf * CFrame.new(x, 7, 0), Color = Color3.fromRGB(30, 30, 30) }, folder)
		table.insert(t.Droppers, { Item = item, Spout = cf * CFrame.new(x, 5.5, 0), Next = 0 })
	elseif item.Kind == "Upgrader" then
		local x = item.X
		for _, z in { -3.5, 3.5 } do
			part({ Size = Vector3.new(1, 7, 1), CFrame = cf * CFrame.new(x, 4.5, z), Color = Color3.fromRGB(50, 50, 60) }, folder)
		end
		local top = part({ Size = Vector3.new(1.5, 1, 8), CFrame = cf * CFrame.new(x, 8.5, 0), Color = Color3.fromRGB(50, 50, 60) }, folder)
		billboard(top, item.Name, item.Color, 3)
		local laser = part({
			Size = Vector3.new(0.4, 5, 6),
			CFrame = cf * CFrame.new(x, 4.5, 0),
			Color = item.Color,
			Material = Enum.Material.Neon,
			Transparency = 0.4,
			CanCollide = false,
		}, folder)
		local tag = "Up_" .. item.Id
		laser.Touched:Connect(function(hit)
			if hit.Parent == dropsFolder and hit:GetAttribute("Tycoon") == t.Index and not hit:GetAttribute(tag) then
				hit:SetAttribute(tag, true)
				hit:SetAttribute("Value", (hit:GetAttribute("Value") or 0) * item.Mult)
				hit.Color = item.Color
			end
		end)
		table.insert(t.Upgraders, item.Mult)
	elseif item.Kind == "Build" then
		for _, spec in item.Parts do
			part({
				Size = spec.Size,
				CFrame = cf * spec.Offset,
				Color = spec.Color,
				Material = spec.Material or Enum.Material.SmoothPlastic,
				Shape = spec.Shape or Enum.PartType.Block,
			}, folder)
		end
	end
end

local function refreshButtons(t)
	local player = t.Owner
	local data = player and DataService.Get(player)
	for id, button in t.Buttons do
		local item = Config.ItemById[id]
		local visible = data ~= nil
			and not data.Purchased[id]
			and (item.Requires == nil or data.Purchased[item.Requires] == true)
		button.Transparency = if visible then 0 else 1
		button.CanTouch = visible
		local gui = button:FindFirstChildOfClass("BillboardGui")
		if gui then
			gui.Enabled = visible
		end
	end
end

local function resetTycoon(t)
	t.Built:ClearAllChildren()
	table.clear(t.Droppers)
	table.clear(t.Upgraders)
	t.Bank = 0
	t.BankLabel.Text = "COLLECT $0"
	for _, drop in dropsFolder:GetChildren() do
		if drop:GetAttribute("Tycoon") == t.Index then
			drop:Destroy()
		end
	end
end

local function loadTycoon(t, player: Player)
	resetTycoon(t)
	local data = DataService.Get(player)
	for _, item in Config.Items do
		if data.Purchased[item.Id] then
			buildItem(t, item)
		end
	end
	if MonetizationService.OwnsPass(player, "VIP") then
		buildItem(t, Config.VIPDropper)
	end
	refreshButtons(t)
end

local function buy(t, player: Player, item)
	local data = DataService.Get(player)
	if not data or data.Purchased[item.Id] then
		return
	end
	if item.Requires and not data.Purchased[item.Requires] then
		return
	end
	if data.Cash < item.Cost then
		notify(player, "Need " .. Format.Cash(item.Cost - data.Cash) .. " more!", Color3.fromRGB(255, 90, 90))
		return
	end
	data.Cash -= item.Cost
	data.Purchased[item.Id] = true
	buildItem(t, item)
	refreshButtons(t)
	updateStats(player)
	if item.Id == "golden" then
		notify(nil, player.DisplayName .. " FINISHED their tycoon!", Color3.fromRGB(255, 215, 0))
		notify(player, "You can now REBIRTH for " .. Config.RebirthMult(data.Rebirths + 1) .. "x cash!", Color3.fromRGB(255, 215, 0))
	end
end

do
	local index = 0
	for _, z in { 95, -95 } do
		for _, x in { -110, 0, 110 } do
			index += 1
			local cf = CFrame.lookAt(Vector3.new(x, 0, z), Vector3.new(x, 0, 0))
			local model = Instance.new("Model")
			model.Name = "Tycoon" .. index
			model.Parent = world
			part({ Name = "Base", Size = Vector3.new(82, 0.4, 82), CFrame = cf * CFrame.new(0, 0.2, 0), Color = Color3.fromRGB(70, 150, 70) }, model)
			local conveyor = part({
				Name = "Conveyor",
				Size = Vector3.new(68, 1, 5),
				CFrame = cf * CFrame.new(-1, 1.5, 0),
				Color = Color3.fromRGB(40, 40, 45),
				Material = Enum.Material.DiamondPlate,
			}, model)
			conveyor.AssemblyLinearVelocity = cf.RightVector * 10
			for _, side in { -1, 1 } do
				part({ Name = "Rail", Size = Vector3.new(68, 1.5, 0.5), CFrame = cf * CFrame.new(-1, 2.75, side * 2.75), Color = Color3.fromRGB(255, 200, 0) }, model)
			end
			local collector = part({
				Name = "Collector",
				Size = Vector3.new(4, 3, 6),
				CFrame = cf * CFrame.new(35, 2, 0),
				Color = Color3.fromRGB(40, 220, 80),
				Material = Enum.Material.Neon,
			}, model)
			local collectPad = part({ Name = "CollectPad", Size = Vector3.new(8, 1, 8), CFrame = cf * CFrame.new(32, 1, -14), Color = Color3.fromRGB(40, 220, 80), Material = Enum.Material.Neon }, model)
			local bankLabel = billboard(collectPad, "COLLECT $0", Color3.fromRGB(120, 255, 120), 4)
			local signPart = part({ Name = "Sign", Size = Vector3.new(20, 5, 1), CFrame = cf * CFrame.new(0, 15, 41), Color = Color3.fromRGB(50, 50, 60) }, model)
			local signLabel = billboard(signPart, "Empty Tycoon", Color3.new(1, 1, 1), 0)
			local built = Instance.new("Model")
			built.Name = "Built"
			built.Parent = model

			local t = {
				Index = index,
				CFrame = cf,
				Owner = nil,
				Built = built,
				Buttons = {},
				Droppers = {},
				Upgraders = {},
				Bank = 0,
				BankLabel = bankLabel,
				SignLabel = signLabel,
				SpawnCFrame = cf * CFrame.new(0, 4, -32),
			}
			tycoons[index] = t

			collector.Touched:Connect(function(hit)
				if hit.Parent ~= dropsFolder or hit:GetAttribute("Tycoon") ~= index then
					return
				end
				local value = hit:GetAttribute("Value") or 0
				hit:Destroy()
				local owner = t.Owner
				if not owner then
					return
				end
				local amount = value * multiplier(owner)
				if MonetizationService.OwnsPass(owner, "AutoCollect") then
					addCash(owner, amount)
				else
					t.Bank += amount
					bankLabel.Text = "COLLECT " .. Format.Cash(t.Bank)
				end
			end)
			local collectBusy = false
			collectPad.Touched:Connect(function(hit)
				local player = playerFromHit(hit)
				if collectBusy or not player or player ~= t.Owner or t.Bank < 1 then
					return
				end
				collectBusy = true
				local amount = math.floor(t.Bank)
				t.Bank -= amount
				bankLabel.Text = "COLLECT " .. Format.Cash(t.Bank)
				addCash(player, amount)
				notify(player, "+" .. Format.Cash(amount), Color3.fromRGB(90, 255, 90))
				task.wait(0.4)
				collectBusy = false
			end)

			-- Purchase buttons in a grid at the front of the plot.
			for i, item in Config.Items do
				local col = (i - 1) % 6
				local row = math.floor((i - 1) / 6)
				local button = part({
					Name = "Button_" .. item.Id,
					Size = Vector3.new(5, 0.6, 5),
					CFrame = cf * CFrame.new(-25 + col * 10, 0.7, -36 + row * 8),
					Color = if item.Cost == 0 then Color3.fromRGB(90, 255, 90) else Color3.fromRGB(255, 70, 70),
					Material = Enum.Material.Neon,
					CanCollide = false,
				}, model)
				billboard(button, item.Name .. "\n" .. (if item.Cost == 0 then "FREE" else Format.Cash(item.Cost)), Color3.new(1, 1, 1), 3)
				button.Touched:Connect(function(hit)
					local player = playerFromHit(hit)
					if player and player == t.Owner then
						buy(t, player, item)
					end
				end)
				t.Buttons[item.Id] = button
			end
			refreshButtons(t)
		end
	end
end

---------------------------------------------------------------- droppers

task.spawn(function()
	while true do
		task.wait(0.2)
		local now = os.clock()
		for _, t in tycoons do
			local owner = t.Owner
			if not owner then
				continue
			end
			local interval = Config.DropInterval / (if MonetizationService.OwnsPass(owner, "FastDroppers") then 2 else 1)
			for _, d in t.Droppers do
				if now >= d.Next then
					d.Next = now + interval
					local drop = Instance.new("Part")
					drop.Size = Vector3.new(1.2, 1.2, 1.2)
					drop.Color = d.Item.Color
					drop.Material = Enum.Material.SmoothPlastic
					drop.CFrame = d.Spout
					drop.TopSurface = Enum.SurfaceType.Smooth
					drop:SetAttribute("Tycoon", t.Index)
					drop:SetAttribute("Value", d.Item.Value)
					drop.Parent = dropsFolder
					drop:SetNetworkOwner(nil)
					Debris:AddItem(drop, 25)
				end
			end
		end
	end
end)

---------------------------------------------------------------- players

local function claim(player: Player)
	for _, t in tycoons do
		if not t.Owner then
			t.Owner = player
			t.SignLabel.Text = player.DisplayName .. "'s Tycoon"
			playerTycoon[player] = t
			loadTycoon(t, player)
			return t
		end
	end
	return nil
end

DataService.ProfileLoaded:Connect(function(player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = stats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = stats
	stats.Parent = player
	if not claim(player) then
		notify(player, "All tycoons are taken! Try another server.", Color3.fromRGB(255, 90, 90))
	end
	if data.LastSave > 0 then
		local away = math.min(os.time() - data.LastSave, 3600)
		local earned = math.floor(away * income(player) * 0.3)
		if earned > 0 then
			addCash(player, earned)
			task.delay(3, notify, player, "Your tycoon earned " .. Format.Cash(earned) .. " while you were away!", Color3.fromRGB(90, 255, 90))
		end
	end
	updateStats(player)
	local function onCharacter(character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait()
		local t = playerTycoon[player]
		if t then
			character:PivotTo(t.SpawnCFrame)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end)

DataService.ProfileReleasing:Connect(function(player, data)
	local t = playerTycoon[player]
	if t and t.Owner == player then
		data.Cash += math.floor(t.Bank)
		t.Bank = 0
	end
end)

Players.PlayerRemoving:Connect(function(player)
	task.defer(function()
		local t = playerTycoon[player]
		if not t then
			return
		end
		playerTycoon[player] = nil
		t.Owner = nil
		t.SignLabel.Text = "Empty Tycoon"
		resetTycoon(t)
		refreshButtons(t)
	end)
end)

RebirthRemote.OnServerInvoke = function(player)
	local data = DataService.Get(player)
	if not data then
		return false, "Loading..."
	end
	if not data.Purchased.golden then
		return false, "Finish your tycoon (buy the Golden Brainrot) to rebirth!"
	end
	data.Purchased = {}
	data.Cash = 0
	data.Rebirths += 1
	local t = playerTycoon[player]
	if t then
		loadTycoon(t, player)
	end
	updateStats(player)
	notify(nil, player.DisplayName .. " rebirthed! (" .. data.Rebirths .. ")", Color3.fromRGB(255, 215, 0))
	return true, "Rebirthed! " .. Config.RebirthMult(data.Rebirths) .. "x cash forever."
end

---------------------------------------------------------------- monetization

local function cashPack(seconds: number, min: number)
	return function(player)
		local amount = math.max(min, math.floor(income(player) * seconds))
		addCash(player, amount)
		notify(player, "+" .. Format.Cash(amount) .. "! Thanks!", Color3.fromRGB(90, 255, 90))
		return true
	end
end

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		CashSmall = cashPack(600, 1_000),
		CashLarge = cashPack(7200, 50_000),
		GoldenHour = function(player, data)
			data.GoldenUntil = math.max(data.GoldenUntil, os.time()) + 15 * 60
			updateStats(player)
			notify(nil, player.DisplayName .. " started a GOLDEN HOUR (5x cash)!", Color3.fromRGB(255, 215, 0))
			return true
		end,
	},
	OnPassOwned = function(player, name)
		local t = playerTycoon[player]
		if name == "VIP" and t then
			buildItem(t, Config.VIPDropper)
		end
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("BrainrotTycoon_v1", {
	Cash = 0,
	Rebirths = 0,
	Purchased = {},
	TotalEarned = 0,
	GoldenUntil = 0,
})
