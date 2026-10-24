-- Eat the Brainrot World client: size HUD, EAT button (also click/tap), upgrades, rebirth, shop.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(40, 30, 30))
ShopUI.VIPChatTag("VIP")

local top = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(380, 80), BackgroundColor3 = Color3.fromRGB(35, 25, 25), BackgroundTransparency = 0.15, Parent = gui }, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local sizeLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 44), Position = UDim2.fromOffset(5, 2), TextColor3 = Color3.fromRGB(255, 150, 80), Parent = top })
local infoLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 28), Position = UDim2.fromOffset(5, 48), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = top })

local eat = UI.Button("😋 EAT", Color3.fromRGB(230, 70, 60), { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20), Size = UDim2.fromOffset(150, 150), Parent = gui })
local holding = false
eat.MouseButton1Down:Connect(function()
	holding = true
end)
eat.MouseButton1Up:Connect(function()
	holding = false
end)
eat.Activated:Connect(function()
	remotes.Eat:FireServer()
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.E) then
		remotes.Eat:FireServer()
	end
end)
task.spawn(function()
	while true do
		if holding then
			remotes.Eat:FireServer()
		end
		task.wait(Config.BiteCooldown)
	end
end)

local side = ShopUI.SideBar(gui)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(140, 46), Parent = side }).Activated:Connect(function()
	shop.Visible = not shop.Visible
end)
local upButtons = {}
for _, u in Config.Upgrades do
	local b = UI.Button(u.Name, Color3.fromRGB(80, 140, 255), { Size = UDim2.fromOffset(140, 46), Parent = side })
	b.Activated:Connect(function()
		remotes.Upgrade:InvokeServer(u.Id)
	end)
	upButtons[u.Id] = b
end
local rebirth = UI.Button("REBIRTH", Color3.fromRGB(200, 80, 255), { Size = UDim2.fromOffset(140, 46), Parent = side })
rebirth.Activated:Connect(function()
	remotes.Rebirth:InvokeServer()
end)
UI.Button("SHRINK RAY", Color3.fromRGB(80, 200, 255), { Size = UDim2.fromOffset(140, 46), Parent = side }).Activated:Connect(function()
	buy("Product", "ShrinkRay")
end)

while true do
	local size = player:GetAttribute("Size") or 0
	sizeLabel.Text = "📏 Size " .. Format.Abbreviate(math.floor(size))
	infoLabel.Text = "🪙 " .. Format.Abbreviate(player:GetAttribute("Coins") or 0) .. "  •  🔁 " .. (player:GetAttribute("Rebirths") or 0)
	for _, u in Config.Upgrades do
		local lv = player:GetAttribute("Lv_" .. u.Id) or 0
		upButtons[u.Id].Text = if lv >= u.Max then u.Name .. " MAX" else u.Name .. " " .. Format.Abbreviate(Config.UpgradeCost(u, lv))
	end
	rebirth.Text = "REBIRTH @" .. Format.Abbreviate(Config.RebirthCost(player:GetAttribute("Rebirths") or 0))
	task.wait(0.3)
end
