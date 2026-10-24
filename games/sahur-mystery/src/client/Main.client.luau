-- Sahur Mystery client: role reveal, bat/gun use, tracers, coins HUD, crates + skins, perks, shop.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
local ShopUI = require(ReplicatedStorage.Common.ShopUI)
local UI = require(ReplicatedStorage.Common.UI)

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui = UI.new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") }) :: ScreenGui
local toast = UI.CreateToaster(gui)
remotes:WaitForChild("Notify").OnClientEvent:Connect(toast)
local buy = ShopUI.Buyer(Config, toast)
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(35, 30, 45))
ShopUI.VIPChatTag("VIP")

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(400, 80),
	BackgroundColor3 = Color3.fromRGB(30, 25, 40),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local stateLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 40), Position = UDim2.fromOffset(5, 2), Parent = top })
local coinsLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 28), Position = UDim2.fromOffset(5, 46), TextColor3 = Color3.fromRGB(255, 210, 60), Parent = top })
local roleLabel = UI.Label("", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(420, 40), Parent = gui })

local function refresh()
	local cap = if player:GetAttribute("Pass_VIP") then Config.VIPCoinBag else Config.CoinBag
	coinsLabel.Text = string.format("🪙 %s coins  •  this round %d/%d  •  %d wins", Format.Abbreviate(player:GetAttribute("Coins") or 0), player:GetAttribute("RoundCoins") or 0, cap, player:GetAttribute("Wins") or 0)
	local role = player:GetAttribute("Role")
	roleLabel.Text = if role == "Sahur" then "You are TUNG TUNG SAHUR" elseif role == "Sheriff" then "You are the SHERIFF" elseif role == "Hero" then "You are the HERO" elseif role == "Innocent" then "You are INNOCENT" else ""
	roleLabel.TextColor3 = if role == "Sahur" then Color3.fromRGB(255, 70, 70) elseif role == "Sheriff" or role == "Hero" then Color3.fromRGB(90, 160, 255) else Color3.fromRGB(90, 255, 120)
end
player.AttributeChanged:Connect(refresh)
refresh()

task.spawn(function()
	while true do
		local state = workspace:GetAttribute("RoundState")
		local t = workspace:GetAttribute("TimeLeft") or 0
		stateLabel.Text = if state == "Playing" then Format.Time(t) .. "  •  " .. (workspace:GetAttribute("AliveCount") or 0) .. " alive" elseif state == "Intermission" then "Next round in " .. t elseif state == "Waiting" then "Waiting for players..." else "Round over!"
		task.wait(0.25)
	end
end)

-- Big role reveal at round start.
local reveal = UI.Label("", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromOffset(700, 110), Visible = false, Parent = gui })
local REVEAL = {
	Sahur = { "YOU ARE TUNG TUNG SAHUR", "Bonk everyone with your bat!", Color3.fromRGB(255, 70, 70) },
	Sheriff = { "YOU ARE THE SHERIFF", "Find Sahur and shoot them!", Color3.fromRGB(90, 160, 255) },
	Hero = { "YOU ARE THE HERO", "You grabbed the gun — stop Sahur!", Color3.fromRGB(90, 160, 255) },
	Innocent = { "YOU ARE INNOCENT", "Hide, collect coins, survive!", Color3.fromRGB(90, 255, 120) },
}
remotes:WaitForChild("Role").OnClientEvent:Connect(function(role)
	local r = REVEAL[role]
	if not r then
		return
	end
	reveal.Text = r[1] .. "\n" .. r[2]
	reveal.TextColor3 = r[3]
	reveal.Visible = true
	task.delay(3, function()
		reveal.Visible = false
	end)
end)

---------------------------------------------------------------- weapons

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	local character = player.Character
	if character and character:FindFirstChild("Bat") then
		remotes.Bat:FireServer()
	elseif character and character:FindFirstChild("Gun") then
		mouse.TargetFilter = character
		remotes.Gun:FireServer(mouse.Hit.Position)
	end
end)

remotes:WaitForChild("Tracer").OnClientEvent:Connect(function(from: Vector3, to: Vector3)
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(255, 240, 150)
	beam.Size = Vector3.new(0.15, 0.15, (to - from).Magnitude)
	beam.CFrame = CFrame.lookAt((from + to) / 2, to)
	beam.Parent = workspace
	TweenService:Create(beam, TweenInfo.new(0.25), { Transparency = 1 }):Play()
	Debris:AddItem(beam, 0.3)
end)

---------------------------------------------------------------- skins + crates

local skinsFrame = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 540, 0.72, 0),
	BackgroundColor3 = Color3.fromRGB(35, 30, 45),
	Visible = false,
	Parent = gui,
}, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
UI.Label("WEAPON SKINS", { Size = UDim2.new(1, -80, 0, 50), Position = UDim2.fromOffset(16, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = skinsFrame })
UI.Button("X", Color3.fromRGB(230, 60, 60), { Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -58, 0, 8), Parent = skinsFrame }).Activated:Connect(function()
	skinsFrame.Visible = false
end)
local crateButton = UI.Button("OPEN CRATE (" .. Config.CrateCost .. " coins)", Color3.fromRGB(255, 170, 0), { Position = UDim2.fromOffset(16, 62), Size = UDim2.new(1, -32, 0, 52), Parent = skinsFrame })
local odds = {}
for _, r in Config.Rarities do
	table.insert(odds, r.Name .. " " .. r.Weight .. "%")
end
UI.Label(table.concat(odds, " • "), { Position = UDim2.fromOffset(16, 118), Size = UDim2.new(1, -32, 0, 22), Font = Enum.Font.GothamMedium, Parent = skinsFrame })
local skinList = UI.new("ScrollingFrame", { Position = UDim2.fromOffset(12, 146), Size = UDim2.new(1, -24, 1, -158), BackgroundTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 8, Parent = skinsFrame })
local skinLayout = Instance.new("UIListLayout")
skinLayout.Padding = UDim.new(0, 6)
skinLayout.SortOrder = Enum.SortOrder.LayoutOrder
skinLayout.Parent = skinList

local function renderSkins()
	for _, c in skinList:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local owned = {}
	for id in string.gmatch(player:GetAttribute("OwnedSkins") or "", "[^,]+") do
		owned[id] = true
	end
	for i, skin in Config.Skins do
		local has = owned[skin.Id]
		local row = UI.new("Frame", { LayoutOrder = i, Size = UDim2.new(1, -10, 0, 52), BackgroundColor3 = Color3.fromRGB(55, 48, 70), Parent = skinList }, { UI.Corner(10) })
		UI.Label((if has then skin.Name else "??? ") .. "  (" .. skin.Kind .. ", " .. skin.Rarity .. ")", { Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -150, 1, -8), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Config.RarityColor[skin.Rarity], Parent = row })
		if has then
			local equipped = player:GetAttribute(skin.Kind .. "Skin") == skin.Id
			local b = UI.Button(if equipped then "EQUIPPED" else "EQUIP", if equipped then Color3.fromRGB(90, 90, 90) else Color3.fromRGB(40, 180, 70), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(120, 42), Parent = row })
			b.Activated:Connect(function()
				remotes.EquipSkin:InvokeServer(skin.Id)
				renderSkins()
			end)
		end
	end
end
crateButton.Activated:Connect(function()
	local ok, result = remotes.OpenCrate:InvokeServer()
	if not ok then
		toast(result, Color3.fromRGB(255, 90, 90))
		buy("Product", "CoinPack")
		return
	end
	local skin = Config.SkinById[result]
	toast("You got " .. skin.Name .. " (" .. skin.Rarity .. ")!", Config.RarityColor[skin.Rarity])
	renderSkins()
end)

local side = ShopUI.SideBar(gui)
UI.Button("SKINS", Color3.fromRGB(255, 120, 40), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	shop.Visible = false
	skinsFrame.Visible = not skinsFrame.Visible
	if skinsFrame.Visible then
		renderSkins()
	end
end)
UI.Button("BE SAHUR", Color3.fromRGB(220, 50, 50), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	buy("Product", "SahurPerk")
end)
UI.Button("BE SHERIFF", Color3.fromRGB(60, 120, 255), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	buy("Product", "SheriffPerk")
end)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	skinsFrame.Visible = false
	shop.Visible = not shop.Visible
end)
