-- Tiny helpers for building UI from code so the games need no Studio work.
local UI = {}

function UI.new(className: string, props: { [string]: any }, children: { Instance }?): Instance
	local inst = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(inst :: any)[key] = value
		end
	end
	if children then
		for _, child in children do
			child.Parent = inst
		end
	end
	if props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function UI.Corner(radius: number?): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	return c
end

function UI.Stroke(color: Color3?, thickness: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.new(0, 0, 0)
	s.Thickness = thickness or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

function UI.TextStroke(thickness: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = Color3.new(0, 0, 0)
	s.Thickness = thickness or 2
	return s
end

-- Big chunky cartoon button used by every game.
function UI.Button(text: string, color: Color3, props: { [string]: any }?): TextButton
	local button = UI.new("TextButton", {
		Text = text,
		BackgroundColor3 = color,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		AutoButtonColor = true,
		Size = UDim2.fromOffset(160, 50),
	}, { UI.Corner(12), UI.Stroke(Color3.new(0, 0, 0), 3), UI.TextStroke(2) }) :: TextButton
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = button
	if props then
		for key, value in props do
			(button :: any)[key] = value
		end
	end
	return button
end

function UI.Label(text: string, props: { [string]: any }?): TextLabel
	local label = UI.new("TextLabel", {
		Text = text,
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		Size = UDim2.fromOffset(200, 40),
	}, { UI.TextStroke(2) }) :: TextLabel
	if props then
		for key, value in props do
			(label :: any)[key] = value
		end
	end
	return label
end

-- Toast notifications stacked at the top of the screen.
function UI.CreateToaster(screenGui: ScreenGui)
	local holder = UI.new("Frame", {
		Name = "Toasts",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 90),
		Size = UDim2.new(0.6, 0, 0, 300),
		Parent = screenGui,
	})
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = holder

	local TweenService = game:GetService("TweenService")
	local order = 0
	return function(text: string, color: Color3?)
		order += 1
		local label = UI.Label(text, {
			Size = UDim2.new(1, 0, 0, 32),
			TextColor3 = color or Color3.new(1, 1, 1),
			LayoutOrder = order,
			Parent = holder,
		})
		task.delay(3.5, function()
			local tween = TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 1 })
			tween:Play()
			tween.Completed:Wait()
			label:Destroy()
		end)
	end
end

return UI
