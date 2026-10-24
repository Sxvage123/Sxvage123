-- Hatch a Brainrot client: click button, hatching, pet inventory, shop, followers.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local BrainrotModels = require(ReplicatedStorage.Common.BrainrotModels)
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
		toast("[Studio test] granted " .. key, Color3.fromRGB(255, 215, 0))
	else
		toast("Coming soon!", Color3.fromRGB(255, 90, 90))
	end
end

---------------------------------------------------------------- top HUD

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(340, 80),
	BackgroundColor3 = Color3.fromRGB(40, 20, 60),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local powerLabel = UI.Label("0", { Size = UDim2.new(1, -10, 0, 44), Position = UDim2.fromOffset(5, 2), TextColor3 = Color3.fromRGB(255, 120, 255), Parent = top })
local perClick = UI.Label("+1 per click", { Size = UDim2.new(1, -10, 0, 26), Position = UDim2.fromOffset(5, 48), TextColor3 = Color3.fromRGB(230, 230, 230), Parent = top })
local banner = UI.Label("", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 92), Size = UDim2.fromOffset(500, 30), TextColor3 = Color3.fromRGB(0, 255, 200), Parent = gui })

local function refresh()
	powerLabel.Text = "🧠 " .. Format.Abbreviate(player:GetAttribute("Brainpower") or 0)
	perClick.Text = "+" .. Format.Abbreviate(player:GetAttribute("ClickPower") or 1) .. " per click  •  Rebirths " .. (player:GetAttribute("Rebirths") or 0)
end
player.AttributeChanged:Connect(refresh)
refresh()

---------------------------------------------------------------- clicking

local clickRemote = remotes:WaitForChild("Click")
local clickButton = UI.Button("CLICK!", Color3.fromRGB(255, 80, 200), {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -20),
	Size = UDim2.fromOffset(200, 80),
	Parent = gui,
})
local lastClick = 0
local function doClick()
	local now = os.clock()
	if now - lastClick < 1 / Config.MaxClicksPerSecond then
		return
	end
	lastClick = now
	clickRemote:FireServer()
	local pop = UI.Label("+" .. Format.Abbreviate(player:GetAttribute("ClickPower") or 1), {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, math.random(-120, 120), 1, -130),
		Size = UDim2.fromOffset(160, 40),
		TextColor3 = Color3.fromRGB(255, 160, 255),
		Parent = gui,
	})
	TweenService:Create(pop, TweenInfo.new(0.8), { Position = pop.Position - UDim2.fromOffset(0, 120), TextTransparency = 1 }):Play()
	task.delay(0.8, pop.Destroy, pop)
	clickButton.Size = UDim2.fromOffset(190, 74)
	TweenService:Create(clickButton, TweenInfo.new(0.1), { Size = UDim2.fromOffset(200, 80) }):Play()
end
clickButton.Activated:Connect(doClick)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		doClick()
	end
end)

---------------------------------------------------------------- modals

local function modal(title: string): (Frame, ScrollingFrame)
	local frame = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 560, 0.72, 0),
		BackgroundColor3 = Color3.fromRGB(45, 30, 70),
		Visible = false,
		Parent = gui,
	}, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
	local c = Instance.new("UISizeConstraint")
	c.MaxSize = Vector2.new(math.huge, 580)
	c.Parent = frame
	UI.Label(title, { Size = UDim2.new(1, -80, 0, 50), Position = UDim2.fromOffset(16, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
	local close = UI.Button("X", Color3.fromRGB(230, 60, 60), { Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -58, 0, 8), Parent = frame })
	close.Activated:Connect(function()
		frame.Visible = false
	end)
	local list = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 64),
		Size = UDim2.new(1, -24, 1, -76),
		BackgroundTransparency = 1,
		ScrollBarThickness = 8,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = frame,
	}) :: ScrollingFrame
	return frame, list
end

local modals = {}
local function toggle(frame: Frame)
	for _, m in modals do
		if m ~= frame then
			m.Visible = false
		end
	end
	frame.Visible = not frame.Visible
end

-- Shop
local shop, shopList = modal("SHOP")
table.insert(modals, shop)
do
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = shopList
	local order = 0
	local function item(info, kind)
		order += 1
		local row = UI.new("Frame", { Size = UDim2.new(1, -10, 0, 74), BackgroundColor3 = Color3.fromRGB(70, 50, 100), LayoutOrder = order, Parent = shopList }, { UI.Corner(12) })
		UI.Label(info.Name, { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -150, 0, 32), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
		UI.Label(info.Description, { Position = UDim2.fromOffset(12, 38), Size = UDim2.new(1, -150, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(210, 200, 230), Parent = row })
		local b = UI.Button("R$ " .. info.Price, if kind == "Pass" then Color3.fromRGB(40, 180, 70) else Color3.fromRGB(40, 140, 230), {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(120, 52),
			Parent = row,
		})
		if kind == "Pass" then
			local function owned()
				if player:GetAttribute("Pass_" .. info.Key) then
					b.Text = "OWNED"
					b.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
				end
			end
			player:GetAttributeChangedSignal("Pass_" .. info.Key):Connect(owned)
			owned()
		end
		b.Activated:Connect(function()
			if kind == "Pass" and player:GetAttribute("Pass_" .. info.Key) then
				return
			end
			buy(kind, info.Key)
		end)
	end
	for _, info in Config.PassInfo do
		item(info, "Pass")
	end
	for _, info in Config.ProductInfo do
		item(info, "Product")
	end
end

-- Rebirth
local rebirthFrame, rebirthList = modal("REBIRTH")
table.insert(modals, rebirthFrame)
local rebirthText = UI.Label("", { Size = UDim2.new(1, 0, 0, 120), TextWrapped = true, Parent = rebirthList })
local rebirthButton = UI.Button("REBIRTH!", Color3.fromRGB(255, 170, 0), { Position = UDim2.fromOffset(0, 130), Size = UDim2.new(1, -10, 0, 64), Parent = rebirthList })
local function refreshRebirth()
	local r = player:GetAttribute("Rebirths") or 0
	rebirthText.Text = "Cost: " .. Format.Abbreviate(Config.RebirthCost(r)) .. " Brainpower\nReward: " .. (1 + (r + 1) * Config.RebirthBonus) .. "x Brainpower forever\nKeeps your pets!"
end
player:GetAttributeChangedSignal("Rebirths"):Connect(refreshRebirth)
refreshRebirth()
rebirthButton.Activated:Connect(function()
	local ok, msg = remotes.Rebirth:InvokeServer()
	toast(msg, if ok then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(255, 90, 90))
end)

-- Pets inventory
local petsFrame, petGrid = modal("PETS")
table.insert(modals, petsFrame)
petGrid.Position = UDim2.fromOffset(12, 124)
petGrid.Size = UDim2.new(1, -24, 1, -136)
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(120, 120)
grid.CellPadding = UDim2.fromOffset(8, 8)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = petGrid
local countLabel = UI.Label("0/60", { Position = UDim2.new(1, -200, 0, 10), Size = UDim2.fromOffset(130, 40), Parent = petsFrame })
local bar = UI.new("Frame", { Position = UDim2.fromOffset(12, 64), Size = UDim2.new(1, -24, 0, 52), BackgroundTransparency = 1, Parent = petsFrame })
local barLayout = Instance.new("UIListLayout")
barLayout.FillDirection = Enum.FillDirection.Horizontal
barLayout.Padding = UDim.new(0, 8)
barLayout.Parent = bar
local equipBestButton = UI.Button("Equip Best", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(160, 50), Parent = bar })
local autoButton = UI.Button("Auto: ON", Color3.fromRGB(40, 140, 230), { Size = UDim2.fromOffset(160, 50), Parent = bar })
local deleteButton = UI.Button("Delete: OFF", Color3.fromRGB(150, 60, 60), { Size = UDim2.fromOffset(170, 50), Parent = bar })

local inventory = {}
local deleteMode = false
local autoEquip = true

local function renderInventory()
	for _, child in petGrid:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local list = {}
	for uid, pet in inventory do
		local info = Config.PetById[pet.Id]
		if info then
			table.insert(list, { uid = uid, pet = pet, info = info })
		end
	end
	table.sort(list, function(a, b)
		if a.pet.Equipped ~= b.pet.Equipped then
			return a.pet.Equipped
		end
		return a.info.Multiplier > b.info.Multiplier
	end)
	countLabel.Text = #list .. "/" .. (player:GetAttribute("StorageLimit") or Config.BaseStorage)
	for i, entry in list do
		local color = Config.Rarities[entry.info.Rarity]
		local card = UI.new("TextButton", {
			Text = "",
			LayoutOrder = i,
			BackgroundColor3 = color:Lerp(Color3.new(0, 0, 0), 0.55),
			AutoButtonColor = true,
			Parent = petGrid,
		}, { UI.Corner(12), UI.Stroke(if entry.pet.Equipped then Color3.fromRGB(90, 255, 90) else color, if entry.pet.Equipped then 4 else 2) }) :: TextButton
		UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 8),
			Size = UDim2.fromOffset(44, 44),
			BackgroundColor3 = entry.info.Color,
			Parent = card,
		}, { UI.Corner(22), UI.Stroke(Color3.new(0, 0, 0), 2) })
		UI.Label(entry.info.Name, { Position = UDim2.fromOffset(4, 56), Size = UDim2.new(1, -8, 0, 22), Parent = card })
		UI.Label("x" .. Format.Abbreviate(entry.info.Multiplier), { Position = UDim2.fromOffset(4, 78), Size = UDim2.new(1, -8, 0, 20), TextColor3 = Color3.fromRGB(255, 160, 255), Parent = card })
		UI.Label(entry.info.Rarity, { Position = UDim2.fromOffset(4, 98), Size = UDim2.new(1, -8, 0, 16), TextColor3 = color, Parent = card })
		card.Activated:Connect(function()
			if deleteMode then
				remotes.Delete:InvokeServer({ entry.uid })
			else
				remotes.Equip:InvokeServer(entry.uid, not entry.pet.Equipped)
			end
		end)
	end
end

remotes:WaitForChild("Inventory").OnClientEvent:Connect(function(pets)
	inventory = pets
	renderInventory()
end)
equipBestButton.Activated:Connect(function()
	remotes.Equip:InvokeServer("BEST")
end)
autoButton.Activated:Connect(function()
	autoEquip = not autoEquip
	autoButton.Text = if autoEquip then "Auto: ON" else "Auto: OFF"
	remotes.Equip:InvokeServer("AUTO", autoEquip)
end)
deleteButton.Activated:Connect(function()
	deleteMode = not deleteMode
	deleteButton.Text = if deleteMode then "Delete: ON" else "Delete: OFF"
	deleteButton.BackgroundColor3 = if deleteMode then Color3.fromRGB(230, 40, 40) else Color3.fromRGB(150, 60, 60)
end)

---------------------------------------------------------------- side buttons + gift

local side = UI.new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(130, 300), BackgroundTransparency = 1, Parent = gui })
local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 10)
sideLayout.Parent = side
UI.Button("PETS", Color3.fromRGB(255, 120, 40), { Size = UDim2.fromOffset(130, 56), Parent = side }).Activated:Connect(function()
	toggle(petsFrame)
end)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 56), Parent = side }).Activated:Connect(function()
	toggle(shop)
end)
UI.Button("REBIRTH", Color3.fromRGB(255, 170, 0), { Size = UDim2.fromOffset(130, 56), Parent = side }).Activated:Connect(function()
	toggle(rebirthFrame)
end)
local giftButton = UI.Button("GIFT", Color3.fromRGB(200, 60, 255), { Size = UDim2.fromOffset(130, 56), Parent = side })
giftButton.Activated:Connect(function()
	local ok, msg = remotes.ClaimGift:InvokeServer()
	toast(msg, if ok then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(255, 90, 90))
end)

task.spawn(function()
	while true do
		local now = os.time()
		local nextGift = player:GetAttribute("NextGift") or 0
		giftButton.Text = if nextGift <= now then "GIFT READY!" else "Gift " .. Format.Time(nextGift - now)
		local boost = player:GetAttribute("BoostUntil") or 0
		local l = player:GetAttribute("Luck") or 1
		banner.Text = if boost > now then string.format("%gx LUCK  %s", l, Format.Time(boost - now)) else ""
		task.wait(0.5)
	end
end)

---------------------------------------------------------------- hatching

local hatchFrame = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.45),
	Size = UDim2.fromOffset(600, 260),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = gui,
})
local hatchLayout = Instance.new("UIListLayout")
hatchLayout.FillDirection = Enum.FillDirection.Horizontal
hatchLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hatchLayout.Padding = UDim.new(0, 16)
hatchLayout.Parent = hatchFrame

local hatching = false
local function playHatch(eggId: string, results: { string })
	hatching = true
	for _, c in hatchFrame:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	hatchFrame.Visible = true
	local egg = Config.EggById[eggId]
	local eggs = {}
	for _ = 1, #results do
		local e = UI.new("Frame", { Size = UDim2.fromOffset(170, 220), BackgroundColor3 = egg.Color }, { UI.Corner(85), UI.Stroke(Color3.new(0, 0, 0), 4) })
		e.Parent = hatchFrame
		table.insert(eggs, e)
	end
	for i = 1, 8 do
		for _, e in eggs do
			e.Rotation = if i % 2 == 0 then 12 else -12
		end
		task.wait(0.09 + i * 0.01)
	end
	for i, e in eggs do
		local info = Config.PetById[results[i]]
		local color = Config.Rarities[info.Rarity]
		e.Rotation = 0
		e.BackgroundColor3 = info.Color
		UI.Label(info.Rarity, { Position = UDim2.fromOffset(5, 40), Size = UDim2.new(1, -10, 0, 34), TextColor3 = color, Parent = e })
		UI.Label(info.Name, { Position = UDim2.fromOffset(5, 80), Size = UDim2.new(1, -10, 0, 50), TextWrapped = true, Parent = e })
		UI.Label("x" .. Format.Abbreviate(info.Multiplier), { Position = UDim2.fromOffset(5, 140), Size = UDim2.new(1, -10, 0, 34), TextColor3 = Color3.fromRGB(255, 160, 255), Parent = e })
	end
	task.wait(1.6)
	hatchFrame.Visible = false
	hatching = false
end

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local count = prompt:GetAttribute("Count")
	local stand = prompt:FindFirstAncestorOfClass("Model")
	local eggId = stand and stand:GetAttribute("EggId")
	if not count or not eggId or hatching then
		return
	end
	local ok, result = remotes.Hatch:InvokeServer(eggId, count)
	if ok then
		playHatch(eggId, result)
	elseif result == "NeedTriple" then
		buy("Pass", "TripleHatch")
	else
		toast(result, Color3.fromRGB(255, 90, 90))
	end
end)

---------------------------------------------------------------- pet followers (all players, client-side)

local followers: { [Player]: { key: string, parts: { BasePart } } } = {}

local VARIANT_TINTS = {
	golden = Color3.fromRGB(255, 205, 40),
	rainbow = Color3.fromRGB(255, 80, 255),
	void = Color3.fromRGB(40, 0, 80),
}
local followFolder = Instance.new("Folder")
followFolder.Name = "PetFollowers"
followFolder.Parent = workspace

local function makePet(info): BasePart
	local rank = Config.RarityRank(info.Rarity)
	if BrainrotModels.Has(info.Id) then
		-- Real character model, scaled down. Moving its anchored Root moves the welded figure.
		local prefix = string.match(info.Id, "^(%a+)_")
		local model, root = BrainrotModels.Build(info.Id, { Scale = 0.3 + rank * 0.02, Tint = prefix and VARIANT_TINTS[prefix] })
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.CanQuery = false
			end
		end
		if rank >= 5 then
			local sparkle = Instance.new("ParticleEmitter")
			sparkle.Color = ColorSequence.new(Config.Rarities[info.Rarity])
			sparkle.LightEmission = 1
			sparkle.Size = NumberSequence.new(0.25, 0)
			sparkle.Rate = 8
			sparkle.Lifetime = NumberRange.new(0.6)
			sparkle.Speed = NumberRange.new(1)
			sparkle.Parent = root
		end
		model.Parent = followFolder
		return root
	end
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.one * (1.6 + rank * 0.2)
	p.Color = info.Color
	p.Material = if rank >= 6 then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	for _, side in { -1, 1 } do
		local eye = Instance.new("Part")
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.one * 0.5
		eye.Color = Color3.new(0, 0, 0)
		eye.Anchored = false
		eye.CanCollide = false
		eye.CanQuery = false
		eye.Massless = true
		eye.CFrame = p.CFrame * CFrame.new(side * p.Size.X * 0.2, p.Size.Y * 0.15, -p.Size.Z * 0.45)
		local w = Instance.new("WeldConstraint")
		w.Part0 = p
		w.Part1 = eye
		w.Parent = eye
		eye.Parent = p
	end
	if rank >= 5 then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Color = ColorSequence.new(Config.Rarities[info.Rarity])
		sparkle.LightEmission = 1
		sparkle.Size = NumberSequence.new(0.25, 0)
		sparkle.Rate = 8
		sparkle.Lifetime = NumberRange.new(0.6)
		sparkle.Speed = NumberRange.new(1)
		sparkle.Parent = p
	end
	p.Parent = followFolder
	return p
end

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, plr in Players:GetPlayers() do
		local key = plr:GetAttribute("Equipped") or ""
		local entry = followers[plr]
		if not entry or entry.key ~= key then
			if entry then
				for _, p in entry.parts do
					(if p.Parent and p.Parent:IsA("Model") then p.Parent else p):Destroy()
				end
			end
			entry = { key = key, parts = {} }
			for id in string.gmatch(key, "[^,]+") do
				local info = Config.PetById[id]
				if info then
					table.insert(entry.parts, makePet(info))
				end
			end
			followers[plr] = entry
		end
		local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local n = #entry.parts
			for i, p in entry.parts do
				local angle = math.pi + (i - (n + 1) / 2) * 0.55
				local offset = Vector3.new(math.sin(angle) * 6, 0, -math.cos(angle) * 6)
				local target = root.CFrame * CFrame.new(offset) + Vector3.new(0, math.sin(t * 4 + i) * 0.4 - 1, 0)
				p.CFrame = p.CFrame:Lerp(CFrame.lookAt(target.Position, target.Position + root.CFrame.LookVector), 0.2)
			end
		end
	end
	for plr, entry in followers do
		if not plr.Parent then
			for _, p in entry.parts do
				(if p.Parent and p.Parent:IsA("Model") then p.Parent else p):Destroy()
			end
			followers[plr] = nil
		end
	end
end)
