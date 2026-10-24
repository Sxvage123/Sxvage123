-- Escape the Lava for Brainrots client: cash/income HUD, lava countdown + warning, zone readout,
-- speed upgrade, rebirth, shop.
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
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(20, 40, 70))
ShopUI.VIPChatTag("VIP")

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(400, 84),
	BackgroundColor3 = Color3.fromRGB(20, 35, 60),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local cashLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 44), Position = UDim2.fromOffset(5, 2), TextColor3 = Color3.fromRGB(90, 255, 90), Parent = top })
local incomeLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 30), Position = UDim2.fromOffset(5, 48), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = top })

local waveLabel = UI.Label("", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 96), Size = UDim2.fromOffset(560, 56), Parent = gui })
local zoneLabel = UI.Label("", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.fromOffset(520, 36), Parent = gui })
local carryLabel = UI.Label("", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -52), Size = UDim2.fromOffset(520, 30), TextColor3 = Color3.fromRGB(255, 200, 80), Parent = gui })
local flash = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 90, 20), BackgroundTransparency = 1, ZIndex = 0, Parent = gui }) :: Frame

local side = ShopUI.SideBar(gui)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(140, 48), Parent = side }).Activated:Connect(function()
	shop.Visible = not shop.Visible
end)
local speedButton = UI.Button("SPEED", Color3.fromRGB(40, 160, 255), { Size = UDim2.fromOffset(140, 48), Parent = side })
speedButton.Activated:Connect(function()
	remotes.UpgradeSpeed:InvokeServer()
end)
local rebirthButton = UI.Button("REBIRTH", Color3.fromRGB(200, 80, 255), { Size = UDim2.fromOffset(140, 48), Parent = side })
rebirthButton.Activated:Connect(function()
	remotes.Rebirth:InvokeServer()
end)
UI.Button("BASE", Color3.fromRGB(80, 80, 100), { Size = UDim2.fromOffset(140, 48), Parent = side }).Activated:Connect(function()
	remotes.Home:FireServer()
end)
UI.Button("STOP WAVE", Color3.fromRGB(255, 90, 20), { Size = UDim2.fromOffset(140, 48), Parent = side }).Activated:Connect(function()
	buy("Product", "StopLava")
end)
UI.Button("SECRET", Color3.fromRGB(20, 20, 20), { Size = UDim2.fromOffset(140, 48), Parent = side }).Activated:Connect(function()
	buy("Product", "SummonSecret")
end)

task.spawn(function()
	local pulse = 0
	while true do
		pulse += 1
		cashLabel.Text = "$" .. Format.Abbreviate(player:GetAttribute("Cash") or 0)
		incomeLabel.Text = "+$" .. Format.Abbreviate(player:GetAttribute("Income") or 0) .. "/s   •   🔁 " .. (player:GetAttribute("Rebirths") or 0)
		local level = player:GetAttribute("SpeedLevel") or 0
		speedButton.Text = if level >= Config.MaxSpeedLevel then "SPEED MAX" else "SPEED $" .. Format.Abbreviate(Config.SpeedUpgradeCost(level))
		rebirthButton.Text = "REBIRTH $" .. Format.Abbreviate(Config.RebirthCost(player:GetAttribute("Rebirths") or 0))

		local active = workspace:GetAttribute("WaveActive")
		local calm = workspace:GetAttribute("Calm") or 0
		local waveIn = workspace:GetAttribute("WaveIn") or 0
		if active then
			waveLabel.Text = "🌋 LAVA! GET TO A SHELTER! 🌋"
			waveLabel.TextColor3 = if pulse % 2 == 0 then Color3.fromRGB(255, 80, 80) else Color3.new(1, 1, 1)
			flash.BackgroundTransparency = 0.85
		elseif calm > 0 then
			waveLabel.Text = "😌 Lava stopped: " .. Format.Time(calm)
			waveLabel.TextColor3 = Color3.fromRGB(90, 255, 200)
			flash.BackgroundTransparency = 1
		else
			waveLabel.Text = "🌋 Next lava in " .. waveIn .. "s"
			waveLabel.TextColor3 = if waveIn <= 10 then Color3.fromRGB(255, 120, 80) else Color3.new(1, 1, 1)
			flash.BackgroundTransparency = 1
		end
		local luck = workspace:GetAttribute("LuckLeft") or 0

		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local z = if root then root.Position.Z else -1
		local zoneText = "🏠 Your base (safe)"
		if z >= 0 then
			zoneText = "⛰ The Foothills"
			for _, zone in Config.Zones do
				if z >= zone.From and z < zone.To then
					zoneText = zone.Name .. " (" .. zone.Rarity .. ")"
				end
			end
		end
		zoneLabel.Text = zoneText .. (if luck > 0 then "   •   🍀 2x Luck " .. Format.Time(luck) else "")
		local carrying = player:GetAttribute("Carrying") or 0
		carryLabel.Text = if carrying > 0 then "Carrying " .. carrying .. " brainrot(s): run back to base!" else ""
		task.wait(0.25)
	end
end)
