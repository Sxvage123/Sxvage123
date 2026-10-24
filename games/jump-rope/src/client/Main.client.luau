-- Brainrot Jump Rope client: jump counter, round state, revive, shop.
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
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(45, 25, 40))
ShopUI.VIPChatTag("VIP")

local top = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(380, 84), BackgroundColor3 = Color3.fromRGB(45, 25, 40), Parent = gui }, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local main = UI.Label("", { Size = UDim2.new(1, -10, 0, 50), Position = UDim2.fromOffset(5, 2), Parent = top })
local info = UI.Label("", { Size = UDim2.new(1, -10, 0, 26), Position = UDim2.fromOffset(5, 54), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = top })
local revive = UI.Button("REVIVE  R$ 25", Color3.fromRGB(40, 200, 80), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.62), Size = UDim2.fromOffset(320, 84), Visible = false, Parent = gui })
revive.Activated:Connect(function()
	buy("Product", "Revive")
end)
local side = ShopUI.SideBar(gui)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	shop.Visible = not shop.Visible
end)
UI.Button("TURBO ROPE", Color3.fromRGB(230, 60, 60), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	buy("Product", "SpeedUp")
end)

while true do
	local stage = workspace:GetAttribute("Stage") or "Lobby"
	main.Text = if stage == "Lobby" then "Next round in " .. (workspace:GetAttribute("TimeLeft") or 0) else "🪢 JUMP! " .. (player:GetAttribute("Jumps") or 0) .. " jumps"
	info.Text = (player:GetAttribute("Wins") or 0) .. " wins  •  best " .. (player:GetAttribute("BestJumps") or 0) .. "  •  " .. (player:GetAttribute("Coins") or 0) .. " coins"
	revive.Visible = stage == "Round" and not player:GetAttribute("InRound")
	task.wait(0.15)
end
