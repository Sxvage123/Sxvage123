-- Survive Tung Tung Sahur client: round HUD, revive button, coin shop, troll buttons, Robux shop.
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
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(50, 30, 30))
ShopUI.VIPChatTag("VIP")

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(380, 80),
	BackgroundColor3 = Color3.fromRGB(30, 15, 15),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local stateLabel = UI.Label("Intermission", { Size = UDim2.new(1, -10, 0, 44), Position = UDim2.fromOffset(5, 2), Parent = top })
local statsLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 26), Position = UDim2.fromOffset(5, 48), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = top })

local reviveButton = UI.Button("REVIVE  R$ 25", Color3.fromRGB(40, 200, 80), {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.62),
	Size = UDim2.fromOffset(300, 90),
	Visible = false,
	Parent = gui,
})
reviveButton.Activated:Connect(function()
	buy("Product", "Revive")
end)

local side = ShopUI.SideBar(gui)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	shop.Visible = not shop.Visible
end)
local shieldButton = UI.Button("Shield (" .. Config.ShieldCost .. "c)", Color3.fromRGB(60, 120, 255), { Size = UDim2.fromOffset(130, 52), Parent = side })
shieldButton.Activated:Connect(function()
	local ok, msg = remotes.BuyItem:InvokeServer("Shield")
	toast(msg, if ok then Color3.fromRGB(120, 200, 255) else Color3.fromRGB(255, 90, 90))
end)
local potionBuy = UI.Button("Potion (" .. Config.SpeedPotionCost .. "c)", Color3.fromRGB(150, 70, 255), { Size = UDim2.fromOffset(130, 52), Parent = side })
potionBuy.Activated:Connect(function()
	local ok, msg = remotes.BuyItem:InvokeServer("Potion")
	toast(msg, if ok then Color3.fromRGB(200, 150, 255) else Color3.fromRGB(255, 90, 90))
end)
local potionUse = UI.Button("USE POTION", Color3.fromRGB(255, 120, 0), { Size = UDim2.fromOffset(130, 52), Parent = side })
potionUse.Activated:Connect(function()
	local ok, msg = remotes.UsePotion:InvokeServer()
	toast(msg, if ok then Color3.fromRGB(255, 200, 80) else Color3.fromRGB(255, 90, 90))
end)

-- Troll / help buttons on the right
local right = UI.new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(150, 130), BackgroundTransparency = 1, Parent = gui })
local rightLayout = Instance.new("UIListLayout")
rightLayout.Padding = UDim.new(0, 10)
rightLayout.Parent = right
UI.Button("SLOW SAHUR", Color3.fromRGB(60, 160, 255), { Size = UDim2.fromOffset(150, 56), Parent = right }).Activated:Connect(function()
	buy("Product", "SlowSahur")
end)
UI.Button("+1 SAHUR 😈", Color3.fromRGB(220, 40, 40), { Size = UDim2.fromOffset(150, 56), Parent = right }).Activated:Connect(function()
	buy("Product", "ExtraSahur")
end)

local function refresh()
	statsLabel.Text = string.format(
		"%s coins  •  %d wins  •  🛡 %d  •  ⚡ %d",
		Format.Abbreviate(player:GetAttribute("Coins") or 0),
		player:GetAttribute("Wins") or 0,
		(player:GetAttribute("Shields") or 0) + (if player:GetAttribute("FreeShield") then 1 else 0),
		player:GetAttribute("Potions") or 0
	)
end
player.AttributeChanged:Connect(refresh)
refresh()

task.spawn(function()
	while true do
		local state = workspace:GetAttribute("State")
		local t = workspace:GetAttribute("TimeLeft") or 0
		if state == "Round" then
			stateLabel.Text = "SURVIVE! " .. Format.Time(t) .. "  •  " .. (workspace:GetAttribute("AliveCount") or 0) .. " alive"
			stateLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		elseif state == "Intermission" then
			stateLabel.Text = "Next round in " .. t
			stateLabel.TextColor3 = Color3.new(1, 1, 1)
		else
			stateLabel.Text = "Round over!"
			stateLabel.TextColor3 = Color3.new(1, 1, 1)
		end
		reviveButton.Visible = state == "Round" and not player:GetAttribute("Alive")
		task.wait(0.25)
	end
end)
