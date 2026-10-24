-- Brainrot Tycoon client: cash HUD, shop, rebirth, golden hour banner.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
local shop = ShopUI.Create(gui, Config, buy)
ShopUI.VIPChatTag("VIP")

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(320, 64),
	BackgroundColor3 = Color3.fromRGB(30, 30, 40),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local cashLabel = UI.Label("$0", { Size = UDim2.new(1, -10, 1, -8), Position = UDim2.fromOffset(5, 4), TextColor3 = Color3.fromRGB(90, 255, 90), Parent = top })
local banner = UI.Label("", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 76), Size = UDim2.fromOffset(500, 30), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = gui })

local side = ShopUI.SideBar(gui)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 56), Parent = side }).Activated:Connect(function()
	shop.Visible = not shop.Visible
end)
local rebirthButton = UI.Button("REBIRTH", Color3.fromRGB(255, 170, 0), { Size = UDim2.fromOffset(130, 56), Parent = side })
rebirthButton.Activated:Connect(function()
	local ok, msg = remotes.Rebirth:InvokeServer()
	toast(msg, if ok then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(255, 90, 90))
end)
UI.Button("5x CASH", Color3.fromRGB(255, 200, 0), { Size = UDim2.fromOffset(130, 56), Parent = side }).Activated:Connect(function()
	buy("Product", "GoldenHour")
end)

local function refresh()
	cashLabel.Text = Format.Cash(player:GetAttribute("Cash") or 0)
	rebirthButton.BackgroundColor3 = if player:GetAttribute("CanRebirth") then Color3.fromRGB(255, 170, 0) else Color3.fromRGB(110, 100, 80)
end
player.AttributeChanged:Connect(refresh)
refresh()

task.spawn(function()
	while true do
		local remaining = (player:GetAttribute("GoldenUntil") or 0) - os.time()
		banner.Text = if remaining > 0 then "GOLDEN HOUR 5x CASH  " .. Format.Time(remaining) else ""
		task.wait(0.5)
	end
end)
