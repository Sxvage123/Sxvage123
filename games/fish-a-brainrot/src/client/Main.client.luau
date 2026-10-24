-- Fish a Brainrot client: casting, reel minigame, rods, selling, auto fish, shop.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(20, 50, 80))

---------------------------------------------------------------- HUD

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(380, 80),
	BackgroundColor3 = Color3.fromRGB(20, 50, 80),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local cashLabel = UI.Label("$0", { Size = UDim2.new(1, -10, 0, 44), Position = UDim2.fromOffset(5, 2), TextColor3 = Color3.fromRGB(120, 255, 120), Parent = top })
local bagLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 26), Position = UDim2.fromOffset(5, 48), Parent = top })
local statusLabel = UI.Label("Equip your rod and click the water!", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -110),
	Size = UDim2.fromOffset(520, 34),
	Parent = gui,
})
local banner = UI.Label("", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 92), Size = UDim2.fromOffset(500, 28), TextColor3 = Color3.fromRGB(0, 255, 200), Parent = gui })

local function refresh()
	cashLabel.Text = Format.Cash(player:GetAttribute("Cash") or 0)
	bagLabel.Text = string.format("🎣 %d/%d fish  •  worth %s  •  luck x%g", player:GetAttribute("FishCount") or 0, Config.InventoryCap, Format.Cash(player:GetAttribute("FishValue") or 0), math.floor((player:GetAttribute("Luck") or 1) * 10) / 10)
end
player.AttributeChanged:Connect(refresh)
refresh()
task.spawn(function()
	while true do
		local left = (workspace:GetAttribute("TotemUntil") or 0) - os.time()
		local parts = {}
		if left > 0 then
			table.insert(parts, "LUCK TOTEM 3x " .. Format.Time(left))
		end
		local bait = player:GetAttribute("Bait") or 0
		if bait > 0 then
			table.insert(parts, "Mega Bait x" .. bait)
		end
		banner.Text = table.concat(parts, "  •  ")
		task.wait(1)
	end
end)

---------------------------------------------------------------- reel minigame

local BAR_HEIGHT = 320
local game_ = UI.new("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -40, 0.5, 0),
	Size = UDim2.fromOffset(170, BAR_HEIGHT + 60),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = gui,
})
local bar = UI.new("Frame", { Size = UDim2.fromOffset(70, BAR_HEIGHT), BackgroundColor3 = Color3.fromRGB(20, 40, 70), Parent = game_ }, { UI.Corner(10), UI.Stroke(Color3.new(0, 0, 0), 3) })
local zone = UI.new("Frame", { Size = UDim2.new(1, -8, 0, 80), Position = UDim2.fromOffset(4, 0), BackgroundColor3 = Color3.fromRGB(90, 255, 120), BackgroundTransparency = 0.35, Parent = bar }, { UI.Corner(8) })
local fishIcon = UI.Label("🐟", { Size = UDim2.new(1, 0, 0, 30), AnchorPoint = Vector2.new(0, 0.5), Parent = bar })
local progressBack = UI.new("Frame", { Position = UDim2.fromOffset(84, 0), Size = UDim2.fromOffset(22, BAR_HEIGHT), BackgroundColor3 = Color3.fromRGB(40, 40, 40), Parent = game_ }, { UI.Corner(8) })
local progressFill = UI.new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.3), BackgroundColor3 = Color3.fromRGB(255, 220, 60), Parent = progressBack }, { UI.Corner(8) })
local rarityLabel = UI.Label("", { Position = UDim2.fromOffset(0, BAR_HEIGHT + 6), Size = UDim2.new(1, 0, 0, 30), Parent = game_ })
UI.Label("HOLD to reel!", { Position = UDim2.fromOffset(0, -34), Size = UDim2.new(1, 0, 0, 28), Parent = game_ })

local holding = false
UserInputService.InputBegan:Connect(function(input)
	local t = input.UserInputType
	if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.Space then
		holding = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	local t = input.UserInputType
	if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.Space then
		holding = false
	end
end)

local casting = false
local reeling = false

local function playMinigame(rarityName: string, difficulty: number, control: number): boolean
	reeling = true
	local rarity = Config.RarityByName[rarityName]
	rarityLabel.Text = rarityName .. "!"
	rarityLabel.TextColor3 = rarity.Color
	local zoneHeight = math.floor(BAR_HEIGHT * control)
	zone.Size = UDim2.new(1, -8, 0, zoneHeight)
	local zoneY, zoneVel = BAR_HEIGHT - zoneHeight, 0
	local fishY, fishTarget, nextMove = BAR_HEIGHT / 2, BAR_HEIGHT / 2, 0
	local progress = 0.3
	game_.Visible = true
	local result: boolean? = nil
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		dt = math.min(dt, 0.05)
		-- Player zone physics: hold to rise, release to fall.
		zoneVel += (if holding then -900 else 700) * dt
		zoneVel = math.clamp(zoneVel, -380, 380)
		zoneY = math.clamp(zoneY + zoneVel * dt, 0, BAR_HEIGHT - zoneHeight)
		if zoneY == 0 or zoneY == BAR_HEIGHT - zoneHeight then
			zoneVel *= -0.3
		end
		-- Fish darts to random targets; harder fish move more often and faster.
		nextMove -= dt
		if nextMove <= 0 then
			nextMove = (0.5 + math.random() * 1.2) / difficulty
			fishTarget = math.random(15, BAR_HEIGHT - 15)
		end
		fishY += (fishTarget - fishY) * math.min(1, dt * 2.2 * difficulty)
		zone.Position = UDim2.fromOffset(4, zoneY)
		fishIcon.Position = UDim2.fromOffset(0, fishY)
		local inside = fishY >= zoneY and fishY <= zoneY + zoneHeight
		zone.BackgroundColor3 = if inside then Color3.fromRGB(90, 255, 120) else Color3.fromRGB(255, 120, 90)
		progress += if inside then dt * 0.33 else -dt * 0.2 * difficulty
		progressFill.Size = UDim2.fromScale(1, math.clamp(progress, 0, 1))
		if progress >= 1 then
			result = true
		elseif progress <= 0 then
			result = false
		end
	end)
	while result == nil do
		task.wait()
	end
	conn:Disconnect()
	game_.Visible = false
	reeling = false
	return result :: boolean
end

---------------------------------------------------------------- casting

local autoOn = false
local lastTarget: Vector3? = nil

local function rodEquipped(): boolean
	return player.Character ~= nil and player.Character:FindFirstChild("Rod") ~= nil
end

local function cast(target: Vector3)
	if casting or reeling then
		return
	end
	casting = true
	local ok, msg = remotes.Cast:InvokeServer(target)
	if ok then
		lastTarget = target
		statusLabel.Text = "Waiting for a bite..."
	else
		casting = false
		statusLabel.Text = msg
	end
end

remotes:WaitForChild("Bite").OnClientEvent:Connect(function(rarityName, difficulty, control)
	statusLabel.Text = "BITE! Reel it in!"
	local success
	if autoOn and player:GetAttribute("Pass_AutoFish") then
		task.wait(Config.MinCatchSeconds + 0.5 + math.random())
		success = true
	else
		success = playMinigame(rarityName, difficulty, control)
	end
	remotes.Reel:FireServer(success)
	casting = false
	statusLabel.Text = if autoOn then "Auto fishing..." else "Click the water to cast!"
end)

local function hookTool(tool: Instance)
	if tool.Name ~= "Rod" or not tool:IsA("Tool") then
		return
	end
	tool.Activated:Connect(function()
		if reeling then
			return
		end
		mouse.TargetFilter = player.Character
		cast(mouse.Hit.Position)
	end)
	tool.Unequipped:Connect(function()
		if not reeling then
			casting = false
		end
	end)
end
local function hookCharacter(character: Model)
	casting = false
	character.ChildAdded:Connect(hookTool)
	for _, child in character:GetChildren() do
		hookTool(child)
	end
end
player.CharacterAdded:Connect(hookCharacter)
if player.Character then
	hookCharacter(player.Character)
end

-- Auto fish loop (pass): recasts at the last spot, or in front of you.
task.spawn(function()
	while true do
		task.wait(1)
		if autoOn and player:GetAttribute("Pass_AutoFish") and rodEquipped() and not casting and not reeling then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local target = lastTarget or (root and (root.Position + root.CFrame.LookVector * 25))
			if target then
				cast(target)
			end
		end
	end
end)

---------------------------------------------------------------- rods modal

local rodsFrame = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 520, 0.7, 0),
	BackgroundColor3 = Color3.fromRGB(20, 50, 80),
	Visible = false,
	Parent = gui,
}, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
UI.Label("RODS", { Size = UDim2.new(1, -80, 0, 50), Position = UDim2.fromOffset(16, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = rodsFrame })
UI.Button("X", Color3.fromRGB(230, 60, 60), { Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -58, 0, 8), Parent = rodsFrame }).Activated:Connect(function()
	rodsFrame.Visible = false
end)
local rodList = UI.new("ScrollingFrame", {
	Position = UDim2.fromOffset(12, 64),
	Size = UDim2.new(1, -24, 1, -76),
	BackgroundTransparency = 1,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ScrollBarThickness = 8,
	Parent = rodsFrame,
})
local rodLayout = Instance.new("UIListLayout")
rodLayout.Padding = UDim.new(0, 8)
rodLayout.SortOrder = Enum.SortOrder.LayoutOrder
rodLayout.Parent = rodList

local rodButtons = {}
for i, rod in Config.Rods do
	local row = UI.new("Frame", { Size = UDim2.new(1, -10, 0, 74), BackgroundColor3 = Color3.fromRGB(35, 70, 105), LayoutOrder = i, Parent = rodList }, { UI.Corner(12) })
	UI.Label(rod.Name, { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -150, 0, 32), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = rod.Color, Parent = row })
	UI.Label(string.format("Luck x%g  •  Speed x%g  •  Control %d%%", rod.Luck, rod.Speed, rod.Control * 100), { Position = UDim2.fromOffset(12, 38), Size = UDim2.new(1, -150, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, Parent = row })
	local b = UI.Button("", Color3.fromRGB(40, 180, 70), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(120, 52), Parent = row })
	b.Activated:Connect(function()
		local ok, msg = remotes.BuyRod:InvokeServer(rod.Id)
		if msg == "RobuxOnly" then
			buy("Product", "SigmaRod")
			return
		end
		toast(msg, if ok then Color3.fromRGB(120, 255, 120) else Color3.fromRGB(255, 90, 90))
	end)
	rodButtons[rod.Id] = { Button = b, Rod = rod }
end
local function refreshRods()
	local owned = {}
	for id in string.gmatch(player:GetAttribute("OwnedRods") or "", "[^,]+") do
		owned[id] = true
	end
	for id, entry in rodButtons do
		local b = entry.Button
		if player:GetAttribute("Rod") == id then
			b.Text = "EQUIPPED"
			b.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
		elseif owned[id] then
			b.Text = "EQUIP"
			b.BackgroundColor3 = Color3.fromRGB(40, 140, 230)
		else
			b.Text = if entry.Rod.Price < 0 then "R$ " .. Config.ProductInfo[4].Price else Format.Cash(entry.Rod.Price)
			b.BackgroundColor3 = Color3.fromRGB(40, 180, 70)
		end
	end
end
player:GetAttributeChangedSignal("OwnedRods"):Connect(refreshRods)
player:GetAttributeChangedSignal("Rod"):Connect(refreshRods)
refreshRods()

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Name == "RodShopPrompt" then
		shop.Visible = false
		rodsFrame.Visible = true
	end
end)

---------------------------------------------------------------- side bar

local side = ShopUI.SideBar(gui)
UI.Button("RODS", Color3.fromRGB(80, 160, 255), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	shop.Visible = false
	rodsFrame.Visible = not rodsFrame.Visible
end)
UI.Button("SELL", Color3.fromRGB(230, 170, 40), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	local ok, msg = remotes.Sell:InvokeServer()
	if msg == "NeedPass" then
		toast("Walk to the Fish Merchant, or get Sell Anywhere!", Color3.fromRGB(255, 200, 0))
		buy("Pass", "SellAnywhere")
		return
	end
	toast(msg, if ok then Color3.fromRGB(120, 255, 120) else Color3.fromRGB(255, 90, 90))
end)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	rodsFrame.Visible = false
	shop.Visible = not shop.Visible
end)
local autoButton = UI.Button("AUTO: OFF", Color3.fromRGB(80, 80, 110), { Size = UDim2.fromOffset(130, 52), Parent = side })
autoButton.Activated:Connect(function()
	if not player:GetAttribute("Pass_AutoFish") then
		buy("Pass", "AutoFish")
		return
	end
	autoOn = not autoOn
	autoButton.Text = if autoOn then "AUTO: ON" else "AUTO: OFF"
	autoButton.BackgroundColor3 = if autoOn then Color3.fromRGB(40, 180, 70) else Color3.fromRGB(80, 80, 110)
	if autoOn then
		toast("Equip your rod — it'll fish for you!", Color3.fromRGB(120, 255, 120))
	end
end)
