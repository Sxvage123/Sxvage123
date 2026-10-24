-- Pet Breakers client: click breakables to send pets, pet followers, coin pops, hatching, inventory, shop.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local BrainrotModels = require(ReplicatedStorage.Common.BrainrotModels)
local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
local ModelView = require(ReplicatedStorage.Common.ModelView)
local ShopUI = require(ReplicatedStorage.Common.ShopUI)
local UI = require(ReplicatedStorage.Common.UI)

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local breakFolder = workspace:WaitForChild("Breakables")

local gui = UI.new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") }) :: ScreenGui
local toast = UI.CreateToaster(gui)
remotes:WaitForChild("Notify").OnClientEvent:Connect(toast)
local buy = ShopUI.Buyer(Config, toast)
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(30, 45, 70))

---------------------------------------------------------------- HUD

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(360, 76),
	BackgroundColor3 = Color3.fromRGB(25, 35, 55),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local coinsLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 42), Position = UDim2.fromOffset(5, 2), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = top })
local powerLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 26), Position = UDim2.fromOffset(5, 46), Parent = top })
local banner = UI.Label("", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 88), Size = UDim2.fromOffset(520, 28), TextColor3 = Color3.fromRGB(0, 255, 200), Parent = gui })
local function refresh()
	coinsLabel.Text = "🪙 " .. Format.Abbreviate(player:GetAttribute("Coins") or 0)
	powerLabel.Text = "⚡ " .. Format.Abbreviate(player:GetAttribute("Power") or 0) .. " pet power  •  click coins & chests!"
end
player.AttributeChanged:Connect(refresh)
refresh()
task.spawn(function()
	while true do
		local now = os.time()
		local parts = {}
		local luck = (workspace:GetAttribute("ServerLuckUntil") or 0) - now
		local coins = (workspace:GetAttribute("ServerCoinsUntil") or 0) - now
		if luck > 0 then
			table.insert(parts, "2x LUCK " .. Format.Time(luck))
		end
		if coins > 0 then
			table.insert(parts, "2x COINS " .. Format.Time(coins))
		end
		banner.Text = table.concat(parts, "  •  ")
		task.wait(1)
	end
end)

---------------------------------------------------------------- targeting + coin pops

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local t = mouse.Target
		while t and t.Parent ~= breakFolder and t.Parent ~= workspace do
			t = t.Parent :: any
		end
		if t and t.Parent == breakFolder then
			remotes.Target:FireServer(t)
		end
	end
end)

remotes:WaitForChild("CoinPop").OnClientEvent:Connect(function(position: Vector3, amount: number)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position
	anchor.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(160, 40)
	bb.AlwaysOnTop = true
	bb.Parent = anchor
	local label = UI.Label("+" .. Format.Abbreviate(amount) .. " 🪙", { Size = UDim2.fromScale(1, 1), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = bb })
	TweenService:Create(anchor, TweenInfo.new(1), { Position = position + Vector3.new(0, 6, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(1), { TextTransparency = 1 }):Play()
	task.delay(1.05, anchor.Destroy, anchor)
end)

---------------------------------------------------------------- pet followers (every player)

local followFolder = Instance.new("Folder")
followFolder.Name = "PetFollowers"
followFolder.Parent = workspace
local followers: { [Player]: { key: string, roots: { BasePart } } } = {}

local function buildPet(spec: string): BasePart?
	local id, variant, huge = string.match(spec, "^([%w_]+):(%a+):(%d)$")
	if not id or not BrainrotModels.Has(id) then
		return nil
	end
	local v = Config.Variants[variant or "normal"] or Config.Variants.normal
	local model, root = BrainrotModels.Build(id, { Scale = if huge == "1" then 1.3 else 0.5, Tint = v.Tint, Neon = variant == "rainbow" })
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanQuery = false
		end
	end
	model.Parent = followFolder
	return root
end

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, plr in Players:GetPlayers() do
		local key = plr:GetAttribute("Equipped") or ""
		local entry = followers[plr]
		if not entry or entry.key ~= key then
			if entry then
				for _, r in entry.roots do
					(r.Parent :: Instance):Destroy()
				end
			end
			entry = { key = key, roots = {} }
			for spec in string.gmatch(key, "[^,]+") do
				local root = buildPet(spec)
				if root then
					table.insert(entry.roots, root)
				end
			end
			followers[plr] = entry
		end
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			local targetPos = plr:GetAttribute("TargetPos") :: Vector3?
			local n = #entry.roots
			for i, root in entry.roots do
				local goal: CFrame
				local lift = (root.Parent :: Model):GetAttribute("RootHeight") or 1
				if targetPos then
					-- swarm the breakable, hopping as they "attack"
					local a = i / math.max(n, 1) * math.pi * 2 + t * 0.8
					local pos = Vector3.new(targetPos.X + math.cos(a) * 4, targetPos.Y - 1 + lift + math.abs(math.sin(t * 8 + i)) * 1.2, targetPos.Z + math.sin(a) * 4)
					goal = CFrame.lookAt(pos, Vector3.new(targetPos.X, pos.Y, targetPos.Z))
				else
					local angle = math.pi + (i - (n + 1) / 2) * 0.6
					local offset = Vector3.new(math.sin(angle) * 6, 0, -math.cos(angle) * 6)
					local pos = (hrp.CFrame * CFrame.new(offset)).Position
					pos = Vector3.new(pos.X, hrp.Position.Y - 3 + lift + math.abs(math.sin(t * 6 + i)) * 0.4, pos.Z)
					goal = CFrame.lookAt(pos, pos + hrp.CFrame.LookVector)
				end
				root.CFrame = root.CFrame:Lerp(goal, 0.18)
			end
		end
	end
	for plr, entry in followers do
		if not plr.Parent then
			for _, r in entry.roots do
				(r.Parent :: Instance):Destroy()
			end
			followers[plr] = nil
		end
	end
end)

---------------------------------------------------------------- hatching

local hatchFrame = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(620, 260), BackgroundTransparency = 1, Visible = false, Parent = gui })
local hatchLayout = Instance.new("UIListLayout")
hatchLayout.FillDirection = Enum.FillDirection.Horizontal
hatchLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hatchLayout.Padding = UDim.new(0, 14)
hatchLayout.Parent = hatchFrame
local hatching = false

local function petTitle(pet): string
	local info = Config.PetById[pet.Id]
	return (if pet.Huge then "HUGE " else "") .. (if pet.V == "golden" then "Golden " elseif pet.V == "rainbow" then "Rainbow " else "") .. info.Name
end

local function playHatch(results)
	hatching = true
	for _, c in hatchFrame:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	hatchFrame.Visible = true
	local cards = {}
	for _ = 1, #results do
		local card = UI.new("Frame", { Size = UDim2.fromOffset(180, 240), BackgroundColor3 = Color3.fromRGB(255, 245, 220), Parent = hatchFrame }, { UI.Corner(90), UI.Stroke(Color3.new(0, 0, 0), 4) })
		table.insert(cards, card)
	end
	for i = 1, 9 do
		for _, c in cards do
			c.Rotation = if i % 2 == 0 then 10 else -10
		end
		task.wait(0.08 + i * 0.01)
	end
	for i, c in cards do
		local pet = results[i]
		local info = Config.PetById[pet.Id]
		c.Rotation = 0
		c.BackgroundColor3 = Config.Rarities[info.Rarity]:Lerp(Color3.new(0, 0, 0), 0.45)
		local v = Config.Variants[pet.V or "normal"]
		local figure = ModelView.new(pet.Id, { Position = UDim2.fromOffset(10, 30), Size = UDim2.new(1, -20, 0, 130) }, v and v.Tint)
		if figure then
			figure.Parent = c
		end
		UI.Label(petTitle(pet), { Position = UDim2.fromOffset(6, 166), Size = UDim2.new(1, -12, 0, 36), TextWrapped = true, Parent = c })
		UI.Label(info.Rarity .. "  •  ⚡" .. Format.Abbreviate(Config.PetPower(pet)), { Position = UDim2.fromOffset(6, 204), Size = UDim2.new(1, -12, 0, 24), TextColor3 = Config.Rarities[info.Rarity], Parent = c })
	end
	task.wait(2)
	hatchFrame.Visible = false
	hatching = false
end

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local count = prompt:GetAttribute("Count")
	local area = prompt:GetAttribute("Area")
	if not count or not area or hatching then
		return
	end
	local ok, result = remotes.Hatch:InvokeServer(area, count)
	if ok then
		playHatch(result)
	elseif result == "NeedTriple" then
		buy("Pass", "TripleHatch")
	else
		toast(result, Color3.fromRGB(255, 90, 90))
	end
end)

---------------------------------------------------------------- inventory

local inv = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 580, 0.74, 0),
	BackgroundColor3 = Color3.fromRGB(30, 45, 70),
	Visible = false,
	Parent = gui,
}, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
UI.Label("PETS", { Size = UDim2.new(0, 200, 0, 50), Position = UDim2.fromOffset(16, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = inv })
UI.Button("X", Color3.fromRGB(230, 60, 60), { Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -58, 0, 8), Parent = inv }).Activated:Connect(function()
	inv.Visible = false
end)
UI.Button("Equip Best", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(150, 46), Position = UDim2.new(1, -220, 0, 10), Parent = inv }).Activated:Connect(function()
	remotes.Equip:InvokeServer("BEST")
end)
local deleteMode = false
local deleteButton = UI.Button("Delete: OFF", Color3.fromRGB(150, 60, 60), { Size = UDim2.fromOffset(150, 46), Position = UDim2.new(1, -380, 0, 10), Parent = inv })
deleteButton.Activated:Connect(function()
	deleteMode = not deleteMode
	deleteButton.Text = if deleteMode then "Delete: ON" else "Delete: OFF"
end)
local grid = UI.new("ScrollingFrame", { Position = UDim2.fromOffset(12, 66), Size = UDim2.new(1, -24, 1, -78), BackgroundTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 8, Parent = inv })
local gl = Instance.new("UIGridLayout")
gl.CellSize = UDim2.fromOffset(124, 140)
gl.CellPadding = UDim2.fromOffset(8, 8)
gl.SortOrder = Enum.SortOrder.LayoutOrder
gl.Parent = grid

local pets = {}
local function renderInventory()
	for _, c in grid:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local list = {}
	for uid, pet in pets do
		if Config.PetById[pet.Id] then
			table.insert(list, { uid = uid, pet = pet, power = Config.PetPower(pet) })
		end
	end
	table.sort(list, function(a, b)
		if (a.pet.Eq or false) ~= (b.pet.Eq or false) then
			return a.pet.Eq == true
		end
		return a.power > b.power
	end)
	for i, e in list do
		local info = Config.PetById[e.pet.Id]
		local color = Config.Rarities[info.Rarity]
		local card = UI.new("TextButton", { Text = "", LayoutOrder = i, BackgroundColor3 = color:Lerp(Color3.new(0, 0, 0), 0.55), Parent = grid }, { UI.Corner(12), UI.Stroke(if e.pet.Eq then Color3.fromRGB(90, 255, 90) else color, if e.pet.Eq then 4 else 2) }) :: TextButton
		local v = Config.Variants[e.pet.V or "normal"]
		local figure = ModelView.new(e.pet.Id, { Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, 80) }, v and v.Tint)
		if figure then
			figure.Parent = card
		end
		UI.Label(petTitle(e.pet), { Position = UDim2.fromOffset(4, 86), Size = UDim2.new(1, -8, 0, 28), TextWrapped = true, Parent = card })
		UI.Label("⚡" .. Format.Abbreviate(e.power), { Position = UDim2.fromOffset(4, 114), Size = UDim2.new(1, -8, 0, 20), TextColor3 = Color3.fromRGB(255, 230, 120), Parent = card })
		card.Activated:Connect(function()
			if deleteMode then
				remotes.Delete:InvokeServer(e.uid)
			else
				local ok, msg = remotes.Equip:InvokeServer(e.uid, not e.pet.Eq)
				if not ok and msg then
					toast(msg, Color3.fromRGB(255, 90, 90))
				end
			end
		end)
	end
end
remotes:WaitForChild("Inventory").OnClientEvent:Connect(function(p)
	pets = p
	if inv.Visible then
		renderInventory()
	end
end)

local side = ShopUI.SideBar(gui)
UI.Button("PETS", Color3.fromRGB(255, 130, 40), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	shop.Visible = false
	inv.Visible = not inv.Visible
	if inv.Visible then
		renderInventory()
	end
end)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 52), Parent = side }).Activated:Connect(function()
	inv.Visible = false
	shop.Visible = not shop.Visible
end)
local autoButton = UI.Button("AUTO FARM", Color3.fromRGB(150, 70, 255), { Size = UDim2.fromOffset(130, 52), Parent = side })
autoButton.Activated:Connect(function()
	if player:GetAttribute("Pass_AutoFarm") then
		remotes.ToggleAutoFarm:FireServer()
	else
		buy("Pass", "AutoFarm")
	end
end)
player:GetAttributeChangedSignal("AutoFarmOn"):Connect(function()
	autoButton.Text = if player:GetAttribute("AutoFarmOn") == false then "AUTO: OFF" else "AUTO FARM"
end)
UI.Button("EXCLUSIVE EGG", Color3.fromRGB(255, 200, 0), { Size = UDim2.fromOffset(130, 52), TextColor3 = Color3.fromRGB(60, 30, 0), Parent = side }).Activated:Connect(function()
	buy("Product", "ExclusiveEgg")
end)
