-- Brainrot RNG client: roll button + reveal animation, aura index, potions, shop.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
local ShopUI = require(ReplicatedStorage.Common.ShopUI)
local UI = require(ReplicatedStorage.Common.UI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui = UI.new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") }) :: ScreenGui
local toast = UI.CreateToaster(gui)
remotes:WaitForChild("Notify").OnClientEvent:Connect(toast)
local buy = ShopUI.Buyer(Config, toast)
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(40, 25, 70))
ShopUI.VIPChatTag("VIP")

---------------------------------------------------------------- HUD

local info = UI.Label("", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(560, 30),
	Parent = gui,
})
local luckLabel = UI.Label("", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 40),
	Size = UDim2.fromOffset(560, 26),
	TextColor3 = Color3.fromRGB(0, 255, 200),
	Parent = gui,
})

local function refresh()
	local rolls = player:GetAttribute("Rolls") or 0
	local untilLucky = Config.LuckyEvery - (rolls % Config.LuckyEvery)
	info.Text = string.format("Rolls: %s  •  Lucky roll in %d", Format.Abbreviate(rolls), untilLucky)
	local parts = { string.format("Luck x%g", math.floor((player:GetAttribute("Luck") or 1) * 100) / 100) }
	local potionLeft = (player:GetAttribute("PotionUntil") or 0) - os.time()
	if potionLeft > 0 then
		table.insert(parts, "Potion " .. Format.Time(potionLeft))
	end
	local serverLeft = (workspace:GetAttribute("ServerLuckUntil") or 0) - os.time()
	if serverLeft > 0 then
		table.insert(parts, "Server 2x " .. Format.Time(serverLeft))
	end
	if (player:GetAttribute("Heavenly") or 0) > 0 then
		table.insert(parts, "HEAVENLY READY")
	end
	luckLabel.Text = table.concat(parts, "  •  ")
end
player.AttributeChanged:Connect(refresh)
task.spawn(function()
	while true do
		refresh()
		task.wait(1)
	end
end)

---------------------------------------------------------------- reveal animation

local reveal = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromOffset(520, 150),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = gui,
})
local revealName = UI.Label("", { Size = UDim2.new(1, 0, 0, 90), Parent = reveal })
local revealOdds = UI.Label("", { Position = UDim2.fromOffset(0, 92), Size = UDim2.new(1, 0, 0, 44), TextColor3 = Color3.fromRGB(230, 230, 230), Parent = reveal })

local revealing = false
local function playReveal(id: string, lucky: boolean?, quick: boolean?)
	local aura = Config.AuraById[id]
	if not aura then
		return
	end
	revealing = true
	reveal.Visible = true
	local steps = if quick then 0 elseif aura.Chance >= 1000 then 14 else 7
	for i = 1, steps do
		local fake = Config.Auras[math.random(1, #Config.Auras)]
		revealName.Text = fake.Name
		revealName.TextColor3 = fake.Color
		revealOdds.Text = ""
		task.wait(0.04 + i * 0.012)
	end
	revealName.Text = aura.Name
	revealName.TextColor3 = aura.Color
	revealOdds.Text = "1 in " .. Format.Abbreviate(aura.Chance) .. (if lucky then "  (LUCKY ROLL)" else "")
	if aura.Chance >= 1000 then
		local flash = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = aura.Color, BackgroundTransparency = 0.2, ZIndex = 0, Parent = gui })
		TweenService:Create(flash, TweenInfo.new(1.2), { BackgroundTransparency = 1 }):Play()
		task.delay(1.3, flash.Destroy, flash)
	end
	task.wait(if quick then 0.4 elseif aura.Chance >= 1000 then 2 else 0.8)
	reveal.Visible = false
	revealing = false
end

---------------------------------------------------------------- roll button

local rollButton = UI.Button("ROLL", Color3.fromRGB(170, 0, 255), {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -24),
	Size = UDim2.fromOffset(220, 84),
	Parent = gui,
})
rollButton.Activated:Connect(function()
	if revealing then
		return
	end
	local id, lucky = remotes.Roll:InvokeServer()
	if id then
		playReveal(id, lucky)
	end
end)

local autoButton = UI.Button("AUTO: OFF", Color3.fromRGB(80, 80, 110), {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 180, 1, -30),
	Size = UDim2.fromOffset(130, 60),
	Parent = gui,
})
autoButton.Activated:Connect(function()
	if not player:GetAttribute("Pass_AutoRoll") then
		buy("Pass", "AutoRoll")
		return
	end
	remotes.ToggleAutoRoll:FireServer()
end)
player:GetAttributeChangedSignal("AutoRollOn"):Connect(function()
	local on = player:GetAttribute("AutoRollOn")
	autoButton.Text = if on then "AUTO: ON" else "AUTO: OFF"
	autoButton.BackgroundColor3 = if on then Color3.fromRGB(40, 180, 70) else Color3.fromRGB(80, 80, 110)
end)
remotes:WaitForChild("AutoRollResult").OnClientEvent:Connect(function(id, lucky)
	if not revealing then
		task.spawn(playReveal, id, lucky, Config.AuraById[id].Chance < 1000)
	end
end)

---------------------------------------------------------------- index / inventory

local index = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 520, 0.7, 0),
	BackgroundColor3 = Color3.fromRGB(35, 25, 60),
	Visible = false,
	Parent = gui,
}, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) })
UI.Label("AURA INDEX", { Size = UDim2.new(1, -80, 0, 50), Position = UDim2.fromOffset(16, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = index })
UI.Button("X", Color3.fromRGB(230, 60, 60), { Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -58, 0, 8), Parent = index }).Activated:Connect(function()
	index.Visible = false
end)
local indexList = UI.new("ScrollingFrame", {
	Position = UDim2.fromOffset(12, 64),
	Size = UDim2.new(1, -24, 1, -76),
	BackgroundTransparency = 1,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ScrollBarThickness = 8,
	Parent = index,
})
local indexLayout = Instance.new("UIListLayout")
indexLayout.Padding = UDim.new(0, 6)
indexLayout.SortOrder = Enum.SortOrder.LayoutOrder
indexLayout.Parent = indexList

local collected = {}
local function renderIndex()
	for _, c in indexList:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for i, aura in Config.RarestFirst do
		local count = collected[aura.Id]
		local row = UI.new("TextButton", {
			Text = "",
			LayoutOrder = i,
			Size = UDim2.new(1, -10, 0, 52),
			BackgroundColor3 = Color3.fromRGB(55, 45, 85),
			AutoButtonColor = count ~= nil,
			Parent = indexList,
		}, { UI.Corner(10), UI.Stroke(if player:GetAttribute("Equipped") == aura.Id then Color3.fromRGB(90, 255, 90) else Color3.new(0, 0, 0), 2) }) :: TextButton
		UI.Label(if count then aura.Name else "???", {
			Position = UDim2.fromOffset(12, 4),
			Size = UDim2.new(0.6, 0, 1, -8),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = if count then aura.Color else Color3.fromRGB(120, 120, 120),
			Parent = row,
		})
		UI.Label("1 in " .. Format.Abbreviate(aura.Chance) .. (if count then "  x" .. count else ""), {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 8),
			Size = UDim2.new(0.38, 0, 1, -16),
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = row,
		})
		row.Activated:Connect(function()
			if count and remotes.Equip:InvokeServer(aura.Id) then
				toast("Equipped " .. aura.Name, aura.Color)
				renderIndex()
			end
		end)
	end
end
remotes:WaitForChild("Inventory").OnClientEvent:Connect(function(c)
	collected = c
	if index.Visible then
		renderIndex()
	end
end)

local side = ShopUI.SideBar(gui)
UI.Button("AURAS", Color3.fromRGB(170, 0, 255), { Size = UDim2.fromOffset(130, 56), Parent = side }).Activated:Connect(function()
	shop.Visible = false
	index.Visible = not index.Visible
	if index.Visible then
		renderIndex()
	end
end)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 56), Parent = side }).Activated:Connect(function()
	index.Visible = false
	shop.Visible = not shop.Visible
end)
UI.Button("2x LUCK", Color3.fromRGB(0, 190, 170), { Size = UDim2.fromOffset(130, 56), Parent = side }).Activated:Connect(function()
	buy("Product", "LuckPotion")
end)
