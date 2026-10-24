-- Dig to the Brainrot Core client: click blocks to mine, HUD, tool shop, fossil index, dynamite, sell.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
local ShopUI = require(ReplicatedStorage.Common.ShopUI)
local UI = require(ReplicatedStorage.Common.UI)

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local pit = workspace:WaitForChild("Pit")

local gui = UI.new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") }) :: ScreenGui
local toast = UI.CreateToaster(gui)
remotes:WaitForChild("Notify").OnClientEvent:Connect(toast)
local buy = ShopUI.Buyer(Config, toast)
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(55, 40, 30))

---------------------------------------------------------------- HUD

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(400, 80),
	BackgroundColor3 = Color3.fromRGB(45, 35, 25),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local coinsLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 42), Position = UDim2.fromOffset(5, 2), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = top })
local bagLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 28), Position = UDim2.fromOffset(5, 46), Parent = top })
local banner = UI.Label("", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 92), Size = UDim2.fromOffset(520, 28), TextColor3 = Color3.fromRGB(0, 255, 200), Parent = gui })
local hpLabel = UI.Label("", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(400, 32), Parent = gui })

local function refresh()
	coinsLabel.Text = "🪙 " .. Format.Abbreviate(player:GetAttribute("Coins") or 0) .. "   ⛏ depth " .. (player:GetAttribute("Depth") or 0)
	local count, cap = player:GetAttribute("BagCount") or 0, player:GetAttribute("BagCap") or Config.BaseBackpack
	bagLabel.Text = string.format("🎒 %d/%d  •  worth %s  •  🧨 %d  •  🦴 %d fossils", count, cap, Format.Abbreviate(player:GetAttribute("BagValue") or 0), player:GetAttribute("Dynamite") or 0, player:GetAttribute("FossilCount") or 0)
	bagLabel.TextColor3 = if count >= cap then Color3.fromRGB(255, 90, 90) else Color3.new(1, 1, 1)
end
player.AttributeChanged:Connect(refresh)
refresh()

task.spawn(function()
	while true do
		local parts = {}
		local drill = (player:GetAttribute("DrillUntil") or 0) - os.time()
		if drill > 0 then
			table.insert(parts, "MEGA DRILL " .. Format.Time(drill))
		end
		table.insert(parts, "Pit refills in " .. Format.Time((workspace:GetAttribute("PitResetAt") or 0) - os.time()))
		banner.Text = table.concat(parts, "  •  ")
		task.wait(1)
	end
end)

---------------------------------------------------------------- mining

local dynamiteMode = false
local holding = false
local selection = Instance.new("SelectionBox")
selection.LineThickness = 0.06
selection.Color3 = Color3.fromRGB(255, 255, 255)
selection.Parent = gui

local function targetBlock(): BasePart?
	mouse.TargetFilter = player.Character
	local t = mouse.Target
	if t and t.Parent == pit then
		return t
	end
	return nil
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		holding = true
		local block = targetBlock()
		if block and dynamiteMode then
			dynamiteMode = false
			remotes.Dynamite:FireServer(block)
		end
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		holding = false
	end
end)

local lastSwing = 0
RunService.RenderStepped:Connect(function()
	local block = targetBlock()
	selection.Adornee = block
	if block then
		local ore = Config.OreById[block:GetAttribute("Ore")]
		hpLabel.Text = (ore and ore.Name or "?") .. "  •  HP " .. math.ceil(block:GetAttribute("HP") or 0)
	else
		hpLabel.Text = if dynamiteMode then "Click a block to blow it up!" else ""
	end
	local pick = Config.PickaxeById[player:GetAttribute("Pickaxe") or "wood"] or Config.Pickaxes[1]
	if holding and block and not dynamiteMode and os.clock() - lastSwing >= 1 / pick.Speed then
		lastSwing = os.clock()
		remotes.Mine:FireServer(block)
	end
end)

---------------------------------------------------------------- tool shop + fossils

local function modal(title: string): (Frame, ScrollingFrame)
	local frame = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 540, 0.72, 0),
		BackgroundColor3 = Color3.fromRGB(55, 40, 30),
		Visible = false,
		Parent = gui,
	}, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
	UI.Label(title, { Size = UDim2.new(1, -80, 0, 50), Position = UDim2.fromOffset(16, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
	UI.Button("X", Color3.fromRGB(230, 60, 60), { Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -58, 0, 8), Parent = frame }).Activated:Connect(function()
		frame.Visible = false
	end)
	local list = UI.new("ScrollingFrame", { Position = UDim2.fromOffset(12, 64), Size = UDim2.new(1, -24, 1, -76), BackgroundTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 8, Parent = frame }) :: ScrollingFrame
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	return frame, list
end

local tools, toolList = modal("TOOL SHOP")
local toolButtons = {}
local order = 0
local function toolRow(kind: string, item, detail: string)
	order += 1
	local row = UI.new("Frame", { LayoutOrder = order, Size = UDim2.new(1, -10, 0, 66), BackgroundColor3 = Color3.fromRGB(80, 60, 45), Parent = toolList }, { UI.Corner(12) })
	UI.Label(item.Name, { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -150, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = item.Color or Color3.new(1, 1, 1), Parent = row })
	UI.Label(detail, { Position = UDim2.fromOffset(12, 36), Size = UDim2.new(1, -150, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, Parent = row })
	local b = UI.Button("", Color3.fromRGB(40, 180, 70), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(120, 48), Parent = row })
	b.Activated:Connect(function()
		local ok, msg = remotes.BuyTool:InvokeServer(kind, item.Id)
		toast(msg, if ok then Color3.fromRGB(120, 255, 120) else Color3.fromRGB(255, 90, 90))
	end)
	toolButtons[item.Id .. kind] = { Button = b, Item = item, Kind = kind }
end
for _, p in Config.Pickaxes do
	toolRow("Pickaxe", p, string.format("%d damage  •  %.1f hits/sec", p.Power, p.Speed))
end
for _, b in Config.Backpacks do
	toolRow("Backpack", b, b.Capacity .. " ores")
end
local function refreshTools()
	local owned = {}
	for id in string.gmatch(player:GetAttribute("OwnedTools") or "", "[^,]+") do
		owned[id] = true
	end
	for id, entry in toolButtons do
		local equipped = player:GetAttribute(entry.Kind) == entry.Item.Id
		entry.Button.Text = if equipped then "EQUIPPED" elseif owned[id] then "EQUIP" else "🪙 " .. Format.Abbreviate(entry.Item.Cost)
		entry.Button.BackgroundColor3 = if equipped then Color3.fromRGB(90, 90, 90) elseif owned[id] then Color3.fromRGB(40, 140, 230) else Color3.fromRGB(40, 180, 70)
	end
end
player.AttributeChanged:Connect(function(name)
	if name == "OwnedTools" or name == "Pickaxe" or name == "Backpack" then
		refreshTools()
	end
end)
refreshTools()

local fossilFrame, fossilList = modal("FOSSIL MUSEUM")
local fossils = {}
local function renderFossils()
	for _, c in fossilList:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for i, f in Config.Fossils do
		local count = fossils[f.Id]
		local row = UI.new("Frame", { LayoutOrder = i, Size = UDim2.new(1, -10, 0, 50), BackgroundColor3 = if count then Color3.fromRGB(90, 75, 50) else Color3.fromRGB(60, 50, 40), Parent = fossilList }, { UI.Corner(10) })
		UI.Label((if count then "🦴 " .. f.Name .. "  x" .. count else "❓ ???"), { Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
		UI.Label("Found below depth " .. f.MinDepth, { Position = UDim2.fromOffset(10, 28), Size = UDim2.new(1, -20, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(220, 210, 190), Parent = row })
	end
end
remotes:WaitForChild("Fossils").OnClientEvent:Connect(function(f)
	fossils = f
	if fossilFrame.Visible then
		renderFossils()
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Name == "ToolShopPrompt" then
		tools.Visible = true
	end
end)

local side = ShopUI.SideBar(gui)
local frames = { shop, tools, fossilFrame }
local function toggle(frame: Frame)
	for _, f in frames do
		if f ~= frame then
			f.Visible = false
		end
	end
	frame.Visible = not frame.Visible
end
UI.Button("TOOLS", Color3.fromRGB(150, 100, 60), { Size = UDim2.fromOffset(130, 50), Parent = side }).Activated:Connect(function()
	toggle(tools)
end)
UI.Button("SELL", Color3.fromRGB(40, 200, 80), { Size = UDim2.fromOffset(130, 50), Parent = side }).Activated:Connect(function()
	local ok, msg = remotes.Sell:InvokeServer()
	if msg == "NeedPass" then
		toast("Go to the surface Sell pad, or get Sell Anywhere!", Color3.fromRGB(255, 200, 0))
		buy("Pass", "SellAnywhere")
		return
	end
	toast(msg, if ok then Color3.fromRGB(120, 255, 120) else Color3.fromRGB(255, 90, 90))
end)
UI.Button("SURFACE", Color3.fromRGB(80, 160, 255), { Size = UDim2.fromOffset(130, 50), Parent = side }).Activated:Connect(function()
	remotes.Surface:FireServer()
end)
UI.Button("DYNAMITE", Color3.fromRGB(230, 60, 40), { Size = UDim2.fromOffset(130, 50), Parent = side }).Activated:Connect(function()
	if (player:GetAttribute("Dynamite") or 0) > 0 then
		dynamiteMode = true
		toast("Click a block to blow it up!", Color3.fromRGB(255, 160, 60))
	else
		buy("Product", "Dynamite")
	end
end)
UI.Button("FOSSILS", Color3.fromRGB(235, 220, 170), { Size = UDim2.fromOffset(130, 50), TextColor3 = Color3.fromRGB(60, 40, 20), Parent = side }).Activated:Connect(function()
	toggle(fossilFrame)
	if fossilFrame.Visible then
		renderFossils()
	end
end)
UI.Button("SHOP", Color3.fromRGB(40, 140, 230), { Size = UDim2.fromOffset(130, 50), Parent = side }).Activated:Connect(function()
	toggle(shop)
end)
