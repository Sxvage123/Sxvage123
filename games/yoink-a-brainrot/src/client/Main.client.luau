-- Yoink a Brainrot client: HUD, shop, rebirth menu, notifications, prompt filtering.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
local UI = require(ReplicatedStorage.Common.UI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local testPurchase = ReplicatedStorage:WaitForChild("StudioTestPurchase")

local gui = UI.new("ScreenGui", {
	Name = "HUD",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	Parent = player:WaitForChild("PlayerGui"),
}) :: ScreenGui

local toast = UI.CreateToaster(gui)
remotes:WaitForChild("Notify").OnClientEvent:Connect(function(text, color)
	toast(text, color)
end)

---------------------------------------------------------------- top bar

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(320, 80),
	BackgroundColor3 = Color3.fromRGB(30, 30, 40),
	BackgroundTransparency = 0.2,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local cashLabel = UI.Label("$0", {
	Size = UDim2.new(1, -10, 0, 44),
	Position = UDim2.fromOffset(5, 2),
	TextColor3 = Color3.fromRGB(90, 255, 90),
	Parent = top,
})
local incomeLabel = UI.Label("$0/s", {
	Size = UDim2.new(1, -10, 0, 26),
	Position = UDim2.fromOffset(5, 48),
	TextColor3 = Color3.fromRGB(220, 220, 220),
	Parent = top,
})

local banner = UI.Label("", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 92),
	Size = UDim2.fromOffset(500, 30),
	TextColor3 = Color3.fromRGB(0, 255, 200),
	Parent = gui,
})

local carryLabel = UI.Label("", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -120),
	Size = UDim2.fromOffset(600, 44),
	TextColor3 = Color3.fromRGB(255, 230, 80),
	Visible = false,
	Parent = gui,
})

local function refreshStats()
	cashLabel.Text = Format.Cash(player:GetAttribute("Cash") or 0)
	local mult = player:GetAttribute("Multiplier") or 1
	incomeLabel.Text = Format.Cash(player:GetAttribute("Income") or 0) .. "/s  •  x" .. (math.floor(mult * 100) / 100)
	local carrying = player:GetAttribute("Carrying")
	carryLabel.Visible = carrying ~= nil
	carryLabel.Text = if carrying then "CARRYING " .. string.upper(carrying) .. " — RUN TO YOUR BASE!" else ""
end
player.AttributeChanged:Connect(refreshStats)
refreshStats()

---------------------------------------------------------------- shop

local function openModal(title: string): (Frame, ScrollingFrame)
	local modal = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 520, 0.7, 0),
		BackgroundColor3 = Color3.fromRGB(40, 40, 60),
		Visible = false,
		Parent = gui,
	}, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(math.huge, 560)
	constraint.Parent = modal
	UI.Label(title, { Size = UDim2.new(1, -80, 0, 50), Position = UDim2.fromOffset(16, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = modal })
	local close = UI.Button("X", Color3.fromRGB(230, 60, 60), {
		Size = UDim2.fromOffset(48, 48),
		Position = UDim2.new(1, -58, 0, 8),
		Parent = modal,
	})
	close.Activated:Connect(function()
		modal.Visible = false
	end)
	local list = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 64),
		Size = UDim2.new(1, -24, 1, -76),
		BackgroundTransparency = 1,
		ScrollBarThickness = 8,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = modal,
	}) :: ScrollingFrame
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	return modal, list
end

local shop, shopList = openModal("SHOP")
local order = 0

local function section(text: string)
	order += 1
	UI.Label(text, {
		Size = UDim2.new(1, 0, 0, 34),
		TextColor3 = Color3.fromRGB(255, 215, 0),
		LayoutOrder = order,
		Parent = shopList,
	})
end

local function shopItem(info, kind: string, color: Color3)
	order += 1
	local row = UI.new("Frame", {
		Size = UDim2.new(1, -10, 0, 74),
		BackgroundColor3 = Color3.fromRGB(60, 60, 85),
		LayoutOrder = order,
		Parent = shopList,
	}, { UI.Corner(12) })
	UI.Label(info.Name, {
		Position = UDim2.fromOffset(12, 4),
		Size = UDim2.new(1, -150, 0, 32),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	UI.Label(info.Description, {
		Position = UDim2.fromOffset(12, 38),
		Size = UDim2.new(1, -150, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(200, 200, 220),
		Font = Enum.Font.GothamMedium,
		Parent = row,
	})
	local button = UI.Button("R$ " .. info.Price, color, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(120, 52),
		Parent = row,
	})
	if kind == "Pass" then
		local function refresh()
			if player:GetAttribute("Pass_" .. info.Key) then
				button.Text = "OWNED"
				button.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
			end
		end
		player:GetAttributeChangedSignal("Pass_" .. info.Key):Connect(refresh)
		refresh()
	end
	button.Activated:Connect(function()
		local id = if kind == "Pass" then Config.Passes[info.Key] else Config.Products[info.Key]
		if kind == "Pass" and player:GetAttribute("Pass_" .. info.Key) then
			return
		end
		if id and id > 0 then
			if kind == "Pass" then
				MarketplaceService:PromptGamePassPurchase(player, id)
			else
				MarketplaceService:PromptProductPurchase(player, id)
			end
		elseif RunService:IsStudio() then
			testPurchase:FireServer(kind, info.Key)
			toast("[Studio test] granted " .. info.Name, Color3.fromRGB(255, 215, 0))
		else
			toast("Coming soon!", Color3.fromRGB(255, 90, 90))
		end
	end)
end

section("GAME PASSES")
for _, info in Config.PassInfo do
	shopItem(info, "Pass", Color3.fromRGB(40, 180, 70))
end
section("BOOSTS")
for _, info in Config.ProductInfo do
	shopItem(info, "Product", Color3.fromRGB(40, 140, 230))
end

---------------------------------------------------------------- rebirth

local rebirthModal, rebirthList = openModal("REBIRTH")
local rebirthInfo = UI.Label("", {
	Size = UDim2.new(1, 0, 0, 120),
	TextWrapped = true,
	Parent = rebirthList,
})
local rebirthButton = UI.Button("REBIRTH!", Color3.fromRGB(255, 170, 0), {
	Size = UDim2.new(1, -10, 0, 64),
	LayoutOrder = 2,
	Parent = rebirthList,
})
local function refreshRebirth()
	local rebirths = player:GetAttribute("Rebirths") or 0
	local cost = Config.RebirthCost(rebirths)
	rebirthInfo.Text = string.format(
		"Cost: %s\nNext bonus: %sx cash forever\nResets your cash and brainrots.",
		Format.Cash(cost),
		tostring(1 + (rebirths + 1) * Config.RebirthBonus)
	)
end
player:GetAttributeChangedSignal("Rebirths"):Connect(refreshRebirth)
refreshRebirth()
rebirthButton.Activated:Connect(function()
	local ok, message = remotes:WaitForChild("Rebirth"):InvokeServer()
	toast(message, if ok then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(255, 90, 90))
	if ok then
		rebirthModal.Visible = false
	end
end)

---------------------------------------------------------------- side buttons

local side = UI.new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 10, 0.5, 0),
	Size = UDim2.fromOffset(130, 200),
	BackgroundTransparency = 1,
	Parent = gui,
})
local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 10)
sideLayout.Parent = side
local shopButton = UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 56), Parent = side })
local rebirthOpen = UI.Button("REBIRTH", Color3.fromRGB(255, 170, 0), { Size = UDim2.fromOffset(130, 56), Parent = side })
local luckButton = UI.Button("2x LUCK", Color3.fromRGB(0, 190, 170), { Size = UDim2.fromOffset(130, 56), Parent = side })
shopButton.Activated:Connect(function()
	rebirthModal.Visible = false
	shop.Visible = not shop.Visible
end)
rebirthOpen.Activated:Connect(function()
	shop.Visible = false
	rebirthModal.Visible = not rebirthModal.Visible
end)
luckButton.Activated:Connect(function()
	local id = Config.Products.ServerLuck
	if id > 0 then
		MarketplaceService:PromptProductPurchase(player, id)
	elseif RunService:IsStudio() then
		testPurchase:FireServer("Product", "ServerLuck")
	end
end)

---------------------------------------------------------------- prompts + banners

local brainrots = workspace:WaitForChild("Brainrots")
task.spawn(function()
	while true do
		local now = os.time()
		local parts = {}
		local luckUntil = workspace:GetAttribute("ServerLuckUntil") or 0
		local eventUntil = workspace:GetAttribute("EventUntil") or 0
		if luckUntil > now then
			table.insert(parts, "2x SERVER LUCK " .. Format.Time(luckUntil - now))
		end
		if eventUntil > now then
			table.insert(parts, "BRAINROT RUSH " .. Format.Time(eventUntil - now))
		end
		banner.Text = table.concat(parts, "   •   ")

		for _, model in brainrots:GetChildren() do
			local root = model.PrimaryPart
			if not root then
				continue
			end
			local state = model:GetAttribute("State")
			local mine = model:GetAttribute("OwnerId") == player.UserId
			local buy = root:FindFirstChild("BuyPrompt") :: ProximityPrompt?
			local sell = root:FindFirstChild("SellPrompt") :: ProximityPrompt?
			local steal = root:FindFirstChild("StealPrompt") :: ProximityPrompt?
			if buy then
				buy.Enabled = state == "Walking"
			end
			if sell then
				sell.Enabled = state == "Placed" and mine
			end
			if steal then
				steal.Enabled = state == "Placed" and not mine
			end
		end
		task.wait(0.25)
	end
end)

---------------------------------------------------------------- VIP chat tag

TextChatService.OnIncomingMessage = function(message)
	local props = Instance.new("TextChatMessageProperties")
	local source = message.TextSource
	local speaker = source and Players:GetPlayerByUserId(source.UserId)
	if speaker and speaker:GetAttribute("Pass_VIP") then
		props.PrefixText = "<font color='#FFD700'>[VIP]</font> " .. message.PrefixText
	end
	return props
end
