-- Brainrot Ball client: parry (click/F/button), dash, targeted warning, crates, swords, shop.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
local ShopUI = require(ReplicatedStorage.Common.ShopUI)
local UI = require(ReplicatedStorage.Common.UI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local ball = workspace:WaitForChild("World"):WaitForChild("Ball") :: BasePart

local gui = UI.new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") }) :: ScreenGui
local toast = UI.CreateToaster(gui)
remotes:WaitForChild("Notify").OnClientEvent:Connect(toast)
local buy = ShopUI.Buyer(Config, toast)
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(50, 25, 35))
ShopUI.VIPChatTag("VIP")

---------------------------------------------------------------- HUD

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(360, 76),
	BackgroundColor3 = Color3.fromRGB(30, 15, 20),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local stateLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 40), Position = UDim2.fromOffset(5, 2), Parent = top })
local coinsLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 26), Position = UDim2.fromOffset(5, 44), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = top })
local targeted = UI.Label("⚠ TARGETED — PARRY! ⚠", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.3),
	Size = UDim2.fromOffset(520, 56),
	TextColor3 = Color3.fromRGB(255, 50, 50),
	Visible = false,
	Parent = gui,
})
local respawnButton = UI.Button("SECOND CHANCE  R$ 29", Color3.fromRGB(40, 200, 80), {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.62),
	Size = UDim2.fromOffset(340, 80),
	Visible = false,
	Parent = gui,
})
respawnButton.Activated:Connect(function()
	buy("Product", "Respawn")
end)

player.AttributeChanged:Connect(function()
	coinsLabel.Text = Format.Abbreviate(player:GetAttribute("Coins") or 0) .. " coins  •  " .. (player:GetAttribute("Wins") or 0) .. " wins"
end)
coinsLabel.Text = "0 coins"

task.spawn(function()
	while true do
		local roundState = workspace:GetAttribute("RoundState")
		if roundState == "Playing" then
			stateLabel.Text = (workspace:GetAttribute("AliveCount") or 0) .. " players alive"
		elseif roundState == "Intermission" then
			stateLabel.Text = "Next round in " .. (workspace:GetAttribute("TimeLeft") or 0)
		elseif roundState == "Waiting" then
			stateLabel.Text = "Waiting for players..."
		else
			stateLabel.Text = "Round over!"
		end
		local isTarget = ball:GetAttribute("TargetId") == player.UserId and player:GetAttribute("Alive") == true
		targeted.Visible = isTarget
		if isTarget then
			targeted.TextTransparency = (math.sin(os.clock() * 20) + 1) * 0.25
		end
		respawnButton.Visible = roundState == "Playing" and not player:GetAttribute("Alive")
		task.wait(0.05)
	end
end)

---------------------------------------------------------------- parry + dash

local lastParry = 0
local function parry()
	local now = os.clock()
	if now - lastParry < 0.15 then
		return
	end
	lastParry = now
	local cam = workspace.CurrentCamera
	remotes.Parry:FireServer(cam and cam.CFrame.LookVector or nil)
end

local lastDash = -100
local function dash()
	local cooldown = if player:GetAttribute("Pass_QuickDash") then 3 else Config.DashCooldown
	if os.clock() - lastDash < cooldown then
		toast("Dash ready in " .. math.ceil(cooldown - (os.clock() - lastDash)) .. "s", Color3.fromRGB(200, 200, 200))
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		lastDash = os.clock()
		root.AssemblyLinearVelocity = root.CFrame.LookVector * 110 + Vector3.new(0, 12, 0)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F or input.UserInputType == Enum.UserInputType.MouseButton1 then
		parry()
	elseif input.KeyCode == Enum.KeyCode.Q then
		dash()
	end
end)

local parryButton = UI.Button("PARRY", Color3.fromRGB(230, 50, 50), {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -20, 1, -130),
	Size = UDim2.fromOffset(120, 120),
	Parent = gui,
})
parryButton.Activated:Connect(parry)
local dashButton = UI.Button("DASH", Color3.fromRGB(60, 120, 255), {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -150, 1, -140),
	Size = UDim2.fromOffset(90, 90),
	Parent = gui,
})
dashButton.Activated:Connect(dash)
parryButton.Visible = UserInputService.TouchEnabled
dashButton.Visible = UserInputService.TouchEnabled

remotes:WaitForChild("ParryFx").OnClientEvent:Connect(function(position: Vector3)
	local ring = Instance.new("Part")
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Shape = Enum.PartType.Ball
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 255, 255)
	ring.Transparency = 0.3
	ring.Size = Vector3.one * 2
	ring.Position = position
	ring.Parent = workspace
	TweenService:Create(ring, TweenInfo.new(0.3), { Size = Vector3.one * 12, Transparency = 1 }):Play()
	Debris:AddItem(ring, 0.35)
end)

---------------------------------------------------------------- swords + crates

local swordsFrame = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 520, 0.7, 0),
	BackgroundColor3 = Color3.fromRGB(45, 25, 35),
	Visible = false,
	Parent = gui,
}, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
UI.Label("SWORDS", { Size = UDim2.new(1, -80, 0, 50), Position = UDim2.fromOffset(16, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = swordsFrame })
UI.Button("X", Color3.fromRGB(230, 60, 60), { Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -58, 0, 8), Parent = swordsFrame }).Activated:Connect(function()
	swordsFrame.Visible = false
end)
local crateButton = UI.Button("OPEN CRATE (" .. Config.CrateCost .. " coins)", Color3.fromRGB(255, 170, 0), { Position = UDim2.fromOffset(16, 62), Size = UDim2.new(1, -32, 0, 54), Parent = swordsFrame })
local oddsParts = {}
for _, r in Config.Rarities do
	table.insert(oddsParts, r.Name .. " " .. r.Weight .. "%")
end
UI.Label(table.concat(oddsParts, " • "), { Position = UDim2.fromOffset(16, 120), Size = UDim2.new(1, -32, 0, 22), Font = Enum.Font.GothamMedium, Parent = swordsFrame })
local swordList = UI.new("ScrollingFrame", {
	Position = UDim2.fromOffset(12, 150),
	Size = UDim2.new(1, -24, 1, -162),
	BackgroundTransparency = 1,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ScrollBarThickness = 8,
	Parent = swordsFrame,
})
local swordLayout = Instance.new("UIListLayout")
swordLayout.Padding = UDim.new(0, 6)
swordLayout.SortOrder = Enum.SortOrder.LayoutOrder
swordLayout.Parent = swordList

local function renderSwords()
	for _, c in swordList:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local owned = {}
	for id in string.gmatch(player:GetAttribute("OwnedSwords") or "", "[^,]+") do
		owned[id] = true
	end
	for i, sword in Config.Swords do
		local has = owned[sword.Id]
		local row = UI.new("Frame", { LayoutOrder = -i, Size = UDim2.new(1, -10, 0, 56), BackgroundColor3 = Color3.fromRGB(65, 40, 55), Parent = swordList }, { UI.Corner(10) })
		UI.Label(if has then sword.Name else "??? (" .. sword.Rarity .. ")", { Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -150, 1, -8), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Config.RarityColor[sword.Rarity], Parent = row })
		if has then
			local equipped = player:GetAttribute("Sword") == sword.Id
			local b = UI.Button(if equipped then "EQUIPPED" else "EQUIP", if equipped then Color3.fromRGB(90, 90, 90) else Color3.fromRGB(40, 180, 70), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(120, 44), Parent = row })
			b.Activated:Connect(function()
				remotes.EquipSword:InvokeServer(sword.Id)
			end)
		end
	end
end
player:GetAttributeChangedSignal("OwnedSwords"):Connect(function()
	if swordsFrame.Visible then
		renderSwords()
	end
end)
player:GetAttributeChangedSignal("Sword"):Connect(function()
	if swordsFrame.Visible then
		renderSwords()
	end
end)

crateButton.Activated:Connect(function()
	local ok, result, duplicate = remotes.OpenCrate:InvokeServer()
	if not ok then
		toast(result, Color3.fromRGB(255, 90, 90))
		buy("Product", "CoinsSmall")
		return
	end
	local sword = Config.SwordById[result]
	toast((if duplicate then "Duplicate (+25% refund): " else "NEW SWORD: ") .. sword.Name .. " (" .. sword.Rarity .. ")", Config.RarityColor[sword.Rarity])
end)

local side = ShopUI.SideBar(gui)
UI.Button("SWORDS", Color3.fromRGB(255, 120, 40), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	shop.Visible = false
	swordsFrame.Visible = not swordsFrame.Visible
	if swordsFrame.Visible then
		renderSwords()
	end
end)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	swordsFrame.Visible = false
	shop.Visible = not shop.Visible
end)
UI.Label("Click / F = Parry\nQ = Dash", { Size = UDim2.fromOffset(130, 50), Parent = side })
