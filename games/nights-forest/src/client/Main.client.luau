-- 99 Nights with Sahur client: day/night HUD, fuel + hunger bars, wood count, classes, revive, shop.
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
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(30, 25, 40))
ShopUI.VIPChatTag("VIP")

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(380, 80),
	BackgroundColor3 = Color3.fromRGB(25, 20, 35),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local phaseLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 44), Position = UDim2.fromOffset(5, 2), Parent = top })
local infoLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 28), Position = UDim2.fromOffset(5, 48), TextColor3 = Color3.fromRGB(120, 220, 255), Parent = top })

local function bar(y: number, color: Color3)
	local back = UI.new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, y), Size = UDim2.fromOffset(260, 28), BackgroundColor3 = Color3.fromRGB(25, 20, 35), Parent = gui }, { UI.Corner(8), UI.Stroke(Color3.new(0, 0, 0), 2) })
	local fill = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, Parent = back }, { UI.Corner(8) }) :: Frame
	local label = UI.Label("", { Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = back })
	return fill, label
end
local fuelFill, fuelLabel = bar(-86, Color3.fromRGB(255, 140, 40))
local hungerFill, hungerLabel = bar(-52, Color3.fromRGB(220, 60, 80))
local woodLabel = UI.Label("", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -14), Size = UDim2.fromOffset(260, 30), TextColor3 = Color3.fromRGB(230, 190, 140), Parent = gui })

local deadFrame = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(420, 170), BackgroundColor3 = Color3.fromRGB(25, 20, 35), Visible = false, Parent = gui }, { UI.Corner(16), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
UI.Label("💀 You died! Back at sunrise...", { Size = UDim2.new(1, -20, 0, 50), Position = UDim2.fromOffset(10, 10), Parent = deadFrame })
UI.Button("REVIVE NOW  R$ 25", Color3.fromRGB(40, 200, 80), { Size = UDim2.new(1, -40, 0, 80), Position = UDim2.fromOffset(20, 72), Parent = deadFrame }).Activated:Connect(function()
	buy("Product", "Revive")
end)

-- Classes panel
local classes = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(500, 70 + #Config.Classes * 66),
	BackgroundColor3 = Color3.fromRGB(30, 25, 40),
	Visible = false,
	Parent = gui,
}, { UI.Corner(16), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
UI.Label("CLASSES (💎)", { Size = UDim2.new(1, -60, 0, 44), Position = UDim2.fromOffset(10, 6), Parent = classes })
UI.Button("X", Color3.fromRGB(220, 60, 60), { Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -48, 0, 8), Parent = classes }).Activated:Connect(function()
	classes.Visible = false
end)
local classButtons: { [string]: TextButton } = {}
for i, c in Config.Classes do
	local row = UI.new("Frame", { Size = UDim2.new(1, -20, 0, 58), Position = UDim2.fromOffset(10, 56 + (i - 1) * 66), BackgroundColor3 = Color3.fromRGB(50, 45, 65), Parent = classes }, { UI.Corner(10) })
	UI.Label(c.Id, { Size = UDim2.new(0.6, 0, 0, 28), Position = UDim2.fromOffset(10, 2), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
	UI.Label(c.Description, { Size = UDim2.new(0.62, 0, 0, 22), Position = UDim2.fromOffset(10, 32), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(200, 200, 220), Parent = row })
	local b = UI.Button("", Color3.fromRGB(40, 180, 70), { Size = UDim2.new(0.32, 0, 0, 44), Position = UDim2.new(0.66, 0, 0, 7), Parent = row })
	b.Activated:Connect(function()
		remotes.Class:InvokeServer(c.Id)
	end)
	classButtons[c.Id] = b
end

local side = ShopUI.SideBar(gui)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	shop.Visible = not shop.Visible
end)
UI.Button("CLASSES", Color3.fromRGB(80, 160, 255), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	classes.Visible = not classes.Visible
end)
UI.Button("FILL FIRE", Color3.fromRGB(255, 140, 40), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	buy("Product", "FuelFire")
end)
UI.Button("BANISH", Color3.fromRGB(200, 60, 200), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	buy("Product", "BanishSahur")
end)

task.spawn(function()
	while true do
		local phase = workspace:GetAttribute("Phase") or "Day"
		local night = workspace:GetAttribute("Night") or 0
		local t = workspace:GetAttribute("TimeLeft") or 0
		phaseLabel.Text = if phase == "Night" then "🌙 Night " .. night .. "  •  " .. t .. "s" else "☀️ Day " .. (night + 1) .. "  •  dark in " .. t .. "s"
		phaseLabel.TextColor3 = if phase == "Night" then Color3.fromRGB(180, 140, 255) else Color3.fromRGB(255, 220, 120)
		infoLabel.Text = "💎 " .. (player:GetAttribute("Diamonds") or 0) .. "   •   Best: night " .. (player:GetAttribute("BestNight") or 0)
		local fuel = workspace:GetAttribute("Fuel") or 0
		fuelFill.Size = UDim2.fromScale(math.clamp(fuel / Config.MaxFuel, 0, 1), 1)
		fuelLabel.Text = "🔥 Fire " .. fuel .. "%"
		local hunger = player:GetAttribute("Hunger") or 100
		hungerFill.Size = UDim2.fromScale(math.clamp(hunger / 100, 0, 1), 1)
		hungerLabel.Text = "🍖 Hunger " .. hunger .. "%"
		woodLabel.Text = "🪵 Wood: " .. (player:GetAttribute("Wood") or 0)
		deadFrame.Visible = player:GetAttribute("Dead") == true
		if classes.Visible then
			local owned = string.split(player:GetAttribute("OwnedClasses") or "", ",")
			local current = player:GetAttribute("Class")
			for _, c in Config.Classes do
				local b = classButtons[c.Id]
				if current == c.Id then
					b.Text = "EQUIPPED"
					b.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
				elseif table.find(owned, c.Id) then
					b.Text = "EQUIP"
					b.BackgroundColor3 = Color3.fromRGB(40, 140, 255)
				else
					b.Text = "💎 " .. c.Cost
					b.BackgroundColor3 = Color3.fromRGB(40, 180, 70)
				end
			end
		end
		task.wait(0.25)
	end
end)
