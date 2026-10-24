-- Grow a Brainrot client: HUD, seed hotbar, seed shop, selling, Robux shop, weather FX.
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
local UI = require(ReplicatedStorage.Common.UI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local testPurchase = ReplicatedStorage:WaitForChild("StudioTestPurchase")

local gui = UI.new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") }) :: ScreenGui
local toast = UI.CreateToaster(gui)
remotes:WaitForChild("Notify").OnClientEvent:Connect(toast)

local function buy(kind: string, key: string)
	local id = if kind == "Pass" then Config.Passes[key] else Config.Products[key]
	if id > 0 then
		if kind == "Pass" then
			MarketplaceService:PromptGamePassPurchase(player, id)
		else
			MarketplaceService:PromptProductPurchase(player, id)
		end
	elseif RunService:IsStudio() then
		testPurchase:FireServer(kind, key)
		toast("[Studio test] " .. key, Color3.fromRGB(255, 215, 0))
	else
		toast("Coming soon!", Color3.fromRGB(255, 90, 90))
	end
end

---------------------------------------------------------------- HUD

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(360, 80),
	BackgroundColor3 = Color3.fromRGB(40, 70, 30),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local cashLabel = UI.Label("$0", { Size = UDim2.new(1, -10, 0, 44), Position = UDim2.fromOffset(5, 2), TextColor3 = Color3.fromRGB(120, 255, 120), Parent = top })
local fruitLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 26), Position = UDim2.fromOffset(5, 48), Parent = top })
local banner = UI.Label("", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 92), Size = UDim2.fromOffset(560, 30), TextColor3 = Color3.fromRGB(160, 210, 255), Parent = gui })

local function refresh()
	cashLabel.Text = Format.Cash(player:GetAttribute("Cash") or 0)
	fruitLabel.Text = string.format(
		"🧺 %d/%d fruit  •  worth %s",
		player:GetAttribute("FruitCount") or 0,
		Config.FruitCap,
		Format.Cash(player:GetAttribute("FruitValue") or 0)
	)
end
player.AttributeChanged:Connect(refresh)
refresh()

---------------------------------------------------------------- seed hotbar

local hotbar = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -12),
	Size = UDim2.new(0.9, 0, 0, 84),
	BackgroundTransparency = 1,
	Parent = gui,
})
local hotLayout = Instance.new("UIListLayout")
hotLayout.FillDirection = Enum.FillDirection.Horizontal
hotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hotLayout.Padding = UDim.new(0, 6)
hotLayout.SortOrder = Enum.SortOrder.LayoutOrder
hotLayout.Parent = hotbar

local seeds = {}
local function renderHotbar()
	for _, c in hotbar:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local selected = player:GetAttribute("SelectedSeed")
	for i, seed in Config.Seeds do
		local count = seeds[seed.Id]
		if not count or count <= 0 then
			continue
		end
		local b = UI.new("TextButton", {
			Text = "",
			LayoutOrder = i,
			Size = UDim2.fromOffset(84, 84),
			BackgroundColor3 = Color3.fromRGB(40, 40, 50),
			Parent = hotbar,
		}, { UI.Corner(12), UI.Stroke(if selected == seed.Id then Color3.fromRGB(120, 255, 120) else Config.Rarities[seed.Rarity], if selected == seed.Id then 4 else 2) }) :: TextButton
		UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = seed.Color, Parent = b }, { UI.Corner(16) })
		UI.Label(seed.Name, { Position = UDim2.fromOffset(3, 40), Size = UDim2.new(1, -6, 0, 22), Parent = b })
		UI.Label("x" .. count, { Position = UDim2.fromOffset(3, 62), Size = UDim2.new(1, -6, 0, 18), TextColor3 = Color3.fromRGB(255, 230, 120), Parent = b })
		b.Activated:Connect(function()
			remotes.SelectSeed:FireServer(seed.Id)
		end)
	end
end
remotes:WaitForChild("Seeds").OnClientEvent:Connect(function(s)
	seeds = s
	renderHotbar()
end)
player:GetAttributeChangedSignal("SelectedSeed"):Connect(renderHotbar)

---------------------------------------------------------------- modals

local modals = {}
local function modal(title: string): (Frame, ScrollingFrame)
	local frame = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.new(0, 540, 0.68, 0),
		BackgroundColor3 = Color3.fromRGB(50, 70, 40),
		Visible = false,
		Parent = gui,
	}, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
	local c = Instance.new("UISizeConstraint")
	c.MaxSize = Vector2.new(math.huge, 560)
	c.Parent = frame
	UI.Label(title, { Name = "Title", Size = UDim2.new(1, -80, 0, 50), Position = UDim2.fromOffset(16, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
	UI.Button("X", Color3.fromRGB(230, 60, 60), { Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -58, 0, 8), Parent = frame }).Activated:Connect(function()
		frame.Visible = false
	end)
	local list = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 64),
		Size = UDim2.new(1, -24, 1, -76),
		BackgroundTransparency = 1,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 8,
		Parent = frame,
	}) :: ScrollingFrame
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	table.insert(modals, frame)
	return frame, list
end
local function open(frame: Frame)
	for _, m in modals do
		if m ~= frame then
			m.Visible = false
		end
	end
	frame.Visible = not frame.Visible
end

local function row(parent: Instance, order: number, name: string, desc: string, color: Color3): (Frame, TextButton)
	local r = UI.new("Frame", { Size = UDim2.new(1, -10, 0, 74), BackgroundColor3 = Color3.fromRGB(70, 95, 55), LayoutOrder = order, Parent = parent }, { UI.Corner(12) }) :: Frame
	UI.Label(name, { Name = "Name", Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -150, 0, 32), TextXAlignment = Enum.TextXAlignment.Left, Parent = r })
	UI.Label(desc, { Name = "Desc", Position = UDim2.fromOffset(12, 38), Size = UDim2.new(1, -150, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(220, 230, 210), Parent = r })
	local b = UI.Button("", color, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(120, 52), Parent = r })
	return r, b
end

-- Seed shop
local seedShop, seedList = modal("SEED SHOP")
local seedRows = {}
do
	local restockRow, restockButton = row(seedList, 0, "Restock in 5:00", "Restock the shop for the whole server", Color3.fromRGB(40, 140, 230))
	restockButton.Text = "R$ " .. Config.ProductInfo[1].Price
	restockButton.Activated:Connect(function()
		buy("Product", "Restock")
	end)
	seedRows.Restock = restockRow
	for i, seed in Config.Seeds do
		local r, b = row(seedList, i, seed.Name, seed.Rarity .. "  •  sells ~" .. Format.Cash(seed.Value) .. (if seed.Regrow then "  •  regrows" else ""), Color3.fromRGB(40, 180, 70))
		local nameLabel = r:FindFirstChild("Name") :: TextLabel
		nameLabel.TextColor3 = Config.Rarities[seed.Rarity]
		b.Text = Format.Cash(seed.Price)
		b.Activated:Connect(function()
			local ok, msg = remotes.BuySeed:InvokeServer(seed.Id)
			toast(msg, if ok then Color3.fromRGB(120, 255, 120) else Color3.fromRGB(255, 90, 90))
			if ok then
				task.spawn(function()
					local stock = remotes.GetShop:InvokeServer()
					for id, rr in seedRows do
						if id ~= "Restock" then
							rr.Stock(stock[id] or 0)
						end
					end
				end)
			end
		end)
		seedRows[seed.Id] = {
			Stock = function(n: number)
				b.Text = if n > 0 then Format.Cash(seed.Price) .. " (x" .. n .. ")" else "NO STOCK"
				b.BackgroundColor3 = if n > 0 then Color3.fromRGB(40, 180, 70) else Color3.fromRGB(90, 90, 90)
			end,
		}
	end
end
local function refreshShop()
	local stock = remotes.GetShop:InvokeServer()
	for id, r in seedRows do
		if id ~= "Restock" then
			r.Stock(stock[id] or 0)
		end
	end
end
workspace:GetAttributeChangedSignal("Rotation"):Connect(function()
	if seedShop.Visible then
		refreshShop()
	end
end)
local function openSeedShop()
	open(seedShop)
	if seedShop.Visible then
		refreshShop()
	end
end
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Name == "SeedShopPrompt" then
		openSeedShop()
	end
end)

-- Robux shop
local shop, shopList = modal("SHOP")
do
	local order = 0
	for _, info in Config.ProductInfo do
		order += 1
		local _, b = row(shopList, order, info.Name, info.Description, Color3.fromRGB(40, 140, 230))
		b.Text = "R$ " .. info.Price
		b.Activated:Connect(function()
			buy("Product", info.Key)
		end)
	end
	for _, info in Config.PassInfo do
		order += 1
		local _, b = row(shopList, order, info.Name, info.Description, Color3.fromRGB(40, 180, 70))
		b.Text = "R$ " .. info.Price
		local function owned()
			if player:GetAttribute("Pass_" .. info.Key) then
				b.Text = "OWNED"
				b.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
			end
		end
		player:GetAttributeChangedSignal("Pass_" .. info.Key):Connect(owned)
		owned()
		b.Activated:Connect(function()
			if not player:GetAttribute("Pass_" .. info.Key) then
				buy("Pass", info.Key)
			end
		end)
	end
end

-- Side buttons
local side = UI.new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.45, 0), Size = UDim2.fromOffset(130, 260), BackgroundTransparency = 1, Parent = gui })
local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 10)
sideLayout.Parent = side
UI.Button("SEEDS", Color3.fromRGB(80, 170, 60), { Size = UDim2.fromOffset(130, 56), Parent = side }).Activated:Connect(openSeedShop)
UI.Button("SELL", Color3.fromRGB(230, 170, 40), { Size = UDim2.fromOffset(130, 56), Parent = side }).Activated:Connect(function()
	local ok, msg = remotes.SellAll:InvokeServer()
	if msg == "NeedPass" then
		toast("Walk to the Sell Stand, or get Sell Anywhere!", Color3.fromRGB(255, 200, 0))
		buy("Pass", "SellAnywhere")
		return
	end
	toast(msg, if ok then Color3.fromRGB(120, 255, 120) else Color3.fromRGB(255, 90, 90))
end)
UI.Button("SHOP", Color3.fromRGB(40, 140, 230), { Size = UDim2.fromOffset(130, 56), Parent = side }).Activated:Connect(function()
	open(shop)
end)
UI.Button("GROW ALL", Color3.fromRGB(200, 60, 255), { Size = UDim2.fromOffset(130, 56), Parent = side }).Activated:Connect(function()
	buy("Product", "GrowAll")
end)

---------------------------------------------------------------- prompts, banner, weather FX

local rainPart = Instance.new("Part")
rainPart.Anchored = true
rainPart.CanCollide = false
rainPart.CanQuery = false
rainPart.CanTouch = false
rainPart.Transparency = 1
rainPart.Size = Vector3.new(120, 1, 120)
rainPart.Parent = workspace
local rain = Instance.new("ParticleEmitter")
rain.Texture = "rbxasset://textures/particles/sparkles_main.dds"
rain.Rate = 0
rain.Lifetime = NumberRange.new(1.5)
rain.Speed = NumberRange.new(60)
rain.EmissionDirection = Enum.NormalId.Bottom
rain.Size = NumberSequence.new(0.3)
rain.Parent = rainPart

RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	if cam then
		rainPart.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 50, 0))
	end
end)

task.spawn(function()
	while true do
		local now = os.time()
		local nextRestock = workspace:GetAttribute("NextRestock") or now
		local weather = workspace:GetAttribute("Weather")
		local active = (workspace:GetAttribute("WeatherUntil") or 0) > now and weather
		local parts = { "Restock " .. Format.Time(nextRestock - now) }
		if active then
			table.insert(parts, 1, Config.Weathers[weather].Name .. " " .. Format.Time(workspace:GetAttribute("WeatherUntil") - now))
		end
		banner.Text = table.concat(parts, "   •   ")
		local restockLabel = (seedRows.Restock :: Frame):FindFirstChild("Name") :: TextLabel
		restockLabel.Text = "Restock in " .. Format.Time(nextRestock - now)
		rain.Rate = if active then 400 else 0
		rain.Color = ColorSequence.new(if weather == "Brainrot" then Color3.fromRGB(200, 80, 255) else Color3.fromRGB(150, 190, 255))

		for _, soil in CollectionService:GetTagged("Soil") do
			local mine = soil:GetAttribute("OwnerId") == player.UserId
			local state = soil:GetAttribute("State") or "Empty"
			local plant = soil:FindFirstChild("PlantPrompt") :: ProximityPrompt?
			local harvest = soil:FindFirstChild("HarvestPrompt") :: ProximityPrompt?
			local shovel = soil:FindFirstChild("ShovelPrompt") :: ProximityPrompt?
			if plant then
				plant.Enabled = mine and state == "Empty"
				plant.ObjectText = if soil:GetAttribute("Locked") then "🔒 Locked" else ""
			end
			if harvest then
				harvest.Enabled = mine and state == "Ready"
			end
			if shovel then
				shovel.Enabled = mine and state ~= "Empty"
			end
		end
		task.wait(0.3)
	end
end)
