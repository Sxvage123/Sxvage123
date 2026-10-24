-- Brainrot Card Clash client: gems HUD, pack reveal, battle screen, card collection, boss ladder, shop.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
local shop = ShopUI.Create(gui, Config, buy, Color3.fromRGB(40, 30, 60))
ShopUI.VIPChatTag("VIP")

local top = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(420, 80),
	BackgroundColor3 = Color3.fromRGB(35, 25, 55),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { UI.Corner(14), UI.Stroke(Color3.new(0, 0, 0), 3) })
local gemsLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 44), Position = UDim2.fromOffset(5, 2), TextColor3 = Color3.fromRGB(120, 220, 255), Parent = top })
local infoLabel = UI.Label("", { Size = UDim2.new(1, -10, 0, 28), Position = UDim2.fromOffset(5, 48), TextColor3 = Color3.fromRGB(255, 215, 0), Parent = top })

local function panel(title: string, w: number, h: number): Frame
	local f = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = Color3.fromRGB(35, 25, 55),
		Visible = false,
		Parent = gui,
	}, { UI.Corner(16), UI.Stroke(Color3.new(0, 0, 0), 4) }) :: Frame
	UI.Label(title, { Size = UDim2.new(1, -60, 0, 44), Position = UDim2.fromOffset(10, 6), Parent = f })
	UI.Button("X", Color3.fromRGB(220, 60, 60), { Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -48, 0, 8), Parent = f }).Activated:Connect(function()
		f.Visible = false
	end)
	return f
end

-- A card tile: rarity-coloured frame, 3D figure, name, power/hp.
local function cardTile(c, parent: Instance, size: Vector2, extra: string?): (Frame, TextLabel)
	local info = Config.ById[c.Id]
	local rarity = Config.RarityByName[info.Rarity]
	local mutColor
	for _, m in Config.Mutations do
		if m.Name == c.Mut then
			mutColor = m.Color
		end
	end
	local tile = UI.new("Frame", { Size = UDim2.fromOffset(size.X, size.Y), BackgroundColor3 = rarity.Color:Lerp(Color3.new(0, 0, 0), 0.5), Parent = parent }, { UI.Corner(10), UI.Stroke(mutColor or rarity.Color, 3) }) :: Frame
	local view = ModelView.new(c.Id, { Size = UDim2.new(1, -8, 0.55, 0), Position = UDim2.fromOffset(4, 4), BackgroundTransparency = 1 })
	if view then
		view.Parent = tile
	end
	local p, hp = Config.Stats(c.Id, c.Mut)
	UI.Label((if c.Mut then c.Mut .. " " else "") .. info.Name, { Size = UDim2.new(1, -6, 0.18, 0), Position = UDim2.new(0, 3, 0.57, 0), TextColor3 = mutColor or Color3.new(1, 1, 1), Parent = tile })
	UI.Label("⚔️" .. Format.Abbreviate(p) .. "  ❤️" .. Format.Abbreviate(hp), { Size = UDim2.new(1, -6, 0.13, 0), Position = UDim2.new(0, 3, 0.76, 0), TextColor3 = Color3.fromRGB(255, 230, 150), Parent = tile })
	local bottom = UI.Label(extra or info.Rarity, { Size = UDim2.new(1, -6, 0.1, 0), Position = UDim2.new(0, 3, 0.89, 0), TextColor3 = rarity.Color:Lerp(Color3.new(1, 1, 1), 0.3), Parent = tile })
	return tile, bottom
end

---------------------------------------------------------------- pack reveal

local reveal = panel("YOU PULLED", 640, 330)
local revealRow = UI.new("ScrollingFrame", { Size = UDim2.new(1, -20, 1, -64), Position = UDim2.fromOffset(10, 56), BackgroundTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), ScrollBarThickness = 6, Parent = reveal }, {
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }) :: UIListLayout,
})
remotes:WaitForChild("Opened").OnClientEvent:Connect(function(cards)
	for _, child in revealRow:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, c in cards do
		cardTile(c, revealRow, Vector2.new(140, 250))
	end
	reveal.Visible = true
end)

---------------------------------------------------------------- battle screen

local battle = panel("BATTLE", 680, 380)
local bossLabel = UI.Label("", { Size = UDim2.new(1, -20, 0, 34), Position = UDim2.fromOffset(10, 52), TextColor3 = Color3.fromRGB(255, 120, 120), Parent = battle })
local bossBarBack = UI.new("Frame", { Size = UDim2.new(1, -40, 0, 22), Position = UDim2.fromOffset(20, 90), BackgroundColor3 = Color3.fromRGB(20, 15, 30), Parent = battle }, { UI.Corner(6) })
local bossBar = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(230, 50, 60), Parent = bossBarBack }, { UI.Corner(6) }) :: Frame
local battleRow = UI.new("Frame", { Size = UDim2.new(1, -20, 0, 210), Position = UDim2.fromOffset(10, 122), BackgroundTransparency = 1, Parent = battle }, {
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8) }) :: UIListLayout,
})
local resultLabel = UI.Label("", { Size = UDim2.new(1, -20, 0, 36), Position = UDim2.new(0, 10, 1, -42), Parent = battle })

remotes:WaitForChild("Battle").OnClientEvent:Connect(function(index, cards, log, won)
	local boss = Config.Bosses[index]
	for _, child in battleRow:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local hpLabels = {}
	for i, c in cards do
		local _, hpLabel = cardTile(c, battleRow, Vector2.new(118, 200), "❤️ " .. Format.Abbreviate(c.MaxHP))
		hpLabels[i] = hpLabel
	end
	bossLabel.Text = "Stage " .. index .. ": " .. boss.Name .. "  (⚔️" .. Format.Abbreviate(boss.Power) .. ")"
	bossBar.Size = UDim2.fromScale(1, 1)
	resultLabel.Text = ""
	battle.Visible = true
	for _, turn in log do
		task.wait(0.5)
		bossBar.Size = UDim2.fromScale(math.clamp(turn.BossHP / boss.HP, 0, 1), 1)
		resultLabel.Text = "Your cards hit for " .. Format.Abbreviate(turn.Damage) .. "!"
		resultLabel.TextColor3 = Color3.new(1, 1, 1)
		for i, hp in turn.HPs do
			local label = hpLabels[i]
			if label then
				label.Text = if hp > 0 then "❤️ " .. Format.Abbreviate(hp) else "💀 KO"
			end
		end
	end
	task.wait(0.4)
	resultLabel.Text = if won then "🏆 VICTORY!" else "💀 DEFEAT. Get stronger cards!"
	resultLabel.TextColor3 = if won then Color3.fromRGB(90, 255, 90) else Color3.fromRGB(255, 90, 90)
end)

---------------------------------------------------------------- collection

local collection = panel("MY CARDS (deck = gold border)", 700, 460)
local grid = UI.new("ScrollingFrame", { Size = UDim2.new(1, -20, 1, -64), Position = UDim2.fromOffset(10, 56), BackgroundTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 8, Parent = collection }, {
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(120, 230), CellPadding = UDim2.fromOffset(8, 8) }) :: UIGridLayout,
})
local myCards, myDeck = {}, {}
local function renderCollection()
	for _, child in grid:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local order = {}
	for i in myCards do
		table.insert(order, i)
	end
	table.sort(order, function(a, b)
		local pa = Config.Stats(myCards[a].Id, myCards[a].Mut)
		local pb = Config.Stats(myCards[b].Id, myCards[b].Mut)
		return pa > pb
	end)
	for _, i in order do
		local inDeck = table.find(myDeck, i) ~= nil
		local tile, _ = cardTile(myCards[i], grid, Vector2.new(120, 230), if inDeck then "⭐ IN DECK" else nil)
		if inDeck then
			UI.Stroke(Color3.fromRGB(255, 215, 0), 4).Parent = tile
		else
			local sell = UI.Button("SELL", Color3.fromRGB(200, 60, 60), { Size = UDim2.fromOffset(50, 24), Position = UDim2.new(1, -54, 0, 4), TextSize = 14, Parent = tile })
			sell.Activated:Connect(function()
				remotes.Sell:InvokeServer(i)
			end)
		end
	end
end
remotes:WaitForChild("Cards").OnClientEvent:Connect(function(cards, deck)
	myCards, myDeck = cards, deck
	if collection.Visible then
		renderCollection()
	end
end)

---------------------------------------------------------------- boss ladder + packs

local ladder = panel("BOSS LADDER", 460, 470)
local ladderList = UI.new("ScrollingFrame", { Size = UDim2.new(1, -20, 1, -64), Position = UDim2.fromOffset(10, 56), BackgroundTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 8, Parent = ladder }, {
	UI.new("UIListLayout", { Padding = UDim.new(0, 6) }) :: UIListLayout,
})
local ladderButtons = {}
for i in Config.Bosses do
	local b = UI.Button("", Color3.fromRGB(80, 60, 110), { Size = UDim2.new(1, -12, 0, 50), Parent = ladderList })
	b.Activated:Connect(function()
		ladder.Visible = false
		remotes.Fight:InvokeServer(i)
	end)
	ladderButtons[i] = b
end

local packs = panel("CARD PACKS (3 cards each)", 460, 70 + #Config.Packs * 60)
for i, pack in Config.Packs do
	UI.Button(pack.Name .. "  •  " .. Format.Abbreviate(pack.Cost) .. " 💎", pack.Color:Lerp(Color3.new(0, 0, 0), 0.3), { Size = UDim2.new(1, -20, 0, 50), Position = UDim2.fromOffset(10, 56 + (i - 1) * 60), Parent = packs }).Activated:Connect(function()
		remotes.OpenPack:InvokeServer(pack.Id)
	end)
end

local side = ShopUI.SideBar(gui)
UI.Button("PACKS", Color3.fromRGB(255, 140, 40), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	packs.Visible = not packs.Visible
end)
UI.Button("FIGHT", Color3.fromRGB(230, 60, 70), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	ladder.Visible = not ladder.Visible
end)
UI.Button("CARDS", Color3.fromRGB(80, 160, 255), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	collection.Visible = not collection.Visible
	if collection.Visible then
		renderCollection()
	end
end)
UI.Button("SHOP", Color3.fromRGB(40, 180, 70), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	shop.Visible = not shop.Visible
end)
UI.Button("MEGA PACK", Color3.fromRGB(255, 60, 180), { Size = UDim2.fromOffset(130, 48), Parent = side }).Activated:Connect(function()
	buy("Product", "MegaPack")
end)

task.spawn(function()
	while true do
		local stage = player:GetAttribute("Stage") or 0
		gemsLabel.Text = "💎 " .. Format.Abbreviate(player:GetAttribute("Gems") or 0)
		local luck = workspace:GetAttribute("LuckLeft") or 0
		infoLabel.Text = "Stage " .. stage .. "/" .. #Config.Bosses .. "  •  Deck ⚔️" .. Format.Abbreviate(player:GetAttribute("DeckPower") or 0) .. (if luck > 0 then "  •  🍀 " .. Format.Time(luck) else "")
		for i, b in ladderButtons do
			local boss = Config.Bosses[i]
			local locked = i > stage + 1
			b.Text = (if i <= stage then "✅ " elseif locked then "🔒 " else "⚔️ ") .. boss.Name .. "  ❤️" .. Format.Abbreviate(boss.HP)
			b.AutoButtonColor = not locked
			b.BackgroundColor3 = if locked then Color3.fromRGB(50, 45, 60) elseif i <= stage then Color3.fromRGB(60, 120, 70) else Color3.fromRGB(180, 60, 70)
		end
		task.wait(0.3)
	end
end)
