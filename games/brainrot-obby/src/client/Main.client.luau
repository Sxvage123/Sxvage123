-- Escape the Brainrot Obby client: stage HUD, big skip button, coils, stage selector, shop.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Config = require(ReplicatedStorage.Shared.Config)
local UI = require(ReplicatedStorage.Common.UI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local testPurchase = ReplicatedStorage:WaitForChild("StudioTestPurchase")

local gui = UI.new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") }) :: ScreenGui
local toast = UI.CreateToaster(gui)
remotes:WaitForChild("Notify").OnClientEvent:Connect(toast)

local function buy(kind: string, key: string)
	local id = if kind == "Pass" then Config.Passes[key] else Config.Products[key]
	if id > 0 then
		if kind == "Pass" then
			MarketplaceService:PromptGamePassPurchase(player, id)
		else
			MarketplaceService:PromptProductPurchase(player, id)
		end
	elseif RunService:IsStudio() then
		testPurchase:FireServer(kind, key)
		toast("[Studio test] " .. key, Color3.fromRGB(255, 215, 0))
	else
		toast("Coming soon!", Color3.fromRGB(255, 90, 90))
	end
end

-- Stage header with back/forward arrows.
local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(380, 70),
	BackgroundColor3 = Color3.fromRGB(30, 30, 40),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local stageLabel = UI.Label("Stage 1", { Position = UDim2.fromOffset(70, 4), Size = UDim2.new(1, -140, 0, 40), Parent = top })
local winsLabel = UI.Label("0 Wins", { Position = UDim2.fromOffset(70, 44), Size = UDim2.new(1, -140, 0, 22), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = top })
local back = UI.Button("<", Color3.fromRGB(80, 80, 110), { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(54, 54), Parent = top })
local forward = UI.Button(">", Color3.fromRGB(80, 80, 110), { Position = UDim2.new(1, -62, 0, 8), Size = UDim2.fromOffset(54, 54), Parent = top })
back.Activated:Connect(function()
	remotes.SelectStage:FireServer((player:GetAttribute("Stage") or 1) - 1)
end)
forward.Activated:Connect(function()
	remotes.SelectStage:FireServer((player:GetAttribute("Stage") or 1) + 1)
end)

-- Progress bar
local barBack = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 82),
	Size = UDim2.fromOffset(380, 14),
	BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	Parent = gui,
}, { UI.Corner(7) })
local barFill = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(90, 255, 90), Parent = barBack }, { UI.Corner(7) })

-- Skip button (main revenue driver): bottom right, pulses.
local skipButton = UI.Button("SKIP STAGE\nR$ 15", Color3.fromRGB(255, 60, 60), {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -110),
	Size = UDim2.fromOffset(170, 80),
	Parent = gui,
})
skipButton.Activated:Connect(function()
	if (player:GetAttribute("FreeSkips") or 0) > 0 then
		remotes.FreeSkip:FireServer()
	else
		buy("Product", "SkipStage")
	end
end)

local function refresh()
	local stage = player:GetAttribute("Stage") or 1
	local maxStage = player:GetAttribute("MaxStage") or 1
	stageLabel.Text = if stage > Config.StageCount then "FINISHED!" else "Stage " .. stage .. " / " .. Config.StageCount
	winsLabel.Text = (player:GetAttribute("Wins") or 0) .. " Wins  •  Best " .. maxStage
	barFill.Size = UDim2.fromScale(math.clamp((stage - 1) / Config.StageCount, 0, 1), 1)
	local free = player:GetAttribute("FreeSkips") or 0
	skipButton.Text = if free > 0 then "FREE SKIP\n(" .. free .. " left)" else "SKIP STAGE\nR$ 15"
	back.Visible = stage > 1
	forward.Visible = stage < maxStage
end
player.AttributeChanged:Connect(refresh)
refresh()

task.spawn(function()
	local t = 0
	while true do
		t += 0.05
		local s = 1 + math.sin(t * 4) * 0.04
		skipButton.Size = UDim2.fromOffset(170 * s, 80 * s)
		task.wait(0.05)
	end
end)

-- Shop + coil toggles on the left.
local side = UI.new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(130, 260), BackgroundTransparency = 1, Parent = gui })
local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 10)
sideLayout.Parent = side

local shop = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 520, 0.7, 0),
	BackgroundColor3 = Color3.fromRGB(40, 40, 60),
	Visible = false,
	Parent = gui,
}, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
UI.Label("SHOP", { Size = UDim2.new(1, -80, 0, 50), Position = UDim2.fromOffset(16, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = shop })
UI.Button("X", Color3.fromRGB(230, 60, 60), { Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -58, 0, 8), Parent = shop }).Activated:Connect(function()
	shop.Visible = false
end)
local list = UI.new("ScrollingFrame", {
	Position = UDim2.fromOffset(12, 64),
	Size = UDim2.new(1, -24, 1, -76),
	BackgroundTransparency = 1,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ScrollBarThickness = 8,
	Parent = shop,
})
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = list
local order = 0
local function item(info, kind)
	order += 1
	local row = UI.new("Frame", { Size = UDim2.new(1, -10, 0, 74), BackgroundColor3 = Color3.fromRGB(60, 60, 85), LayoutOrder = order, Parent = list }, { UI.Corner(12) })
	UI.Label(info.Name, { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -150, 0, 32), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
	UI.Label(info.Description, { Position = UDim2.fromOffset(12, 38), Size = UDim2.new(1, -150, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(200, 200, 220), Parent = row })
	local b = UI.Button("R$ " .. info.Price, if kind == "Pass" then Color3.fromRGB(40, 180, 70) else Color3.fromRGB(40, 140, 230), {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(120, 52),
		Parent = row,
	})
	if kind == "Pass" then
		local function owned()
			if player:GetAttribute("Pass_" .. info.Key) then
				b.Text = "OWNED"
				b.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
			end
		end
		player:GetAttributeChangedSignal("Pass_" .. info.Key):Connect(owned)
		owned()
	end
	b.Activated:Connect(function()
		if kind == "Pass" and player:GetAttribute("Pass_" .. info.Key) then
			return
		end
		buy(kind, info.Key)
	end)
end
for _, info in Config.ProductInfo do
	item(info, "Product")
end
for _, info in Config.PassInfo do
	item(info, "Pass")
end

UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 56), Parent = side }).Activated:Connect(function()
	shop.Visible = not shop.Visible
end)

local function coilButton(label: string, passKey: string, attr: string, remoteName: string)
	local b = UI.Button(label, Color3.fromRGB(60, 120, 255), { Size = UDim2.fromOffset(130, 56), Parent = side })
	local function refreshCoil()
		local owned = player:GetAttribute("Pass_" .. passKey)
		local on = player:GetAttribute(attr)
		b.Text = if owned then label .. (if on then ": ON" else ": OFF") else label .. " 🔒"
	end
	player.AttributeChanged:Connect(refreshCoil)
	refreshCoil()
	b.Activated:Connect(function()
		if player:GetAttribute("Pass_" .. passKey) then
			remotes.ToggleCoil:FireServer(remoteName)
		else
			buy("Pass", passKey)
		end
	end)
end
coilButton("Speed", "SpeedCoil", "SpeedOn", "Speed")
coilButton("Jump", "GravityCoil", "GravityOn", "Gravity")

TextChatService.OnIncomingMessage = function(message)
	local props = Instance.new("TextChatMessageProperties")
	local source = message.TextSource
	local speaker = source and Players:GetPlayerByUserId(source.UserId)
	if speaker and speaker:GetAttribute("Pass_VIP") then
		props.PrefixText = "<font color='#FFD700'>[VIP]</font> " .. message.PrefixText
	end
	return props
end
