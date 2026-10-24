-- Guess the Brainrot client: big figure viewport, 4 answer buttons, timer, hint/skip, shop.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ModelView = require(ReplicatedStorage.Common.ModelView)
local ShopUI = require(ReplicatedStorage.Common.ShopUI)
local UI = require(ReplicatedStorage.Common.UI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gui = UI.new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") }) :: ScreenGui
local toast = UI.CreateToaster(gui)
remotes:WaitForChild("Notify").OnClientEvent:Connect(toast)
local buy = ShopUI.Buyer(Config, toast)
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(40, 30, 70))
ShopUI.VIPChatTag("VIP")

local card = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(520, 470), BackgroundColor3 = Color3.fromRGB(40, 30, 70), Parent = gui }, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
UI.Label("WHO IS THIS BRAINROT?", { Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 6), Parent = card })
local timer = UI.Label("", { Size = UDim2.fromOffset(80, 40), Position = UDim2.new(1, -90, 0, 6), TextColor3 = Color3.fromRGB(255, 200, 80), Parent = card })
local stats = UI.Label("", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(420, 30), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = gui })
local holder = UI.new("Frame", { Size = UDim2.new(1, -20, 0, 220), Position = UDim2.fromOffset(10, 50), BackgroundColor3 = Color3.fromRGB(25, 20, 45), Parent = card }, { UI.Corner(12) })
local buttons: { TextButton } = {}
for i = 1, 4 do
	local b = UI.Button("", Color3.fromRGB(80, 120, 255), { Size = UDim2.new(0.5, -15, 0, 80), Position = UDim2.new(((i - 1) % 2) * 0.5, 10, 0, 282 + ((i - 1) // 2) * 90), Parent = card })
	b.Activated:Connect(function()
		if b.Text ~= "" and b.AutoButtonColor then
			remotes.Answer:FireServer(b.Text)
		end
	end)
	buttons[i] = b
end

local deadline = 0
remotes:WaitForChild("Question").OnClientEvent:Connect(function(id, choices, seconds, removed)
	for _, c in holder:GetChildren() do
		if c:IsA("ViewportFrame") then
			c:Destroy()
		end
	end
	local view = ModelView.new(id, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	if view then
		view.Parent = holder
	end
	for i, b in buttons do
		b.Text = choices[i] or ""
		local gone = table.find(removed, choices[i]) ~= nil
		b.AutoButtonColor = not gone
		b.BackgroundColor3 = if gone then Color3.fromRGB(60, 55, 70) else Color3.fromRGB(80, 120, 255)
	end
	deadline = os.clock() + seconds
end)

local side = ShopUI.SideBar(gui)
UI.Button("50/50", Color3.fromRGB(255, 160, 40), { Size = UDim2.fromOffset(120, 48), Parent = side }).Activated:Connect(function()
	buy("Product", "Hint")
end)
UI.Button("SKIP", Color3.fromRGB(230, 70, 120), { Size = UDim2.fromOffset(120, 48), Parent = side }).Activated:Connect(function()
	buy("Product", "Skip")
end)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(120, 48), Parent = side }).Activated:Connect(function()
	shop.Visible = not shop.Visible
end)

while true do
	timer.Text = "⏱ " .. math.max(0, math.ceil(deadline - os.clock()))
	stats.Text = "✅ " .. (player:GetAttribute("Correct") or 0) .. "   🔥 best " .. (player:GetAttribute("BestStreak") or 0) .. "   🪙 " .. (player:GetAttribute("Coins") or 0)
	task.wait(0.2)
end
