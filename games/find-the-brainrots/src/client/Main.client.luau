-- Find the Brainrots client: counter, index with hints, radar/guide beams, teleports, spinning collectibles.
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local ShopUI = require(ReplicatedStorage.Common.ShopUI)
local UI = require(ReplicatedStorage.Common.UI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local hints = HttpService:JSONDecode((ReplicatedStorage:WaitForChild("Hints") :: StringValue).Value)

local gui = UI.new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") }) :: ScreenGui
local toast = UI.CreateToaster(gui)
remotes:WaitForChild("Notify").OnClientEvent:Connect(toast)
local buy = ShopUI.Buyer(Config, toast)
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(40, 60, 40))

local counter = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(300, 60),
	BackgroundColor3 = Color3.fromRGB(30, 50, 30),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local counterLabel = UI.Label("", { Size = UDim2.new(1, -10, 1, -8), Position = UDim2.fromOffset(5, 4), Parent = counter })

local found: { [number]: boolean } = {}
local function refreshFound()
	table.clear(found)
	for id in string.gmatch(player:GetAttribute("Found") or "", "[^,]+") do
		found[tonumber(id) :: number] = true
	end
	counterLabel.Text = "Found " .. (player:GetAttribute("FoundCount") or 0) .. " / " .. (workspace:GetAttribute("TotalBrainrots") or #hints)
end
player:GetAttributeChangedSignal("Found"):Connect(refreshFound)
refreshFound()

---------------------------------------------------------------- beams (radar + paid guide)

local function makeBeam(color: Color3): (Beam, Attachment)
	local target = Instance.new("Attachment")
	target.Parent = workspace.Terrain
	local beam = Instance.new("Beam")
	beam.Attachment1 = target
	beam.Color = ColorSequence.new(color)
	beam.Width0 = 0.6
	beam.Width1 = 0.6
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Enabled = false
	beam.Parent = workspace.Terrain
	return beam, target
end
local radarBeam, radarTarget = makeBeam(Color3.fromRGB(0, 255, 200))
local guideBeam, guideTarget = makeBeam(Color3.fromRGB(255, 215, 0))
local guideUntil = 0

remotes:WaitForChild("Guide").OnClientEvent:Connect(function(position: Vector3, seconds: number, hint: string)
	guideTarget.WorldPosition = position
	guideUntil = os.clock() + seconds
	toast("Follow the gold beam! Hint: " .. hint, Color3.fromRGB(255, 215, 0))
end)

local rootAttachment: Attachment? = nil
local function onCharacter(character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root then
		local a = Instance.new("Attachment")
		a.Parent = root
		rootAttachment = a
		radarBeam.Attachment0 = a
		guideBeam.Attachment0 = a
	end
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then
	task.spawn(onCharacter, player.Character)
end

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local nearest, nearestDist = nil, math.huge
	for _, model in CollectionService:GetTagged("Collectible") do
		local body = (model :: Model).PrimaryPart
		local index = model:GetAttribute("Index")
		if body and index then
			-- Spin + bob, and fade the ones you've found.
			local base = body:GetAttribute("BasePos") or body.Position
			body:SetAttribute("BasePos", base)
			local isFound = found[index] == true
			if model:GetAttribute("FadedLocal") ~= isFound then
				model:SetAttribute("FadedLocal", isFound)
				for _, d in model:GetDescendants() do
					if d:IsA("BasePart") and d ~= body then
						d.LocalTransparencyModifier = if isFound then 0.75 else 0
					end
				end
			end
			if root and not isFound then
				local d = (base - root.Position).Magnitude
				if d < nearestDist then
					nearest, nearestDist = base, d
				end
			end
			body.CFrame = CFrame.new(base + Vector3.new(0, math.sin(t * 2 + index) * 0.4, 0)) * CFrame.Angles(0, t * 1.5 + index, 0)
		end
	end
	radarBeam.Enabled = rootAttachment ~= nil and nearest ~= nil and player:GetAttribute("Pass_Radar") == true
	if nearest then
		radarTarget.WorldPosition = nearest
	end
	guideBeam.Enabled = rootAttachment ~= nil and t < guideUntil
end)

---------------------------------------------------------------- index

local index = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 560, 0.72, 0),
	BackgroundColor3 = Color3.fromRGB(30, 50, 30),
	Visible = false,
	Parent = gui,
}, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
UI.Label("BRAINROT INDEX", { Size = UDim2.new(1, -80, 0, 50), Position = UDim2.fromOffset(16, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = index })
UI.Button("X", Color3.fromRGB(230, 60, 60), { Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -58, 0, 8), Parent = index }).Activated:Connect(function()
	index.Visible = false
end)
local list = UI.new("ScrollingFrame", {
	Position = UDim2.fromOffset(12, 64),
	Size = UDim2.new(1, -24, 1, -76),
	BackgroundTransparency = 1,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ScrollBarThickness = 8,
	Parent = index,
})
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local function renderIndex()
	for _, c in list:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for i, hint in hints do
		local isFound = found[i]
		local row = UI.new("Frame", { LayoutOrder = i, Size = UDim2.new(1, -10, 0, 58), BackgroundColor3 = if isFound then Color3.fromRGB(50, 90, 50) else Color3.fromRGB(45, 55, 45), Parent = list }, { UI.Corner(10) })
		UI.Label((if isFound then "✅ " .. Config.Names[i] else "❓ " .. Config.Names[i]), { Position = UDim2.fromOffset(10, 2), Size = UDim2.new(1, -20, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = if isFound then Color3.fromHSV(i / #hints, 0.6, 1) else Color3.fromRGB(200, 200, 200), Parent = row })
		UI.Label("Hint: " .. hint, { Position = UDim2.fromOffset(10, 30), Size = UDim2.new(1, -20, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(210, 220, 210), Parent = row })
	end
end
player:GetAttributeChangedSignal("Found"):Connect(function()
	if index.Visible then
		renderIndex()
	end
end)

---------------------------------------------------------------- teleport menu

local tpFrame = UI.new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 150, 0.5, 0),
	Size = UDim2.fromOffset(170, 5 * 52 + 10),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = gui,
})
local tpLayout = Instance.new("UIListLayout")
tpLayout.Padding = UDim.new(0, 6)
tpLayout.Parent = tpFrame
for i, zone in Config.ZoneSpawns do
	UI.Button(zone.Name, Color3.fromRGB(80, 140, 255), { Size = UDim2.fromOffset(170, 46), Parent = tpFrame }).Activated:Connect(function()
		remotes.Teleport:FireServer(i)
		tpFrame.Visible = false
	end)
end

local side = ShopUI.SideBar(gui)
UI.Button("INDEX", Color3.fromRGB(255, 170, 0), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	shop.Visible = false
	index.Visible = not index.Visible
	if index.Visible then
		renderIndex()
	end
end)
UI.Button("TELEPORT", Color3.fromRGB(80, 140, 255), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	if player:GetAttribute("Pass_Teleporter") then
		tpFrame.Visible = not tpFrame.Visible
	else
		buy("Pass", "Teleporter")
	end
end)
UI.Button("HINT", Color3.fromRGB(255, 215, 0), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	buy("Product", "Hint")
end)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	index.Visible = false
	shop.Visible = not shop.Visible
end)
