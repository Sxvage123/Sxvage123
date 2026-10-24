-- Brainrot Slap Battles client: slap nearest player in front, glove ability, knockback, glove shop, shop.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local ShopUI = require(ReplicatedStorage.Common.ShopUI)
local UI = require(ReplicatedStorage.Common.UI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui = UI.new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") }) :: ScreenGui
local toast = UI.CreateToaster(gui)
remotes:WaitForChild("Notify").OnClientEvent:Connect(toast)
local buy = ShopUI.Buyer(Config, toast)
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(60, 35, 30))
ShopUI.VIPChatTag("VIP")

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(360, 64),
	BackgroundColor3 = Color3.fromRGB(50, 25, 25),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local statsLabel = UI.Label("", { Size = UDim2.new(1, -10, 1, -8), Position = UDim2.fromOffset(5, 4), TextColor3 = Color3.fromRGB(255, 200, 120), Parent = top })
local hint = UI.Label("Walk into the purple portal to jump into the arena!", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 76), Size = UDim2.fromOffset(560, 26), Parent = gui })
local function refresh()
	statsLabel.Text = "👋 " .. (player:GetAttribute("Slaps") or 0) .. " slaps   •   💀 " .. (player:GetAttribute("Kills") or 0) .. " kills"
end
player.AttributeChanged:Connect(refresh)
refresh()

---------------------------------------------------------------- slapping

local function myRoot(): BasePart?
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function bestTarget(): Player?
	local root = myRoot()
	if not root then
		return nil
	end
	local best, bestScore = nil, -math.huge
	for _, p in Players:GetPlayers() do
		local r = p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if r then
			local offset = r.Position - root.Position
			local dist = offset.Magnitude
			if dist <= Config.SlapRange then
				local facing = if dist > 0.1 then root.CFrame.LookVector:Dot(offset.Unit) else 1
				local score = facing * 2 - dist / Config.SlapRange
				if score > bestScore then
					best, bestScore = p, score
				end
			end
		end
	end
	return best
end

local lastSwing = 0
local function swing()
	local character = player.Character
	if not (character and character:FindFirstChild("Glove")) then
		local tool = player.Backpack:FindFirstChild("Glove")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if tool and humanoid then
			humanoid:EquipTool(tool)
		end
		return
	end
	if os.clock() - lastSwing < 0.25 then
		return
	end
	lastSwing = os.clock()
	remotes.Slap:FireServer(bestTarget())
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		swing()
	elseif input.KeyCode == Enum.KeyCode.E then
		remotes.Ability:FireServer()
	end
end)

local slapButton = UI.Button("SLAP!", Color3.fromRGB(230, 60, 50), {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -20, 1, -130),
	Size = UDim2.fromOffset(120, 120),
	Visible = UserInputService.TouchEnabled,
	Parent = gui,
})
slapButton.Activated:Connect(swing)
local abilityButton = UI.Button("E", Color3.fromRGB(60, 120, 255), {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -150, 1, -140),
	Size = UDim2.fromOffset(80, 80),
	Visible = UserInputService.TouchEnabled,
	Parent = gui,
})
abilityButton.Activated:Connect(function()
	remotes.Ability:FireServer()
end)

-- Knockback is applied by the victim's own client (it owns its character's physics).
remotes:WaitForChild("Knockback").OnClientEvent:Connect(function(velocity: Vector3)
	local root = myRoot()
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end
	humanoid.PlatformStand = true
	root.AssemblyLinearVelocity = velocity
	task.delay(0.7, function()
		if humanoid.Parent then
			humanoid.PlatformStand = false
		end
	end)
	local flash = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.6, ZIndex = 0, Parent = gui })
	TweenService:Create(flash, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
	task.delay(0.35, flash.Destroy, flash)
end)

task.spawn(function()
	while true do
		local root = myRoot()
		hint.Visible = root ~= nil and root.Position.Y > 40
		task.wait(0.5)
	end
end)

---------------------------------------------------------------- glove shop

local gloves = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 520, 0.7, 0),
	BackgroundColor3 = Color3.fromRGB(60, 35, 30),
	Visible = false,
	Parent = gui,
}, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
UI.Label("GLOVES", { Size = UDim2.new(1, -80, 0, 50), Position = UDim2.fromOffset(16, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = gloves })
UI.Button("X", Color3.fromRGB(230, 60, 60), { Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -58, 0, 8), Parent = gloves }).Activated:Connect(function()
	gloves.Visible = false
end)
local list = UI.new("ScrollingFrame", { Position = UDim2.fromOffset(12, 64), Size = UDim2.new(1, -24, 1, -76), BackgroundTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 8, Parent = gloves })
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list
local KIND_TEXT = { slap = "Single slap", aoe = "Hits everyone around you", dash = "Press E to dash", explode = "Explodes on hit" }
local buttons = {}
for i, g in Config.Gloves do
	local row = UI.new("Frame", { LayoutOrder = i, Size = UDim2.new(1, -10, 0, 70), BackgroundColor3 = Color3.fromRGB(85, 55, 45), Parent = list }, { UI.Corner(12) })
	UI.Label(g.Name, { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -150, 0, 32), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = g.Color, Parent = row })
	UI.Label(string.format("Power %d  •  %.1fs  •  %s", g.Power, g.Cooldown, KIND_TEXT[g.Kind]), { Position = UDim2.fromOffset(12, 38), Size = UDim2.new(1, -150, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, Parent = row })
	local b = UI.Button("", Color3.fromRGB(40, 180, 70), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(120, 50), Parent = row })
	b.Activated:Connect(function()
		local ok, msg = remotes.BuyGlove:InvokeServer(g.Id)
		if not ok and string.sub(msg, 1, 5) == "Pass:" then
			buy("Pass", string.sub(msg, 6))
			return
		end
		toast(msg, if ok then Color3.fromRGB(120, 255, 120) else Color3.fromRGB(255, 90, 90))
	end)
	buttons[g.Id] = { Button = b, Glove = g }
end
local function refreshGloves()
	local owned = {}
	for id in string.gmatch(player:GetAttribute("OwnedGloves") or "", "[^,]+") do
		owned[id] = true
	end
	for id, entry in buttons do
		local g = entry.Glove
		local has = owned[id] or (g.Pass and player:GetAttribute("Pass_" .. g.Pass))
		local equipped = player:GetAttribute("Glove") == id
		entry.Button.Text = if equipped then "EQUIPPED" elseif has then "EQUIP" elseif g.Pass then "R$" else "👋 " .. g.Cost
		entry.Button.BackgroundColor3 = if equipped then Color3.fromRGB(90, 90, 90) elseif has then Color3.fromRGB(40, 140, 230) else Color3.fromRGB(40, 180, 70)
	end
end
player.AttributeChanged:Connect(function(name)
	if name == "OwnedGloves" or name == "Glove" or string.sub(name, 1, 5) == "Pass_" then
		refreshGloves()
	end
end)
refreshGloves()

local side = ShopUI.SideBar(gui)
UI.Button("GLOVES", Color3.fromRGB(230, 120, 60), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	shop.Visible = false
	gloves.Visible = not gloves.Visible
end)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	gloves.Visible = false
	shop.Visible = not shop.Visible
end)
UI.Button("SHIELD", Color3.fromRGB(80, 160, 255), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	buy("Product", "Shield")
end)
