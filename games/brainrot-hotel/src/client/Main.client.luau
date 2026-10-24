-- Brainrot Hotel client: door counter, Sahur warning flash, hiding overlay, revive, knob upgrades, shop.
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
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(40, 25, 25))
ShopUI.VIPChatTag("VIP")

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(360, 80),
	BackgroundColor3 = Color3.fromRGB(30, 20, 20),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local doorLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 44), Position = UDim2.fromOffset(5, 2), TextColor3 = Color3.fromRGB(255, 215, 120), Parent = top })
local infoLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 28), Position = UDim2.fromOffset(5, 48), Parent = top })

local warnFrame = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(200, 0, 0), BackgroundTransparency = 1, ZIndex = 0, Parent = gui }) :: Frame
local warnLabel = UI.Label("", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 100), Size = UDim2.fromOffset(600, 60), TextColor3 = Color3.fromRGB(255, 70, 70), Parent = gui })
local hideLabel = UI.Label("", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.fromOffset(500, 40), TextColor3 = Color3.fromRGB(180, 220, 255), Parent = gui })

remotes:WaitForChild("Warn").OnClientEvent:Connect(function(seconds)
	local ends = os.clock() + seconds
	task.spawn(function()
		while os.clock() < ends do
			warnFrame.BackgroundTransparency = if warnFrame.BackgroundTransparency < 0.9 then 0.95 else 0.75
			warnLabel.Text = "👁 SAHUR IS COMING. HIDE IN A CLOSET!"
			task.wait(0.2)
		end
		warnFrame.BackgroundTransparency = 1
		task.wait(2)
		warnLabel.Text = ""
	end)
end)

local deadFrame = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(420, 170), BackgroundColor3 = Color3.fromRGB(30, 20, 20), Visible = false, Parent = gui }, { UI.Corner(16), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
UI.Label("💀 You died! Spectating...", { Size = UDim2.new(1, -20, 0, 50), Position = UDim2.fromOffset(10, 10), Parent = deadFrame })
UI.Button("REVIVE  R$ 25", Color3.fromRGB(40, 200, 80), { Size = UDim2.new(1, -40, 0, 80), Position = UDim2.fromOffset(20, 72), Parent = deadFrame }).Activated:Connect(function()
	buy("Product", "Revive")
end)

local upgrades = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(480, 70 + #Config.Upgrades * 66),
	BackgroundColor3 = Color3.fromRGB(30, 20, 20),
	Visible = false,
	Parent = gui,
}, { UI.Corner(16), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
UI.Label("KNOB SHOP", { Size = UDim2.new(1, -60, 0, 44), Position = UDim2.fromOffset(10, 6), Parent = upgrades })
UI.Button("X", Color3.fromRGB(220, 60, 60), { Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -48, 0, 8), Parent = upgrades }).Activated:Connect(function()
	upgrades.Visible = false
end)
local upgradeButtons: { [string]: TextButton } = {}
for i, u in Config.Upgrades do
	local row = UI.new("Frame", { Size = UDim2.new(1, -20, 0, 58), Position = UDim2.fromOffset(10, 56 + (i - 1) * 66), BackgroundColor3 = Color3.fromRGB(60, 40, 40), Parent = upgrades }, { UI.Corner(10) })
	UI.Label(u.Name, { Size = UDim2.new(0.6, 0, 0, 28), Position = UDim2.fromOffset(10, 2), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
	UI.Label(u.Description, { Size = UDim2.new(0.62, 0, 0, 22), Position = UDim2.fromOffset(10, 32), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(220, 200, 200), Parent = row })
	local b = UI.Button(u.Cost .. " knobs", Color3.fromRGB(200, 150, 40), { Size = UDim2.new(0.32, 0, 0, 44), Position = UDim2.new(0.66, 0, 0, 7), Parent = row })
	b.Activated:Connect(function()
		remotes.Upgrade:InvokeServer(u.Id)
	end)
	upgradeButtons[u.Id] = b
end

local side = ShopUI.SideBar(gui)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	shop.Visible = not shop.Visible
end)
UI.Button("KNOBS", Color3.fromRGB(200, 150, 40), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	upgrades.Visible = not upgrades.Visible
end)
UI.Button("SKIP 10", Color3.fromRGB(80, 140, 255), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	buy("Product", "SkipRooms")
end)
UI.Button("SUMMON SAHUR", Color3.fromRGB(200, 40, 40), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	buy("Product", "SummonSahur")
end)

task.spawn(function()
	while true do
		doorLabel.Text = "🚪 Door " .. string.format("%04d", workspace:GetAttribute("Door") or 0) .. " / " .. Config.FinalRoom
		infoLabel.Text = "🔑 " .. Format.Abbreviate(player:GetAttribute("Knobs") or 0) .. " knobs  •  best door " .. (player:GetAttribute("BestDoor") or 0)
		hideLabel.Text = if player:GetAttribute("Hiding") then "🚪 Hiding... use the closet again to get out" else ""
		deadFrame.Visible = player:GetAttribute("Dead") == true
		local owned = string.split(player:GetAttribute("Upgrades") or "", ",")
		for id, b in upgradeButtons do
			if table.find(owned, id) then
				b.Text = "OWNED"
				b.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
			end
		end
		task.wait(0.25)
	end
end)
