-- Squid Challenge client: stage HUD with a big red/green light, glass vision, revive + skip buttons, shop.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ShopUI = require(ReplicatedStorage.Common.ShopUI)
local UI = require(ReplicatedStorage.Common.UI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local glass = workspace:WaitForChild("Glass")

local gui = UI.new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") }) :: ScreenGui
local toast = UI.CreateToaster(gui)
remotes:WaitForChild("Notify").OnClientEvent:Connect(toast)
local buy = ShopUI.Buyer(Config, toast)
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(40, 30, 45))
ShopUI.VIPChatTag("VIP")

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(380, 80),
	BackgroundColor3 = Color3.fromRGB(35, 25, 40),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local stageLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 42), Position = UDim2.fromOffset(5, 2), Parent = top })
local infoLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 28), Position = UDim2.fromOffset(5, 46), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = top })
local light = UI.Label("", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 92), Size = UDim2.fromOffset(500, 70), Parent = gui })
local revive = UI.Button("REVIVE  R$ 25", Color3.fromRGB(40, 200, 80), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.62), Size = UDim2.fromOffset(320, 84), Visible = false, Parent = gui })
revive.Activated:Connect(function()
	buy("Product", "Revive")
end)

task.spawn(function()
	while true do
		local stage = workspace:GetAttribute("Stage") or "Lobby"
		local t = workspace:GetAttribute("TimeLeft") or 0
		stageLabel.Text = if stage == "Lobby" then "Next round in " .. t else stage .. "  •  " .. t .. "s"
		infoLabel.Text = (player:GetAttribute("Wins") or 0) .. " wins  •  " .. (player:GetAttribute("Coins") or 0) .. " coins"
		local l = workspace:GetAttribute("Light")
		light.Text = if l == "Green" then "🟢 GREEN LIGHT — RUN!" elseif l == "Red" then "🔴 RED LIGHT — FREEZE!" else ""
		light.TextColor3 = if l == "Red" then Color3.fromRGB(255, 60, 60) else Color3.fromRGB(90, 255, 90)
		revive.Visible = stage ~= "Lobby" and not player:GetAttribute("InRound")
		-- Glass Vision pass: safe panels glow for this player only.
		if player:GetAttribute("Pass_GlassVision") then
			for _, g in glass:GetChildren() do
				if g:IsA("BasePart") and g:GetAttribute("Safe") then
					g.Color = Color3.fromRGB(150, 255, 170)
				end
			end
		end
		task.wait(0.15)
	end
end)

local side = ShopUI.SideBar(gui)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	shop.Visible = not shop.Visible
end)
UI.Button("SKIP STAGE", Color3.fromRGB(255, 80, 140), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	buy("Product", "SkipStage")
end)
UI.Button("GLASS VISION", Color3.fromRGB(120, 200, 255), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	buy("Pass", "GlassVision")
end)
