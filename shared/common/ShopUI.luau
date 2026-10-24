-- Shared Robux shop window + purchase helper used by every game's client.
-- Expects Config.Passes/Products (name -> id) and Config.PassInfo/ProductInfo (display rows).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UI = require(script.Parent.UI)

local ShopUI = {}

function ShopUI.Buyer(config, toast: (string, Color3?) -> ())
	local player = Players.LocalPlayer
	local testPurchase = ReplicatedStorage:WaitForChild("StudioTestPurchase")
	return function(kind: string, key: string)
		if kind == "Pass" and player:GetAttribute("Pass_" .. key) then
			return
		end
		local id = if kind == "Pass" then config.Passes[key] else config.Products[key]
		if id and id > 0 then
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
end

-- Returns the (hidden) shop frame; toggle its Visible to open it.
function ShopUI.Create(gui: ScreenGui, config, buy: (string, string) -> (), theme: Color3?): Frame
	local player = Players.LocalPlayer
	local bg = theme or Color3.fromRGB(40, 40, 60)
	local frame = UI.new("Frame", {
		Name = "Shop",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 520, 0.7, 0),
		BackgroundColor3 = bg,
		Visible = false,
		ZIndex = 5,
		Parent = gui,
	}, { UI.Corner(18), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
	local c = Instance.new("UISizeConstraint")
	c.MaxSize = Vector2.new(math.huge, 560)
	c.Parent = frame
	UI.Label("SHOP", { Size = UDim2.new(1, -80, 0, 50), Position = UDim2.fromOffset(16, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
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
	})
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local order = 0
	local function item(info, kind: string)
		order += 1
		local row = UI.new("Frame", { Size = UDim2.new(1, -10, 0, 74), BackgroundColor3 = bg:Lerp(Color3.new(1, 1, 1), 0.12), LayoutOrder = order, Parent = list }, { UI.Corner(12) })
		UI.Label(info.Name, { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -150, 0, 32), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
		UI.Label(info.Description, { Position = UDim2.fromOffset(12, 38), Size = UDim2.new(1, -150, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(215, 215, 230), Parent = row })
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
			buy(kind, info.Key)
		end)
	end
	for _, info in config.ProductInfo do
		item(info, "Product")
	end
	for _, info in config.PassInfo do
		item(info, "Pass")
	end
	return frame
end

-- Gold [VIP] chat tag for players owning the given pass.
function ShopUI.VIPChatTag(passKey: string)
	local TextChatService = game:GetService("TextChatService")
	TextChatService.OnIncomingMessage = function(message)
		local props = Instance.new("TextChatMessageProperties")
		local source = message.TextSource
		local speaker = source and Players:GetPlayerByUserId(source.UserId)
		if speaker and speaker:GetAttribute("Pass_" .. passKey) then
			props.PrefixText = "<font color='#FFD700'>[VIP]</font> " .. message.PrefixText
		end
		return props
	end
end

-- Column of big buttons on the left edge.
function ShopUI.SideBar(gui: ScreenGui): Frame
	local side = UI.new("Frame", {
		Name = "SideBar",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(130, 330),
		BackgroundTransparency = 1,
		Parent = gui,
	}) :: Frame
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = side
	return side
end

return ShopUI
