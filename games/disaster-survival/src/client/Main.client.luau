-- Brainrot Disaster Survival client: round HUD, pick-the-next-disaster panel, upgrades, revive, shop.
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
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(40, 30, 30))
ShopUI.VIPChatTag("VIP")

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(420, 80),
	BackgroundColor3 = Color3.fromRGB(35, 25, 25),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local stageLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 44), Position = UDim2.fromOffset(5, 2), Parent = top })
local infoLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 28), Position = UDim2.fromOffset(5, 48), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = top })

local revive = UI.Button("REVIVE  R$ 25", Color3.fromRGB(40, 200, 80), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.62), Size = UDim2.fromOffset(320, 84), Visible = false, Parent = gui })
revive.Activated:Connect(function()
	buy("Product", "Revive")
end)

-- Pick the next disaster
local picker = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(420, 70 + #Config.Disasters * 56),
	BackgroundColor3 = Color3.fromRGB(35, 25, 25),
	Visible = false,
	Parent = gui,
}, { UI.Corner(16), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
UI.Label("PICK THE NEXT DISASTER", { Size = UDim2.new(1, -60, 0, 44), Position = UDim2.fromOffset(10, 6), Parent = picker })
UI.Button("X", Color3.fromRGB(220, 60, 60), { Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -48, 0, 8), Parent = picker }).Activated:Connect(function()
	picker.Visible = false
end)
for i, d in Config.Disasters do
	UI.Button(d.Name, d.Color:Lerp(Color3.new(0, 0, 0), 0.25), { Size = UDim2.new(1, -20, 0, 48), Position = UDim2.fromOffset(10, 56 + (i - 1) * 56), Parent = picker }).Activated:Connect(function()
		remotes.Choose:FireServer(d.Id)
		buy("Product", "ChooseDisaster")
		picker.Visible = false
	end)
end

local side = ShopUI.SideBar(gui)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(140, 48), Parent = side }).Activated:Connect(function()
	shop.Visible = not shop.Visible
end)
UI.Button("PICK DISASTER", Color3.fromRGB(255, 100, 40), { Size = UDim2.fromOffset(140, 48), Parent = side }).Activated:Connect(function()
	picker.Visible = not picker.Visible
end)
local healthButton = UI.Button("", Color3.fromRGB(220, 60, 80), { Size = UDim2.fromOffset(140, 48), Parent = side })
healthButton.Activated:Connect(function()
	remotes.Upgrade:InvokeServer("Health")
end)
local speedButton = UI.Button("", Color3.fromRGB(40, 160, 255), { Size = UDim2.fromOffset(140, 48), Parent = side })
speedButton.Activated:Connect(function()
	remotes.Upgrade:InvokeServer("Speed")
end)

local function upgradeText(name: string, level: number): string
	if level >= Config.MaxLevel then
		return name .. " MAX"
	end
	return name .. " " .. Config.UpgradeCost(level) .. "c"
end

task.spawn(function()
	while true do
		local stage = workspace:GetAttribute("Stage") or "Lobby"
		local t = workspace:GetAttribute("TimeLeft") or 0
		if stage == "Lobby" then
			stageLabel.Text = "Next disaster in " .. t
		elseif stage == "Warning" then
			stageLabel.Text = "⚠️ Disaster in " .. t .. "..."
		else
			stageLabel.Text = tostring(workspace:GetAttribute("Disaster") or "Disaster") .. "  •  " .. t .. "s"
		end
		infoLabel.Text = (player:GetAttribute("Wins") or 0) .. " survived  •  " .. (player:GetAttribute("Coins") or 0) .. " coins"
		healthButton.Text = upgradeText("❤️ HP", player:GetAttribute("HealthLevel") or 0)
		speedButton.Text = upgradeText("👟 SPD", player:GetAttribute("SpeedLevel") or 0)
		revive.Visible = stage == "Disaster" and not player:GetAttribute("InRound")
		task.wait(0.2)
	end
end)
