-- Brainrot Color Block client: called colour banner, timer, Color Sense preview, revive, shop.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ShopUI = require(ReplicatedStorage.Common.ShopUI)
local UI = require(ReplicatedStorage.Common.UI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gui = UI.new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") }) :: ScreenGui
local toast = UI.CreateToaster(gui)
remotes:WaitForChild("Notify").OnClientEvent:Connect(toast)
local buy = ShopUI.Buyer(Config, toast)
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(30, 25, 45))
ShopUI.VIPChatTag("VIP")

local banner = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(420, 90), BackgroundColor3 = Color3.fromRGB(30, 25, 45), Parent = gui }, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) }) :: Frame
local calledLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 56), Position = UDim2.fromOffset(5, 2), Parent = banner })
local infoLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 26), Position = UDim2.fromOffset(5, 60), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = banner })
local preview = UI.Label("", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 104), Size = UDim2.fromOffset(400, 30), TextColor3 = Color3.fromRGB(180, 220, 255), Parent = gui })
remotes:WaitForChild("Preview").OnClientEvent:Connect(function(name)
	preview.Text = "🔮 Next: " .. name
	task.delay(2, function()
		preview.Text = ""
	end)
end)
local revive = UI.Button("REVIVE  R$ 25", Color3.fromRGB(40, 200, 80), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.62), Size = UDim2.fromOffset(320, 84), Visible = false, Parent = gui })
revive.Activated:Connect(function()
	buy("Product", "Revive")
end)
local side = ShopUI.SideBar(gui)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	shop.Visible = not shop.Visible
end)
UI.Button("SLOW MODE", Color3.fromRGB(80, 140, 255), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	buy("Product", "ExtraTime")
end)

while true do
	local stage = workspace:GetAttribute("Stage") or "Lobby"
	local called = workspace:GetAttribute("Called")
	local t = workspace:GetAttribute("TimeLeft") or 0
	local color = Color3.new(1, 1, 1)
	for _, c in Config.Colors do
		if c.Name == called then
			color = c.Color
		end
	end
	calledLabel.Text = if stage == "Lobby" then "Next round in " .. t elseif called then "GO TO " .. called .. "!  " .. t else "Get ready..."
	calledLabel.TextColor3 = color
	banner.BackgroundColor3 = if called and stage ~= "Lobby" then color:Lerp(Color3.new(0, 0, 0), 0.7) else Color3.fromRGB(30, 25, 45)
	infoLabel.Text = (player:GetAttribute("Wins") or 0) .. " wins  •  " .. (player:GetAttribute("Coins") or 0) .. " coins"
	revive.Visible = stage == "Round" and not player:GetAttribute("InRound")
	task.wait(0.15)
end
