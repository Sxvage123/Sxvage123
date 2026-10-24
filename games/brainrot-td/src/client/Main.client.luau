-- Brainrot Tower Defense client: HUD, unit hotbar + placement, upgrades, summons, tracers.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
local ShopUI = require(ReplicatedStorage.Common.ShopUI)
local UI = require(ReplicatedStorage.Common.UI)

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui = UI.new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") }) :: ScreenGui
local toast = UI.CreateToaster(gui)
remotes:WaitForChild("Notify").OnClientEvent:Connect(toast)
local buy = ShopUI.Buyer(Config, toast)
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(30, 40, 70))
ShopUI.VIPChatTag("VIP")

---------------------------------------------------------------- HUD

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(420, 80),
	BackgroundColor3 = Color3.fromRGB(25, 30, 50),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local waveLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 40), Position = UDim2.fromOffset(5, 2), Parent = top })
local cashLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 30), Position = UDim2.fromOffset(5, 44), TextColor3 = Color3.fromRGB(120, 255, 120), Parent = top })

local startButton = UI.Button("START", Color3.fromRGB(40, 200, 80), {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 94),
	Size = UDim2.fromOffset(220, 56),
	Visible = false,
	Parent = gui,
})
startButton.Activated:Connect(function()
	remotes.Start:FireServer()
end)
local reviveButton = UI.Button("REVIVE BASE  R$ 39", Color3.fromRGB(230, 60, 60), {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.45),
	Size = UDim2.fromOffset(340, 90),
	Visible = false,
	Parent = gui,
})
reviveButton.Activated:Connect(function()
	buy("Product", "ReviveBase")
end)

task.spawn(function()
	while true do
		local state = workspace:GetAttribute("MatchState") or "Lobby"
		local wave = workspace:GetAttribute("Wave") or 0
		local hp = workspace:GetAttribute("BaseHealth") or Config.BaseHealth
		if state == "Lobby" then
			waveLabel.Text = "Place units! Starting in " .. (workspace:GetAttribute("StartIn") or 0)
		elseif state == "Defeat" then
			waveLabel.Text = "BASE DESTROYED! Revive in " .. (workspace:GetAttribute("ReviveIn") or 0)
		elseif state == "Victory" then
			waveLabel.Text = "VICTORY!"
		elseif state == "GameOver" then
			waveLabel.Text = "Game over — wave " .. wave
		else
			waveLabel.Text = "Wave " .. wave .. "/" .. Config.WinWave .. "  •  Base " .. hp .. " HP"
		end
		cashLabel.Text = "$" .. Format.Abbreviate(player:GetAttribute("MatchCash") or 0) .. "   •   💎 " .. Format.Abbreviate(player:GetAttribute("Gems") or 0) .. "   •   " .. (workspace:GetAttribute("GameSpeed") or 1) .. "x"
		startButton.Visible = state == "Lobby"
		reviveButton.Visible = state == "Defeat"
		task.wait(0.2)
	end
end)

---------------------------------------------------------------- tracers

remotes:WaitForChild("Shot").OnClientEvent:Connect(function(from: Vector3, to: Vector3, color: Color3, splash: number)
	local dist = (to - from).Magnitude
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.Material = Enum.Material.Neon
	beam.Color = color
	beam.Size = Vector3.new(0.25, 0.25, dist)
	beam.CFrame = CFrame.lookAt((from + to) / 2, to)
	beam.Parent = workspace
	TweenService:Create(beam, TweenInfo.new(0.15), { Transparency = 1 }):Play()
	Debris:AddItem(beam, 0.2)
	if splash > 0 then
		local boom = Instance.new("Part")
		boom.Anchored = true
		boom.CanCollide = false
		boom.CanQuery = false
		boom.CanTouch = false
		boom.Shape = Enum.PartType.Ball
		boom.Material = Enum.Material.Neon
		boom.Color = color
		boom.Transparency = 0.4
		boom.Size = Vector3.one
		boom.Position = to
		boom.Parent = workspace
		TweenService:Create(boom, TweenInfo.new(0.25), { Size = Vector3.one * splash * 2, Transparency = 1 }):Play()
		Debris:AddItem(boom, 0.3)
	end
end)

---------------------------------------------------------------- inventory + hotbar

local owned, equipped = {}, {}
local hotbar = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -12),
	Size = UDim2.fromOffset(560, 96),
	BackgroundTransparency = 1,
	Parent = gui,
})
local hotLayout = Instance.new("UIListLayout")
hotLayout.FillDirection = Enum.FillDirection.Horizontal
hotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hotLayout.Padding = UDim.new(0, 8)
hotLayout.Parent = hotbar

local placing: string? = nil
local ghost: BasePart? = nil

local function stopPlacing()
	placing = nil
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
end

local function startPlacing(unitId: string)
	stopPlacing()
	local unit = Config.UnitById[unitId]
	placing = unitId
	local g = Instance.new("Part")
	g.Shape = Enum.PartType.Cylinder
	g.Anchored = true
	g.CanCollide = false
	g.CanQuery = false
	g.CanTouch = false
	g.Material = Enum.Material.ForceField
	g.Color = Color3.fromRGB(90, 255, 120)
	g.Size = Vector3.new(0.3, unit.Range * 2, unit.Range * 2)
	g.Parent = workspace
	ghost = g
	toast("Click to place " .. unit.Name .. " ($" .. unit.Cost .. ")  •  Q to cancel", Color3.fromRGB(255, 220, 80))
end

local function renderHotbar()
	for _, c in hotbar:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for _, id in equipped do
		local unit = Config.UnitById[id]
		if unit then
			local b = UI.new("TextButton", {
				Text = "",
				Size = UDim2.fromOffset(100, 96),
				BackgroundColor3 = Color3.fromRGB(35, 40, 60),
				Parent = hotbar,
			}, { UI.Corner(12), UI.Stroke(Config.RarityColor[unit.Rarity], 3) }) :: TextButton
			UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = unit.Color, Parent = b }, { UI.Corner(17) })
			UI.Label(unit.Name, { Position = UDim2.fromOffset(3, 42), Size = UDim2.new(1, -6, 0, 26), TextWrapped = true, Parent = b })
			UI.Label("$" .. unit.Cost, { Position = UDim2.fromOffset(3, 70), Size = UDim2.new(1, -6, 0, 20), TextColor3 = Color3.fromRGB(120, 255, 120), Parent = b })
			b.Activated:Connect(function()
				startPlacing(id)
			end)
		end
	end
end

---------------------------------------------------------------- selection panel

local panel = UI.new("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -12, 0.5, 0),
	Size = UDim2.fromOffset(230, 190),
	BackgroundColor3 = Color3.fromRGB(30, 35, 55),
	Visible = false,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) }) :: Frame
local panelTitle = UI.Label("", { Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 0, 30), Parent = panel })
local panelStats = UI.Label("", { Position = UDim2.fromOffset(8, 38), Size = UDim2.new(1, -16, 0, 40), Font = Enum.Font.GothamMedium, TextWrapped = true, Parent = panel })
local upgradeButton = UI.Button("UPGRADE", Color3.fromRGB(40, 180, 70), { Position = UDim2.fromOffset(10, 84), Size = UDim2.new(1, -20, 0, 46), Parent = panel })
local sellButton = UI.Button("SELL", Color3.fromRGB(200, 60, 60), { Position = UDim2.fromOffset(10, 136), Size = UDim2.new(1, -20, 0, 44), Parent = panel })
local selected: Model? = nil
local rangeRing: BasePart? = nil

local function refreshPanel()
	if not selected or not selected.Parent then
		panel.Visible = false
		if rangeRing then
			rangeRing:Destroy()
			rangeRing = nil
		end
		return
	end
	local unit = Config.UnitById[selected:GetAttribute("UnitId")]
	local level = selected:GetAttribute("Level") or 1
	local stats = Config.UnitStats(unit, level)
	panelTitle.Text = unit.Name .. " Lv" .. level
	panelTitle.TextColor3 = Config.RarityColor[unit.Rarity]
	panelStats.Text = string.format("DMG %d  •  Range %d  •  %.1fs%s", stats.Damage, stats.Range, stats.Cooldown, if stats.Splash > 0 then "  •  Splash" else "")
	upgradeButton.Text = if level >= Config.MaxLevel then "MAX" else "UPGRADE $" .. Config.UpgradeCost(unit, level)
	panel.Visible = true
	if not rangeRing then
		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanQuery = false
		ring.CanTouch = false
		ring.Material = Enum.Material.ForceField
		ring.Color = Color3.fromRGB(80, 180, 255)
		ring.Parent = workspace
		rangeRing = ring
	end
	local pos = (selected.PrimaryPart :: BasePart).Position
	local ring = rangeRing :: BasePart
	ring.Size = Vector3.new(0.3, stats.Range * 2, stats.Range * 2)
	ring.CFrame = CFrame.new(pos.X, 0.4, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
end

upgradeButton.Activated:Connect(function()
	if selected then
		local ok, msg = remotes.Upgrade:InvokeServer(selected:GetAttribute("Uid"))
		toast(msg, if ok then Color3.fromRGB(120, 255, 120) else Color3.fromRGB(255, 90, 90))
		task.wait(0.1)
		refreshPanel()
	end
end)
sellButton.Activated:Connect(function()
	if selected then
		local ok, msg = remotes.Sell:InvokeServer(selected:GetAttribute("Uid"))
		toast(msg, if ok then Color3.fromRGB(255, 220, 80) else Color3.fromRGB(255, 90, 90))
		selected = nil
		refreshPanel()
	end
end)

RunService.RenderStepped:Connect(function()
	if ghost and placing then
		mouse.TargetFilter = ghost
		local p = mouse.Hit.Position
		ghost.CFrame = CFrame.new(p.X, 0.4, p.Z) * CFrame.Angles(0, 0, math.rad(90))
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q then
		stopPlacing()
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if placing then
		local unitId = placing
		mouse.TargetFilter = ghost
		local pos = mouse.Hit.Position
		local ok, msg = remotes.Place:InvokeServer(unitId, pos)
		if ok then
			stopPlacing()
		else
			toast(msg, Color3.fromRGB(255, 90, 90))
		end
		return
	end
	-- Select one of your units
	mouse.TargetFilter = nil
	local target = mouse.Target
	local model = target and target:FindFirstAncestorOfClass("Model")
	if model and model.Parent == workspace:FindFirstChild("Units") and model:GetAttribute("OwnerId") == player.UserId then
		selected = model
	else
		selected = nil
	end
	refreshPanel()
end)

---------------------------------------------------------------- summon + units modals

local function modal(title: string, color: Color3): (Frame, ScrollingFrame)
	local frame = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 540, 0.7, 0),
		BackgroundColor3 = color,
		Visible = false,
		Parent = gui,
	}, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
	UI.Label(title, { Size = UDim2.new(1, -80, 0, 50), Position = UDim2.fromOffset(16, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
	UI.Button("X", Color3.fromRGB(230, 60, 60), { Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -58, 0, 8), Parent = frame }).Activated:Connect(function()
		frame.Visible = false
	end)
	local list = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 64),
		Size = UDim2.new(1, -24, 1, -76),
		BackgroundTransparency = 1,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 8,
		Parent = frame,
	}) :: ScrollingFrame
	return frame, list
end

local summonFrame, summonList = modal("SUMMON", Color3.fromRGB(60, 30, 90))
local summonGrid = Instance.new("UIGridLayout")
summonGrid.CellSize = UDim2.fromOffset(150, 70)
summonGrid.CellPadding = UDim2.fromOffset(8, 8)
summonGrid.SortOrder = Enum.SortOrder.LayoutOrder
summonGrid.Parent = summonList
local oddsText = {}
for _, r in Config.RarityWeights do
	table.insert(oddsText, r.Name .. " " .. r.Weight .. "%")
end
UI.Label(table.concat(oddsText, "  •  "), { Position = UDim2.new(0, 16, 1, -36), Size = UDim2.new(1, -32, 0, 26), Font = Enum.Font.GothamMedium, Parent = summonFrame })
summonList.Size = UDim2.new(1, -24, 1, -170)
summonList.Position = UDim2.fromOffset(12, 124)
local function doSummon(count: number)
	local ok, result = remotes.Summon:InvokeServer(count)
	if not ok then
		toast(result, Color3.fromRGB(255, 90, 90))
		if string.find(result, "gems") then
			buy("Product", "GemsSmall")
		end
		return
	end
	for _, c in summonList:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for i, id in result do
		local unit = Config.UnitById[id]
		local card = UI.new("Frame", { LayoutOrder = i, BackgroundColor3 = Config.RarityColor[unit.Rarity]:Lerp(Color3.new(0, 0, 0), 0.5), Parent = summonList }, { UI.Corner(10), UI.Stroke(Config.RarityColor[unit.Rarity], 3) })
		UI.Label(unit.Name, { Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, 36), TextWrapped = true, Parent = card })
		UI.Label(unit.Rarity, { Position = UDim2.fromOffset(4, 42), Size = UDim2.new(1, -8, 0, 22), TextColor3 = Config.RarityColor[unit.Rarity], Parent = card })
	end
end
UI.Button("Summon x1  (" .. Config.SummonCost .. "💎)", Color3.fromRGB(170, 70, 255), { Position = UDim2.fromOffset(16, 64), Size = UDim2.fromOffset(240, 52), Parent = summonFrame }).Activated:Connect(function()
	doSummon(1)
end)
UI.Button("Summon x10  (" .. Config.SummonCost * 9 .. "💎)", Color3.fromRGB(255, 170, 0), { Position = UDim2.new(1, -256, 0, 64), Size = UDim2.fromOffset(240, 52), Parent = summonFrame }).Activated:Connect(function()
	doSummon(10)
end)

local unitsFrame, unitsList = modal("MY UNITS", Color3.fromRGB(30, 40, 70))
local unitsLayout = Instance.new("UIListLayout")
unitsLayout.Padding = UDim.new(0, 6)
unitsLayout.SortOrder = Enum.SortOrder.LayoutOrder
unitsLayout.Parent = unitsList
local function renderUnits()
	for _, c in unitsList:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for i, unit in Config.Units do
		local count = owned[unit.Id]
		if not count then
			continue
		end
		local isEquipped = table.find(equipped, unit.Id) ~= nil
		local row = UI.new("Frame", { LayoutOrder = -i, Size = UDim2.new(1, -10, 0, 60), BackgroundColor3 = Color3.fromRGB(45, 55, 90), Parent = unitsList }, { UI.Corner(10) })
		UI.Label(unit.Name .. " x" .. count, { Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -150, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Config.RarityColor[unit.Rarity], Parent = row })
		UI.Label(string.format("%s • DMG %d • Range %d • $%d", unit.Rarity, unit.Damage, unit.Range, unit.Cost), { Position = UDim2.fromOffset(10, 32), Size = UDim2.new(1, -150, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, Parent = row })
		local b = UI.Button(if isEquipped then "UNEQUIP" else "EQUIP", if isEquipped then Color3.fromRGB(150, 70, 70) else Color3.fromRGB(40, 180, 70), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(120, 46), Parent = row })
		b.Activated:Connect(function()
			local ok, msg = remotes.Equip:InvokeServer(unit.Id, not isEquipped)
			if not ok and msg then
				toast(msg, Color3.fromRGB(255, 90, 90))
			end
		end)
	end
end

remotes:WaitForChild("Inventory").OnClientEvent:Connect(function(u, e)
	owned, equipped = u, e
	renderHotbar()
	if unitsFrame.Visible then
		renderUnits()
	end
end)

local side = ShopUI.SideBar(gui)
local frames = { shop, summonFrame, unitsFrame }
local function toggle(frame: Frame)
	for _, f in frames do
		if f ~= frame then
			f.Visible = false
		end
	end
	frame.Visible = not frame.Visible
end
UI.Button("SUMMON", Color3.fromRGB(170, 70, 255), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	toggle(summonFrame)
end)
UI.Button("UNITS", Color3.fromRGB(80, 140, 255), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	toggle(unitsFrame)
	renderUnits()
end)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	toggle(shop)
end)
UI.Button("2x SPEED", Color3.fromRGB(255, 170, 0), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	if player:GetAttribute("Pass_DoubleSpeed") then
		remotes.ToggleSpeed:FireServer()
	else
		buy("Pass", "DoubleSpeed")
	end
end)
