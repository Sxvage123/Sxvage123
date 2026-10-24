-- Brainrot Hide and Seek client: role banner, timers, radar markers, shop.
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
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(30, 40, 30))
ShopUI.VIPChatTag("VIP")

local top = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(420, 84), BackgroundColor3 = Color3.fromRGB(30, 40, 30), Parent = gui }, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local main = UI.Label("", { Size = UDim2.new(1, -10, 0, 48), Position = UDim2.fromOffset(5, 2), Parent = top })
local info = UI.Label("", { Size = UDim2.new(1, -10, 0, 28), Position = UDim2.fromOffset(5, 52), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = top })

remotes:WaitForChild("Radar").OnClientEvent:Connect(function(spots)
	for _, pos in spots do
		local marker = Instance.new("Part")
		marker.Anchored = true
		marker.CanCollide = false
		marker.Size = Vector3.new(2, 40, 2)
		marker.Position = pos + Vector3.new(0, 20, 0)
		marker.Color = Color3.fromRGB(255, 50, 50)
		marker.Material = Enum.Material.Neon
		marker.Parent = workspace
		task.delay(5, function()
			marker:Destroy()
		end)
	end
end)

local side = ShopUI.SideBar(gui)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	shop.Visible = not shop.Visible
end)
UI.Button("BE SEEKER", Color3.fromRGB(230, 100, 50), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	buy("Product", "BeSeeker")
end)
UI.Button("RADAR", Color3.fromRGB(230, 50, 50), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	buy("Product", "Radar")
end)

while true do
	local stage = workspace:GetAttribute("Stage") or "Lobby"
	local t = workspace:GetAttribute("TimeLeft") or 0
	local role = player:GetAttribute("Role")
	if stage == "Lobby" then
		main.Text = "Next round in " .. t
	elseif role == "Seeker" then
		main.Text = if stage == "Hide" then "😈 You're the SEEKER. Released in " .. t else "😈 FIND THEM! " .. t .. "s  •  " .. (workspace:GetAttribute("HidersLeft") or 0) .. " left"
	elseif role == "Hider" then
		main.Text = if stage == "Hide" then "🙈 HIDE! " .. t .. "s" else "🤫 Stay hidden! " .. t .. "s"
	else
		main.Text = "👀 Spectating  •  " .. t .. "s"
	end
	info.Text = "Seeker: " .. tostring(workspace:GetAttribute("Seeker") or "?") .. "  •  " .. (player:GetAttribute("Wins") or 0) .. " wins  •  " .. (player:GetAttribute("Coins") or 0) .. " coins"
	task.wait(0.2)
end
