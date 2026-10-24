-- Brainrot Lifting Simulator client: lift button, weights shop, arm-wrestling minigame, rebirth, shop.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

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
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(45, 35, 60))
ShopUI.VIPChatTag("VIP")

---------------------------------------------------------------- HUD

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(380, 80),
	BackgroundColor3 = Color3.fromRGB(35, 30, 50),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local strengthLabel = UI.Label("💪 0", { Size = UDim2.new(1, -10, 0, 44), Position = UDim2.fromOffset(5, 2), TextColor3 = Color3.fromRGB(255, 170, 80), Parent = top })
local winsLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 26), Position = UDim2.fromOffset(5, 48), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = top })
local banner = UI.Label("", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 92), Size = UDim2.fromOffset(500, 28), TextColor3 = Color3.fromRGB(0, 255, 200), Parent = gui })

local function refresh()
	strengthLabel.Text = "💪 " .. Format.Abbreviate(player:GetAttribute("Strength") or 0)
	winsLabel.Text = "🏆 " .. Format.Abbreviate(player:GetAttribute("Wins") or 0) .. " wins  •  +" .. Format.Abbreviate(player:GetAttribute("LiftPower") or 1) .. " per lift  •  Rebirths " .. (player:GetAttribute("Rebirths") or 0)
end
player.AttributeChanged:Connect(refresh)
refresh()
task.spawn(function()
	while true do
		local left = (player:GetAttribute("ProteinUntil") or 0) - os.time()
		banner.Text = if left > 0 then "3x PROTEIN " .. Format.Time(left) else ""
		task.wait(1)
	end
end)

---------------------------------------------------------------- lifting

local lastLift = 0
local function lift()
	if player:GetAttribute("Wrestling") then
		return
	end
	local character = player.Character
	local tool = character and character:FindFirstChild("Dumbbell")
	if not tool then
		local backpackTool = player.Backpack:FindFirstChild("Dumbbell")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if backpackTool and humanoid then
			humanoid:EquipTool(backpackTool)
		end
		return
	end
	local now = os.clock()
	if now - lastLift < 1 / Config.MaxLiftsPerSecond then
		return
	end
	lastLift = now
	remotes.Lift:FireServer()
	local pop = UI.Label("+" .. Format.Abbreviate(player:GetAttribute("LiftPower") or 1) .. " 💪", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, math.random(-100, 100), 1, -150),
		Size = UDim2.fromOffset(160, 36),
		TextColor3 = Color3.fromRGB(255, 170, 80),
		Parent = gui,
	})
	TweenService:Create(pop, TweenInfo.new(0.7), { Position = pop.Position - UDim2.fromOffset(0, 100), TextTransparency = 1 }):Play()
	task.delay(0.7, pop.Destroy, pop)
end

local liftButton = UI.Button("LIFT!", Color3.fromRGB(255, 130, 40), {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -20),
	Size = UDim2.fromOffset(200, 80),
	Parent = gui,
})
liftButton.Activated:Connect(lift)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
		if player:GetAttribute("Wrestling") then
			remotes.WrestleTap:FireServer()
		else
			lift()
		end
	end
end)

---------------------------------------------------------------- arm wrestling

local wrestle = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromOffset(460, 190),
	BackgroundColor3 = Color3.fromRGB(30, 25, 40),
	BackgroundTransparency = 0.1,
	Visible = false,
	Parent = gui,
}, { UI.Corner(16), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
local wrestleTitle = UI.Label("", { Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 36), Parent = wrestle })
local barBack = UI.new("Frame", { Position = UDim2.fromOffset(20, 52), Size = UDim2.new(1, -40, 0, 34), BackgroundColor3 = Color3.fromRGB(200, 60, 60), Parent = wrestle }, { UI.Corner(10) })
local barFill = UI.new("Frame", { Size = UDim2.fromScale(0.5, 1), BackgroundColor3 = Color3.fromRGB(80, 220, 90), Parent = barBack }, { UI.Corner(10) })
local tapButton = UI.Button("TAP TAP TAP!", Color3.fromRGB(255, 170, 0), { Position = UDim2.fromOffset(20, 100), Size = UDim2.new(1, -40, 0, 76), Parent = wrestle })
tapButton.Activated:Connect(function()
	remotes.WrestleTap:FireServer()
	tapButton.Size = UDim2.new(1, -50, 0, 70)
	TweenService:Create(tapButton, TweenInfo.new(0.08), { Size = UDim2.new(1, -40, 0, 76) }):Play()
end)

player:GetAttributeChangedSignal("WrestleProgress"):Connect(function()
	barFill.Size = UDim2.fromScale(math.clamp(player:GetAttribute("WrestleProgress") or 0.5, 0, 1), 1)
end)
player:GetAttributeChangedSignal("Wrestling"):Connect(function()
	local index = player:GetAttribute("Wrestling")
	wrestle.Visible = index ~= nil
	if index then
		wrestleTitle.Text = "VS " .. Config.Bosses[index].Name
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local index = prompt:GetAttribute("BossIndex")
	if not index then
		return
	end
	local ok, result = remotes.Wrestle:InvokeServer(index)
	if not ok and result ~= "Busy" then
		toast(result, Color3.fromRGB(255, 90, 90))
	end
end)

---------------------------------------------------------------- weights + rebirth

local weights = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 520, 0.7, 0),
	BackgroundColor3 = Color3.fromRGB(45, 35, 60),
	Visible = false,
	Parent = gui,
}, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
UI.Label("WEIGHTS", { Size = UDim2.new(1, -80, 0, 50), Position = UDim2.fromOffset(16, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = weights })
UI.Button("X", Color3.fromRGB(230, 60, 60), { Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -58, 0, 8), Parent = weights }).Activated:Connect(function()
	weights.Visible = false
end)
local list = UI.new("ScrollingFrame", { Position = UDim2.fromOffset(12, 64), Size = UDim2.new(1, -24, 1, -76), BackgroundTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 8, Parent = weights })
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list
local weightButtons = {}
for i, w in Config.Weights do
	local row = UI.new("Frame", { LayoutOrder = i, Size = UDim2.new(1, -10, 0, 70), BackgroundColor3 = Color3.fromRGB(65, 55, 85), Parent = list }, { UI.Corner(12) })
	UI.Label(w.Name, { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -150, 0, 32), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = w.Color, Parent = row })
	UI.Label("+" .. w.Power .. " per lift", { Position = UDim2.fromOffset(12, 38), Size = UDim2.new(1, -150, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, Parent = row })
	local b = UI.Button("", Color3.fromRGB(40, 180, 70), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(120, 50), Parent = row })
	b.Activated:Connect(function()
		local ok, msg = remotes.BuyWeight:InvokeServer(w.Id)
		toast(msg, if ok then Color3.fromRGB(120, 255, 120) else Color3.fromRGB(255, 90, 90))
	end)
	weightButtons[w.Id] = { Button = b, Weight = w }
end
local function refreshWeights()
	local owned = {}
	for id in string.gmatch(player:GetAttribute("OwnedWeights") or "", "[^,]+") do
		owned[id] = true
	end
	for id, entry in weightButtons do
		local b = entry.Button
		if player:GetAttribute("Weight") == id then
			b.Text = "EQUIPPED"
			b.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
		elseif owned[id] then
			b.Text = "EQUIP"
			b.BackgroundColor3 = Color3.fromRGB(40, 140, 230)
		else
			b.Text = "🏆 " .. Format.Abbreviate(entry.Weight.Cost)
			b.BackgroundColor3 = Color3.fromRGB(40, 180, 70)
		end
	end
end
player:GetAttributeChangedSignal("OwnedWeights"):Connect(refreshWeights)
player:GetAttributeChangedSignal("Weight"):Connect(refreshWeights)
refreshWeights()

local side = ShopUI.SideBar(gui)
UI.Button("WEIGHTS", Color3.fromRGB(255, 130, 40), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	shop.Visible = false
	weights.Visible = not weights.Visible
end)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	weights.Visible = false
	shop.Visible = not shop.Visible
end)
UI.Button("REBIRTH", Color3.fromRGB(255, 200, 0), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	local ok, msg = remotes.Rebirth:InvokeServer()
	toast(msg, if ok then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(255, 90, 90))
end)
UI.Button("3x PROTEIN", Color3.fromRGB(0, 190, 170), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	buy("Product", "Protein")
end)
