-- Tower of Brainrot client: timer, section counter, coils, mutator buttons, shop.
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
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(30, 40, 60))
ShopUI.VIPChatTag("VIP")

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(380, 80),
	BackgroundColor3 = Color3.fromRGB(25, 30, 45),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local timerLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 42), Position = UDim2.fromOffset(5, 2), Parent = top })
local infoLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 28), Position = UDim2.fromOffset(5, 46), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = top })

task.spawn(function()
	while true do
		local left = (workspace:GetAttribute("RoundEnds") or 0) - os.time()
		timerLabel.Text = "New tower in " .. Format.Time(left) .. (if workspace:GetAttribute("LavaOn") then "  🔥 LAVA" else "")
		timerLabel.TextColor3 = if left < 60 then Color3.fromRGB(255, 90, 90) else Color3.new(1, 1, 1)
		infoLabel.Text = string.format("Section %d/%d  •  %d wins  •  %d coins", player:GetAttribute("Section") or 1, Config.Sections, player:GetAttribute("Wins") or 0, player:GetAttribute("Coins") or 0)
		task.wait(0.25)
	end
end)

local side = ShopUI.SideBar(gui)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	shop.Visible = not shop.Visible
end)
local function coilButton(label: string, pass: string, attr: string, remoteName: string)
	local b = UI.Button(label, Color3.fromRGB(60, 120, 255), { Size = UDim2.fromOffset(130, 52), Parent = side })
	local function refresh()
		b.Text = if player:GetAttribute("Pass_" .. pass) then label .. (if player:GetAttribute(attr) then ": ON" else ": OFF") else label .. " 🔒"
	end
	player.AttributeChanged:Connect(refresh)
	refresh()
	b.Activated:Connect(function()
		if player:GetAttribute("Pass_" .. pass) then
			remotes.ToggleCoil:FireServer(remoteName)
		else
			buy("Pass", pass)
		end
	end)
end
coilButton("Speed", "SpeedCoil", "SpeedOn", "Speed")
coilButton("Jump", "GravityCoil", "GravityOn", "Gravity")
UI.Button("SKIP", Color3.fromRGB(230, 60, 60), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	buy("Product", "SkipSection")
end)
UI.Button("LAVA 🔥", Color3.fromRGB(255, 110, 30), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	buy("Product", "LavaRise")
end)
