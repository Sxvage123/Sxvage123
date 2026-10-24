-- Pizza Restaurant Tycoon server: restaurants per player, customers, ovens, serving, upgrades, staff.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Common.Format)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)

Lighting.ClockTime = 13
Lighting.Brightness = 2.5

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local NotifyRemote = Instance.new("RemoteEvent")
NotifyRemote.Name = "Notify"
NotifyRemote.Parent = remotes
local BuyRemote = Instance.new("RemoteFunction")
BuyRemote.Name = "BuyUpgrade"
BuyRemote.Parent = remotes

local function notify(player: Player?, text: string, color: Color3?)
	if player then
		NotifyRemote:FireClient(player, text, color)
	else
		NotifyRemote:FireAllClients(text, color)
	end
end

---------------------------------------------------------------- world

local world = Instance.new("Folder")
world.Name = "World"
world.Parent = workspace
local function part(props, parent: Instance?): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent or world
	return p
end
local function billboard(adornee: BasePart, text: string, offset: number, size: Vector2?): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset((size or Vector2.new(200, 50)).X, (size or Vector2.new(200, 50)).Y)
	gui.StudsOffset = Vector3.new(0, offset, 0)
	gui.MaxDistance = 80
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Parent = label
	label.Parent = gui
	return label
end

part({ Name = "Street", Size = Vector3.new(400, 2, 300), Position = Vector3.new(0, -1, 0), Color = Color3.fromRGB(90, 190, 90), Material = Enum.Material.Grass })
part({ Name = "Road", Size = Vector3.new(400, 0.2, 30), Position = Vector3.new(0, 0.1, 0), Color = Color3.fromRGB(60, 60, 65), Material = Enum.Material.Asphalt })
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = Vector3.new(0, 0.5, 0)
spawn.Neutral = true
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Parent = world

local plots = {}
do
	local i = 0
	for _, z in { 60, -60 } do
		for _, x in { -110, 0, 110 } do
			i += 1
			local cf = CFrame.lookAt(Vector3.new(x, 0, z), Vector3.new(x, 0, 0))
			local model = Instance.new("Model")
			model.Name = "Restaurant" .. i
			model.Parent = world
			part({ Name = "Floor", Size = Vector3.new(64, 1, 50), CFrame = cf * CFrame.new(0, 0.5, 0), Color = Color3.fromRGB(235, 225, 210), Material = Enum.Material.WoodPlanks }, model)
			for _, sx in { -1, 1 } do
				part({ Size = Vector3.new(1, 14, 50), CFrame = cf * CFrame.new(sx * 32, 7, 0), Color = Color3.fromRGB(200, 60, 50), Material = Enum.Material.Brick }, model)
			end
			part({ Size = Vector3.new(64, 14, 1), CFrame = cf * CFrame.new(0, 7, 25), Color = Color3.fromRGB(200, 60, 50), Material = Enum.Material.Brick }, model)
			part({ Size = Vector3.new(26, 14, 1), CFrame = cf * CFrame.new(-19, 7, -25), Color = Color3.fromRGB(200, 60, 50), Material = Enum.Material.Brick }, model)
			part({ Size = Vector3.new(26, 14, 1), CFrame = cf * CFrame.new(19, 7, -25), Color = Color3.fromRGB(200, 60, 50), Material = Enum.Material.Brick }, model)
			local signPart = part({ Name = "Sign", Size = Vector3.new(30, 5, 1), CFrame = cf * CFrame.new(0, 17, -25), Color = Color3.fromRGB(40, 40, 45) }, model)
			local signLabel = billboard(signPart, "For Sale", 0, Vector2.new(300, 60))
			local counter = part({ Name = "Counter", Size = Vector3.new(30, 4, 3), CFrame = cf * CFrame.new(0, 2.5, 10), Color = Color3.fromRGB(130, 85, 50), Material = Enum.Material.WoodPlanks }, model)
			local stockLabel = billboard(counter, "🍕 0 ready", 4)
			local seats = {}
			for r = 0, 1 do
				for c = -3, 3, 2 do
					local tableCF = cf * CFrame.new(c * 6.5, 0, -6 - r * 10)
					part({ Size = Vector3.new(5, 3, 5), CFrame = tableCF * CFrame.new(0, 2.5, 0), Color = Color3.fromRGB(250, 250, 250) }, model)
					table.insert(seats, { CFrame = tableCF * CFrame.new(0, 0, -3.5), Extra = r == 1 and math.abs(c) == 3 })
				end
			end
			plots[i] = {
				Index = i,
				CFrame = cf,
				Model = model,
				SignLabel = signLabel,
				StockLabel = stockLabel,
				Counter = counter,
				Seats = seats,
				Ovens = {},
				Customers = {},
				Stock = 0,
				Owner = nil,
				Door = cf * CFrame.new(0, 0, -30),
				SpawnCFrame = cf * CFrame.new(0, 4, 16),
				NextCustomer = 0,
				Decor = Instance.new("Folder"),
			}
			plots[i].Decor.Name = "Decor"
			plots[i].Decor.Parent = model
		end
	end
end

---------------------------------------------------------------- per-player helpers

local playerPlot: { [Player]: any } = {}

local function owned(data, kind: string)
	local list = {}
	for _, u in Config.Upgrades do
		if u.Kind == kind and data.Upgrades[u.Id] then
			table.insert(list, u)
		end
	end
	return list
end

local function stats(player: Player, data)
	local price = Config.BasePrice
	for _, u in owned(data, "Price") do
		price = Config.BasePrice * u.Value
	end
	local tips = 0
	for _, u in owned(data, "Tips") do
		tips += u.Value
	end
	if MonetizationService.OwnsPass(player, "VIP") then
		tips += 0.5
	end
	local speed = 1
	for _, u in owned(data, "Speed") do
		speed = u.Value
	end
	if MonetizationService.OwnsPass(player, "FastOvens") then
		speed *= 2
	end
	local seats = 6
	for _, u in owned(data, "Seats") do
		seats += u.Value
	end
	local cashMult = if MonetizationService.OwnsPass(player, "DoubleCash") then 2 else 1
	return {
		Price = price,
		Tips = tips,
		BakeTime = Config.BakeTime / speed,
		Ovens = 1 + #owned(data, "Oven"),
		Chefs = #owned(data, "Chef"),
		Seats = seats,
		CashMult = cashMult,
	}
end

local function sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Cash", data.Cash)
	player:SetAttribute("Served", data.Served)
	local list = {}
	for id in data.Upgrades do
		table.insert(list, id)
	end
	player:SetAttribute("Upgrades", table.concat(list, ","))
	local s = stats(player, data)
	player:SetAttribute("Price", s.Price)
	player:SetAttribute("Tips", s.Tips)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Cash.Value = Format.Cash(data.Cash)
		ls.Served.Value = data.Served
	end
end

---------------------------------------------------------------- ovens

local function refreshStock(plot)
	plot.StockLabel.Text = "🍕 " .. plot.Stock .. " ready"
end

local function buildOven(plot, index: number)
	local cf = plot.CFrame * CFrame.new(-21 + (index - 1) * 14, 0, 20)
	local oven = part({ Name = "Oven" .. index, Size = Vector3.new(8, 6, 4), CFrame = cf * CFrame.new(0, 3.5, 0), Color = Color3.fromRGB(110, 110, 120), Material = Enum.Material.Metal }, plot.Decor)
	part({ Size = Vector3.new(5, 2.5, 0.3), CFrame = cf * CFrame.new(0, 3.5, -2.1), Color = Color3.fromRGB(255, 140, 40), Material = Enum.Material.Neon }, plot.Decor)
	local label = billboard(oven, "Bake 🍕", 4.5)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OvenPrompt"
	prompt.ActionText = "Bake Pizza"
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = oven
	local o = { Part = oven, Label = label, Prompt = prompt, State = "Idle", ReadyAt = 0 }
	table.insert(plot.Ovens, o)
	local function bake(player: Player)
		local data = DataService.Get(player)
		if not data or o.State ~= "Idle" then
			return false
		end
		o.State = "Baking"
		o.ReadyAt = os.clock() + stats(player, data).BakeTime
		prompt.Enabled = false
		return true
	end
	o.Bake = bake
	prompt.Triggered:Connect(function(player)
		if plot.Owner == player then
			bake(player)
		end
	end)
	return o
end

local function decorate(plot, data)
	-- Visual upgrades: tablecloths, neon sign, chandeliers.
	for _, child in plot.Decor:GetChildren() do
		if child:GetAttribute("DecorId") then
			child:Destroy()
		end
	end
	local function deco(id: string, props)
		local p = part(props, plot.Decor)
		p:SetAttribute("DecorId", id)
	end
	if data.Upgrades.decor1 then
		for _, seat in plot.Seats do
			deco("decor1", { Size = Vector3.new(5.4, 0.2, 5.4), CFrame = seat.CFrame * CFrame.new(0, 4.1, 3.5), Color = Color3.fromRGB(220, 40, 40), Material = Enum.Material.Fabric })
		end
	end
	if data.Upgrades.decor2 then
		deco("decor2", { Size = Vector3.new(24, 3, 0.5), CFrame = plot.CFrame * CFrame.new(0, 11, 24), Color = Color3.fromRGB(255, 60, 200), Material = Enum.Material.Neon })
	end
	if data.Upgrades.decor3 then
		for _, x in { -16, 0, 16 } do
			deco("decor3", { Shape = Enum.PartType.Ball, Size = Vector3.one * 2.5, CFrame = plot.CFrame * CFrame.new(x, 12, -6), Color = Color3.fromRGB(255, 230, 150), Material = Enum.Material.Neon })
		end
	end
end

local function rebuild(plot, player: Player)
	for _, o in plot.Ovens do
		o.Part:Destroy()
	end
	plot.Decor:ClearAllChildren()
	table.clear(plot.Ovens)
	local data = DataService.Get(player)
	if not data then
		return
	end
	for i = 1, stats(player, data).Ovens do
		buildOven(plot, i)
	end
	decorate(plot, data)
	plot.SignLabel.Text = player.DisplayName .. "'s Pizzeria"
	plot.SignLabel.TextColor3 = if MonetizationService.OwnsPass(player, "VIP") then Color3.fromRGB(255, 215, 0) else Color3.new(1, 1, 1)
end

---------------------------------------------------------------- customers

local SKIN = { Color3.fromRGB(255, 220, 180), Color3.fromRGB(220, 170, 120), Color3.fromRGB(150, 100, 60), Color3.fromRGB(90, 60, 40) }

local function makeCustomer(plot, celebrity: boolean)
	local model = Instance.new("Model")
	model.Name = "Customer"
	local shirt = if celebrity then Color3.fromRGB(255, 215, 0) else Color3.fromHSV(math.random(), 0.6, 0.9)
	local root = part({ Name = "Root", Size = Vector3.new(2, 2, 1), CFrame = plot.Door * CFrame.new(0, 3, 0), Color = shirt, CanCollide = false }, model)
	model.PrimaryPart = root
	local function attach(props)
		local p = part(props, model)
		p.Anchored = false
		p.CanCollide = false
		p.Massless = true
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = p
		w.Parent = p
		return p
	end
	local skin = SKIN[math.random(1, #SKIN)]
	attach({ Name = "Head", Size = Vector3.new(1.2, 1.2, 1.2), CFrame = root.CFrame * CFrame.new(0, 1.6, 0), Color = skin })
	attach({ Size = Vector3.new(0.9, 2, 1), CFrame = root.CFrame * CFrame.new(-0.5, -2, 0), Color = Color3.fromRGB(40, 60, 120) })
	attach({ Size = Vector3.new(0.9, 2, 1), CFrame = root.CFrame * CFrame.new(0.5, -2, 0), Color = Color3.fromRGB(40, 60, 120) })
	attach({ Size = Vector3.new(0.8, 2, 0.8), CFrame = root.CFrame * CFrame.new(-1.4, 0, 0), Color = skin })
	attach({ Size = Vector3.new(0.8, 2, 0.8), CFrame = root.CFrame * CFrame.new(1.4, 0, 0), Color = skin })
	if celebrity then
		attach({ Size = Vector3.new(1.6, 0.4, 1.6), CFrame = root.CFrame * CFrame.new(0, 2.4, 0), Color = Color3.fromRGB(255, 215, 0), Material = Enum.Material.Neon })
	end
	local bubble = billboard(root, if celebrity then "⭐🍕⭐" else "🍕", 4, Vector2.new(120, 50))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ServePrompt"
	prompt.ActionText = "Serve Pizza"
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = root
	model.Parent = plot.Model
	return model, root, bubble, prompt
end

local function leave(plot, c, happy: boolean)
	c.Leaving = true
	c.Prompt.Enabled = false
	c.Bubble.Text = if happy then "😋" else "😡"
	local index = table.find(plot.Customers, c)
	if index then
		table.remove(plot.Customers, index)
	end
	local tween = TweenService:Create(c.Root, TweenInfo.new(3), { CFrame = plot.Door * CFrame.new(0, 3, -6) })
	tween:Play()
	task.delay(3.1, function()
		c.Model:Destroy()
	end)
end

local function serve(plot, c, player: Player)
	local data = DataService.Get(player)
	if not data or c.Leaving or not c.Seated or plot.Stock <= 0 then
		return false
	end
	plot.Stock -= 1
	refreshStock(plot)
	local s = stats(player, data)
	local patienceLeft = math.clamp((c.Deadline - os.clock()) / Config.PatienceSeconds, 0, 1)
	local tip = s.Price * s.Tips * (0.5 + patienceLeft)
	local total = math.floor((s.Price + tip) * s.CashMult * (if c.Celebrity then 50 else 1))
	data.Cash += total
	data.TotalEarned += total
	data.Served += 1
	sync(player)
	notify(player, "+" .. Format.Cash(total) .. (if c.Celebrity then " from a CELEBRITY!" else ""), Color3.fromRGB(90, 255, 90))
	leave(plot, c, true)
	return true
end

local function spawnCustomer(plot, celebrity: boolean?)
	local player = plot.Owner
	local data = player and DataService.Get(player)
	if not data then
		return
	end
	local s = stats(player, data)
	local taken = {}
	for _, c in plot.Customers do
		taken[c.Seat] = true
	end
	local seatIndex
	for i, seat in plot.Seats do
		if not taken[i] and i <= s.Seats then
			seatIndex = i
			break
		end
	end
	if not seatIndex then
		return
	end
	local model, root, bubble, prompt = makeCustomer(plot, celebrity == true)
	local c = { Model = model, Root = root, Bubble = bubble, Prompt = prompt, Seat = seatIndex, Seated = false, Leaving = false, Celebrity = celebrity == true, Deadline = os.clock() + Config.PatienceSeconds + 4 }
	table.insert(plot.Customers, c)
	local seatCF = plot.Seats[seatIndex].CFrame * CFrame.new(0, 3, 0)
	local tween = TweenService:Create(root, TweenInfo.new(3), { CFrame = CFrame.lookAt(seatCF.Position, (plot.Seats[seatIndex].CFrame * CFrame.new(0, 3, 3)).Position) })
	tween:Play()
	tween.Completed:Connect(function()
		if not c.Leaving then
			c.Seated = true
			prompt.Enabled = true
		end
	end)
	prompt.Triggered:Connect(function(p)
		if p == plot.Owner then
			if plot.Stock <= 0 then
				notify(p, "Bake a pizza first! Use an oven.", Color3.fromRGB(255, 200, 80))
			else
				serve(plot, c, p)
			end
		end
	end)
end

---------------------------------------------------------------- loop

task.spawn(function()
	while true do
		task.wait(0.5)
		local now = os.clock()
		for _, plot in plots do
			local player = plot.Owner
			local data = player and DataService.Get(player)
			if not data then
				continue
			end
			local s = stats(player, data)
			-- ovens
			local idle = {}
			for _, o in plot.Ovens do
				if o.State == "Baking" then
					local left = o.ReadyAt - now
					if left <= 0 then
						o.State = "Idle"
						o.Prompt.Enabled = true
						plot.Stock += 1
						refreshStock(plot)
						o.Label.Text = "Bake 🍕"
					else
						o.Label.Text = "Baking " .. math.ceil(left) .. "s"
					end
				end
				if o.State == "Idle" then
					table.insert(idle, o)
				end
			end
			-- chefs auto-bake (one oven each) while pizzas are needed
			local waiting = #plot.Customers
			local chefs = s.Chefs
			for _, o in idle do
				if chefs <= 0 or plot.Stock >= math.max(2, waiting) then
					break
				end
				o.Bake(player)
				chefs -= 1
			end
			-- robot waiter
			if MonetizationService.OwnsPass(player, "AutoServe") then
				for _, c in table.clone(plot.Customers) do
					if plot.Stock > 0 and c.Seated and not c.Leaving then
						serve(plot, c, player)
						break
					end
				end
			end
			-- patience
			for _, c in table.clone(plot.Customers) do
				if not c.Leaving and now > c.Deadline then
					leave(plot, c, false)
				end
			end
			-- arrivals
			local rush = (data.RushUntil or 0) > os.time()
			if now >= plot.NextCustomer and #plot.Customers < math.min(Config.MaxCustomers + 4, s.Seats) then
				plot.NextCustomer = now + Config.SpawnEvery / (if rush then 3 else 1)
				spawnCustomer(plot)
			end
		end
	end
end)

---------------------------------------------------------------- upgrades, players, monetization

BuyRemote.OnServerInvoke = function(player, id)
	local data = DataService.Get(player)
	local u = type(id) == "string" and Config.UpgradeById[id]
	if not data or not u then
		return false, "Invalid"
	end
	if data.Upgrades[id] then
		return false, "Already owned"
	end
	local prev = Config.Upgrades[u.Index - 1]
	if prev and not data.Upgrades[prev.Id] then
		return false, "Buy " .. prev.Name .. " first!"
	end
	if data.Cash < u.Cost then
		return false, "Need " .. Format.Cash(u.Cost) .. "!"
	end
	data.Cash -= u.Cost
	data.Upgrades[id] = true
	local plot = playerPlot[player]
	if plot then
		rebuild(plot, player)
	end
	sync(player)
	return true, "Bought " .. u.Name .. "!"
end

local function claim(player: Player)
	for _, plot in plots do
		if not plot.Owner then
			plot.Owner = player
			playerPlot[player] = plot
			rebuild(plot, player)
			return plot
		end
	end
	return nil
end

local function release(player: Player)
	local plot = playerPlot[player]
	if not plot then
		return
	end
	playerPlot[player] = nil
	plot.Owner = nil
	for _, c in plot.Customers do
		c.Model:Destroy()
	end
	table.clear(plot.Customers)
	for _, o in plot.Ovens do
		o.Part:Destroy()
	end
	table.clear(plot.Ovens)
	plot.Decor:ClearAllChildren()
	plot.Stock = 0
	refreshStock(plot)
	plot.SignLabel.Text = "For Sale"
end

DataService.ProfileLoaded:Connect(function(player, data)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = ls
	local served = Instance.new("IntValue")
	served.Name = "Served"
	served.Parent = ls
	ls.Parent = player
	for id in data.Upgrades do
		if not Config.UpgradeById[id] then
			data.Upgrades[id] = nil
		end
	end
	if not claim(player) then
		notify(player, "Every restaurant is taken! Try another server.", Color3.fromRGB(255, 90, 90))
	end
	sync(player)
	local function onCharacter(character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait()
		local plot = playerPlot[player]
		if plot then
			character:PivotTo(plot.SpawnCFrame)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	task.defer(release, player)
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		RushHour = function(player, data)
			data.RushUntil = math.max(data.RushUntil or 0, os.time()) + 600
			player:SetAttribute("RushUntil", data.RushUntil)
			notify(player, "RUSH HOUR! Customers arrive 3x faster for 10 minutes!", Color3.fromRGB(255, 200, 40))
			return true
		end,
		Celebrity = function(player)
			local plot = playerPlot[player]
			if plot then
				spawnCustomer(plot, true)
			end
			notify(nil, "⭐ A CELEBRITY is visiting " .. player.DisplayName .. "'s Pizzeria! ⭐", Color3.fromRGB(255, 215, 0))
			return true
		end,
		CashPack = function(player, data)
			local s = stats(player, data)
			local perMinute = (s.Price * (1 + s.Tips)) * s.CashMult * (60 / Config.SpawnEvery)
			local amount = math.max(500, math.floor(perMinute * 30))
			data.Cash += amount
			sync(player)
			notify(player, "+" .. Format.Cash(amount) .. "!", Color3.fromRGB(90, 255, 90))
			return true
		end,
	},
	OnPassOwned = function(player, name)
		local plot = playerPlot[player]
		if plot then
			rebuild(plot, player)
		end
		sync(player)
		notify(player, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("PizzaTycoon_v1", {
	Cash = 0,
	TotalEarned = 0,
	Served = 0,
	Upgrades = {},
	RushUntil = 0,
})
