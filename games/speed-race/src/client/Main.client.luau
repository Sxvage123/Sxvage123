-- +1 Speed Brainrot Race client: big speed counter, distance bar to the next finish line, trails, rebirth, shop.
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
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(30, 30, 50))
ShopUI.VIPChatTag("VIP")

-- Top: speed + wins
local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(420, 96),
	BackgroundColor3 = Color3.fromRGB(25, 25, 40),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local speedLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 50), Position = UDim2.fromOffset(5, 2), TextColor3 = Color3.fromRGB(90, 220, 255), Parent = top })
local infoLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 22), Position = UDim2.fromOffset(5, 50), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = top })
local gainLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 18), Position = UDim2.fromOffset(5, 74), TextColor3 = Color3.fromRGB(140, 255, 140), Parent = top })

-- Bottom: progress to the next finish line
local barBack = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.fromOffset(520, 34),
	BackgroundColor3 = Color3.fromRGB(25, 25, 40),
	Parent = gui,
}, { UI.Corner(10), UI.Stroke(Color3.new(0, 0, 0), 3) })
local barFill = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(90, 220, 255), Parent = barBack }, { UI.Corner(10) }) :: Frame
local barLabel = UI.Label("", { Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = barBack })
local boostLabel = UI.Label("", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -56), Size = UDim2.fromOffset(520, 30), TextColor3 = Color3.fromRGB(255, 120, 255), Parent = gui })

-- Trails panel
local trails = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(440, 70 + #Config.Trails * 58),
	BackgroundColor3 = Color3.fromRGB(30, 30, 50),
	Visible = false,
	Parent = gui,
}, { UI.Corner(16), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
UI.Label("TRAILS  (boost speed gain)", { Size = UDim2.new(1, -60, 0, 44), Position = UDim2.fromOffset(10, 6), Parent = trails })
UI.Button("X", Color3.fromRGB(220, 60, 60), { Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -48, 0, 8), Parent = trails }).Activated:Connect(function()
	trails.Visible = false
end)
local trailButtons: { [string]: TextButton } = {}
for i, t in Config.Trails do
	local row = UI.new("Frame", { Size = UDim2.new(1, -20, 0, 50), Position = UDim2.fromOffset(10, 56 + (i - 1) * 58), BackgroundColor3 = t.Color:Lerp(Color3.new(0, 0, 0), 0.55), Parent = trails }, { UI.Corner(10) })
	UI.Label(t.Name .. "  +" .. t.Boost .. "x", { Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.fromOffset(10, 0), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = t.Color:Lerp(Color3.new(1, 1, 1), 0.3), Parent = row })
	local b = UI.Button("", Color3.fromRGB(40, 180, 70), { Size = UDim2.new(0.36, 0, 0, 40), Position = UDim2.new(0.62, 0, 0, 5), Parent = row })
	b.Activated:Connect(function()
		remotes.BuyTrail:InvokeServer(t.Id)
	end)
	trailButtons[t.Id] = b
end

local function refreshTrails()
	local owned = string.split(player:GetAttribute("OwnedTrails") or "", ",")
	local equipped = player:GetAttribute("Trail")
	for _, t in Config.Trails do
		local b = trailButtons[t.Id]
		if equipped == t.Id then
			b.Text = "EQUIPPED"
			b.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
		elseif table.find(owned, t.Id) then
			b.Text = "EQUIP"
			b.BackgroundColor3 = Color3.fromRGB(40, 140, 255)
		else
			b.Text = Format.Abbreviate(t.Cost) .. " WINS"
			b.BackgroundColor3 = Color3.fromRGB(40, 180, 70)
		end
	end
end

-- Side buttons
local side = ShopUI.SideBar(gui)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	shop.Visible = not shop.Visible
end)
UI.Button("TRAILS", Color3.fromRGB(255, 140, 40), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	refreshTrails()
	trails.Visible = not trails.Visible
end)
local rebirthButton = UI.Button("REBIRTH", Color3.fromRGB(200, 80, 255), { Size = UDim2.fromOffset(130, 48), Parent = side })
rebirthButton.Activated:Connect(function()
	remotes.Rebirth:InvokeServer()
end)
UI.Button("RETURN", Color3.fromRGB(80, 80, 100), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	remotes.Return:FireServer()
end)
UI.Button("+1K SPEED", Color3.fromRGB(40, 160, 255), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	buy("Product", "Speed1K")
end)
UI.Button("SKIP ZONE", Color3.fromRGB(255, 80, 140), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	buy("Product", "SkipZone")
end)

task.spawn(function()
	while true do
		local speed = player:GetAttribute("Speed") or 0
		local rebirths = player:GetAttribute("Rebirths") or 0
		speedLabel.Text = "⚡ " .. Format.Abbreviate(speed) .. " SPEED"
		infoLabel.Text = "🏆 " .. Format.Abbreviate(player:GetAttribute("Wins") or 0) .. " wins   •   🔁 " .. rebirths .. " rebirths"
		gainLabel.Text = "+" .. (1 + rebirths * Config.RebirthBoost) .. "x from rebirths"
		rebirthButton.Text = "REBIRTH (" .. Format.Abbreviate(Config.RebirthCost(rebirths)) .. ")"
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local z = if root then root.Position.Z else 0
		local prev, nextZone = 0, nil
		for _, zone in Config.Zones do
			if z < zone.Dist then
				nextZone = zone
				break
			end
			prev = zone.Dist
		end
		if nextZone then
			barFill.Size = UDim2.fromScale(math.clamp((z - prev) / (nextZone.Dist - prev), 0, 1), 1)
			barFill.BackgroundColor3 = nextZone.Color
			barLabel.Text = string.format("%s  •  %d studs to go", nextZone.Name, math.max(0, math.floor(nextZone.Dist - z)))
		else
			barFill.Size = UDim2.fromScale(1, 1)
			barLabel.Text = "YOU BEAT THE TRACK! Rebirth to go even faster"
		end
		local left = workspace:GetAttribute("BoostLeft") or 0
		boostLabel.Text = if left > 0 then string.format("3x SERVER SPEED by %s  •  %s", tostring(workspace:GetAttribute("Booster")), Format.Time(left)) else ""
		if trails.Visible then
			refreshTrails()
		end
		task.wait(0.2)
	end
end)
