-- Merge Brainrots client: tap a brainrot, then tap another of the same level to merge.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
local ModelView = require(ReplicatedStorage.Common.ModelView)
local ShopUI = require(ReplicatedStorage.Common.ShopUI)
local UI = require(ReplicatedStorage.Common.UI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui = UI.new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") }) :: ScreenGui
local toast = UI.CreateToaster(gui)
remotes:WaitForChild("Notify").OnClientEvent:Connect(toast)
local buy = ShopUI.Buyer(Config, toast)
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(30, 45, 80))

---------------------------------------------------------------- top bar

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(340, 74),
	BackgroundColor3 = Color3.fromRGB(25, 30, 50),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local cashLabel = UI.Label("$0", { Size = UDim2.new(1, -10, 0, 42), Position = UDim2.fromOffset(5, 2), TextColor3 = Color3.fromRGB(120, 255, 120), Parent = top })
local incomeLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 24), Position = UDim2.fromOffset(5, 46), Parent = top })

---------------------------------------------------------------- board

local boardFrame = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.52),
	Size = UDim2.fromOffset(520, 510),
	BackgroundColor3 = Color3.fromRGB(30, 40, 70),
	BackgroundTransparency = 0.1,
	Parent = gui,
}, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) })
local scale = Instance.new("UIScale")
scale.Parent = boardFrame
local function rescale()
	local cam = workspace.CurrentCamera
	if cam then
		local vp = cam.ViewportSize
		scale.Scale = math.min(1, (vp.X - 40) / 520, (vp.Y - 200) / 510)
	end
end
rescale()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
end

local grid = UI.new("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 1, -20), BackgroundTransparency = 1, Parent = boardFrame })
local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.fromOffset(94, 74)
layout.CellPadding = UDim2.fromOffset(6, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = grid

local board = {}
local selected: number? = nil
local cells = {}
local TOTAL = Config.BaseSlots + Config.ExtraSlots

local function render()
	local unlocked = player:GetAttribute("Slots") or Config.BaseSlots
	for i = 1, TOTAL do
		local cell = cells[i]
		local level = board[i] or 0
		cell.Visible = i <= math.max(unlocked, Config.BaseSlots + Config.ExtraSlots)
		local locked = i > unlocked
		local stroke = cell:FindFirstChildOfClass("UIStroke") :: UIStroke
		stroke.Color = if selected == i then Color3.fromRGB(255, 255, 255) else Color3.new(0, 0, 0)
		stroke.Thickness = if selected == i then 4 else 2
		local nameLabel = cell:FindFirstChild("NameLabel") :: TextLabel
		local levelLabel = cell:FindFirstChild("LevelLabel") :: TextLabel
		if locked then
			cell.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			nameLabel.Text = "🔒"
			levelLabel.Text = "+10 Slots"
		elseif level == 0 then
			cell.BackgroundColor3 = Color3.fromRGB(45, 55, 85)
			nameLabel.Text = ""
			levelLabel.Text = ""
		else
			cell.BackgroundColor3 = Config.Color(level)
			nameLabel.Text = Config.Names[level]
			levelLabel.Text = "Lv" .. level .. "  " .. Format.Cash(Config.Income(level)) .. "/s"
		end
		-- 3D figure of the brainrot in the cell (rebuilt only when the level changes).
		local shown = if locked then 0 else level
		if cell:GetAttribute("FigureLevel") ~= shown then
			cell:SetAttribute("FigureLevel", shown)
			local old = cell:FindFirstChild("Figure")
			if old then
				old:Destroy()
			end
			if shown > 0 then
				local vp = ModelView.new(Config.Names[shown], { Name = "Figure", Size = UDim2.new(1, 0, 1, -20), ZIndex = 0 })
				if vp then
					vp.Parent = cell
				end
			end
		end
	end
end

for i = 1, TOTAL do
	local cell = UI.new("TextButton", {
		Text = "",
		LayoutOrder = i,
		AutoButtonColor = true,
		BackgroundColor3 = Color3.fromRGB(45, 55, 85),
		Parent = grid,
	}, { UI.Corner(10), UI.Stroke(Color3.new(0, 0, 0), 2) }) :: TextButton
	UI.Label("", { Name = "NameLabel", Position = UDim2.fromOffset(4, 2), Size = UDim2.new(1, -8, 0, 18), TextWrapped = true, ZIndex = 2, Parent = cell })
	UI.Label("", { Name = "LevelLabel", Position = UDim2.new(0, 4, 1, -20), Size = UDim2.new(1, -8, 0, 18), TextColor3 = Color3.fromRGB(255, 255, 210), ZIndex = 2, Parent = cell })
	cells[i] = cell
	cell.Activated:Connect(function()
		if i > (player:GetAttribute("Slots") or Config.BaseSlots) then
			buy("Pass", "MoreSlots")
			return
		end
		if selected == nil then
			if (board[i] or 0) > 0 then
				selected = i
				render()
			end
			return
		end
		local from = selected
		selected = nil
		if from ~= i then
			local ok, kind = remotes.Move:InvokeServer(from, i)
			if ok and kind == "merged" then
				local pop = cells[i]
				pop.Size = UDim2.fromOffset(110, 86)
				TweenService:Create(pop, TweenInfo.new(0.2), { Size = UDim2.fromOffset(94, 74) }):Play()
			end
		end
		render()
	end)
end

remotes:WaitForChild("Board").OnClientEvent:Connect(function(b)
	board = b
	render()
end)
player:GetAttributeChangedSignal("Slots"):Connect(render)

---------------------------------------------------------------- buttons

local buyButton = UI.Button("BUY", Color3.fromRGB(40, 180, 70), {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.fromOffset(300, 70),
	Parent = gui,
})
buyButton.Activated:Connect(function()
	local ok, msg = remotes.Buy:InvokeServer()
	if not ok then
		toast(msg, Color3.fromRGB(255, 90, 90))
	end
end)

local function refresh()
	cashLabel.Text = Format.Cash(player:GetAttribute("Cash") or 0)
	incomeLabel.Text = Format.Cash(player:GetAttribute("Income") or 0) .. "/s  •  Rebirths " .. (player:GetAttribute("Rebirths") or 0)
	local level = player:GetAttribute("BuyLevel") or 1
	buyButton.Text = "BUY Lv" .. level .. "  " .. Format.Cash(player:GetAttribute("BuyCost") or 0)
end
player.AttributeChanged:Connect(refresh)
refresh()

local side = ShopUI.SideBar(gui)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	shop.Visible = not shop.Visible
end)
UI.Button("REBIRTH", Color3.fromRGB(255, 170, 0), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	local ok, msg = remotes.Rebirth:InvokeServer()
	toast(msg, if ok then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(255, 90, 90))
end)
local autoButton = UI.Button("AUTO MERGE", Color3.fromRGB(150, 70, 255), { Size = UDim2.fromOffset(130, 54), Parent = side })
autoButton.Activated:Connect(function()
	if player:GetAttribute("Pass_AutoMerge") then
		remotes.ToggleAutoMerge:FireServer()
	else
		buy("Pass", "AutoMerge")
	end
end)
player:GetAttributeChangedSignal("AutoMergeOn"):Connect(function()
	autoButton.Text = if player:GetAttribute("AutoMergeOn") == false then "AUTO: OFF" else "AUTO MERGE"
end)
UI.Button("LEVEL UP ALL", Color3.fromRGB(255, 80, 160), { Size = UDim2.fromOffset(130, 54), Parent = side }).Activated:Connect(function()
	buy("Product", "LevelUp")
end)
