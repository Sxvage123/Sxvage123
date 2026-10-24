-- Pizza Restaurant Tycoon client: cash HUD, upgrades menu, boosts, shop.
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
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(70, 35, 25))
ShopUI.VIPChatTag("VIP")

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(380, 80),
	BackgroundColor3 = Color3.fromRGB(60, 30, 20),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local cashLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 42), Position = UDim2.fromOffset(5, 2), TextColor3 = Color3.fromRGB(120, 255, 120), Parent = top })
local infoLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 28), Position = UDim2.fromOffset(5, 46), Parent = top })
local hint = UI.Label("Bake at an oven, then serve the customers waiting at your tables!", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.fromOffset(620, 28), Parent = gui })
local function refresh()
	cashLabel.Text = Format.Cash(player:GetAttribute("Cash") or 0)
	infoLabel.Text = string.format("🍕 %s per pizza  •  +%d%% tips  •  %d served", Format.Cash(player:GetAttribute("Price") or Config.BasePrice), math.floor((player:GetAttribute("Tips") or 0) * 100), player:GetAttribute("Served") or 0)
	hint.Visible = (player:GetAttribute("Served") or 0) < 5
end
player.AttributeChanged:Connect(refresh)
refresh()

-- Upgrades menu
local menu = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 520, 0.72, 0),
	BackgroundColor3 = Color3.fromRGB(70, 35, 25),
	Visible = false,
	Parent = gui,
}, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
UI.Label("UPGRADES", { Size = UDim2.new(1, -80, 0, 50), Position = UDim2.fromOffset(16, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = menu })
UI.Button("X", Color3.fromRGB(230, 60, 60), { Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -58, 0, 8), Parent = menu }).Activated:Connect(function()
	menu.Visible = false
end)
local list = UI.new("ScrollingFrame", { Position = UDim2.fromOffset(12, 64), Size = UDim2.new(1, -24, 1, -76), BackgroundTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 8, Parent = menu })
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list
local DESC = { Oven = "Another oven to bake with", Price = "Menu price x%s", Tips = "+%d%% tips", Chef = "Bakes pizzas for you", Speed = "Ovens bake x%s faster", Seats = "+%d seats" }
local rows = {}
for i, u in Config.Upgrades do
	local row = UI.new("Frame", { LayoutOrder = i, Size = UDim2.new(1, -10, 0, 66), BackgroundColor3 = Color3.fromRGB(95, 55, 40), Parent = list }, { UI.Corner(12) })
	UI.Label(u.Name, { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -150, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
	local d = DESC[u.Kind]
	local text = if u.Kind == "Tips" then string.format(d, u.Value * 100) elseif u.Kind == "Seats" then string.format(d, u.Value) elseif u.Value then string.format(d, tostring(u.Value)) else d
	UI.Label(text, { Position = UDim2.fromOffset(12, 36), Size = UDim2.new(1, -150, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, Parent = row })
	local b = UI.Button(Format.Cash(u.Cost), Color3.fromRGB(40, 180, 70), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(120, 48), Parent = row })
	b.Activated:Connect(function()
		local ok, msg = remotes.BuyUpgrade:InvokeServer(u.Id)
		toast(msg, if ok then Color3.fromRGB(120, 255, 120) else Color3.fromRGB(255, 90, 90))
	end)
	rows[u.Id] = b
end
local function refreshMenu()
	local have = {}
	for id in string.gmatch(player:GetAttribute("Upgrades") or "", "[^,]+") do
		have[id] = true
	end
	for _, u in Config.Upgrades do
		local b = rows[u.Id]
		local prev = Config.Upgrades[u.Index - 1]
		if have[u.Id] then
			b.Text = "OWNED"
			b.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
		elseif prev and not have[prev.Id] then
			b.Text = "🔒"
			b.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
		else
			b.Text = Format.Cash(u.Cost)
			b.BackgroundColor3 = Color3.fromRGB(40, 180, 70)
		end
	end
end
player:GetAttributeChangedSignal("Upgrades"):Connect(refreshMenu)
refreshMenu()

local side = ShopUI.SideBar(gui)
UI.Button("UPGRADES", Color3.fromRGB(255, 140, 40), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	shop.Visible = false
	menu.Visible = not menu.Visible
end)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	menu.Visible = false
	shop.Visible = not shop.Visible
end)
UI.Button("RUSH HOUR", Color3.fromRGB(255, 200, 0), { Size = UDim2.fromOffset(130, 52), TextColor3 = Color3.fromRGB(60, 30, 0), Parent = side }).Activated:Connect(function()
	buy("Product", "RushHour")
end)
UI.Button("CELEBRITY", Color3.fromRGB(200, 60, 255), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	buy("Product", "Celebrity")
end)
