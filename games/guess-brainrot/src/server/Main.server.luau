-- Guess the Brainrot server: per-player questions shown on a big stage figure + client viewport.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotModels = require(ReplicatedStorage.Common.BrainrotModels)
local DataService = require(ServerScriptService.CommonServer.DataService)
local MonetizationService = require(ServerScriptService.CommonServer.MonetizationService)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local function remote(className: string, name: string): any
	local r = Instance.new(className)
	r.Name = name
	r.Parent = remotes
	return r
end
local NotifyRemote = remote("RemoteEvent", "Notify")
local QuestionRemote = remote("RemoteEvent", "Question") -- (id, choices, seconds, removed)
local AnswerRemote = remote("RemoteEvent", "Answer")

local world = Instance.new("Folder")
world.Name = "World"
world.Parent = workspace
local floor = Instance.new("Part")
floor.Anchored = true
floor.Size = Vector3.new(120, 2, 120)
floor.Position = Vector3.new(0, -1, 0)
floor.Color = Color3.fromRGB(70, 60, 110)
floor.Parent = world
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = Vector3.new(0, 0.5, 0)
spawn.Neutral = true
spawn.Parent = world
-- A ring of every brainrot as decoration (a "museum" of the answers).
for i, b in Config.Brainrots do
	if BrainrotModels.Has(b.Id) then
		local a = i / #Config.Brainrots * math.pi * 2
		local m, _ = BrainrotModels.Build(b.Id, { Scale = 1.4 })
		m:PivotTo(CFrame.lookAt(Vector3.new(math.cos(a) * 45, (m:GetAttribute("RootHeight") :: number?) or 4, math.sin(a) * 45), Vector3.new(0, 4, 0)))
		m.Parent = world
	end
end

type Q = { Id: string, Choices: { string }, Answer: string, Ends: number, Token: number }
local current: { [Player]: Q } = {}

local function sync(p: Player)
	local data = DataService.Get(p)
	if not data then
		return
	end
	p:SetAttribute("Coins", data.Coins)
	p:SetAttribute("Correct", data.Correct)
	p:SetAttribute("BestStreak", data.BestStreak)
	local ls = p:FindFirstChild("leaderstats")
	if ls then
		(ls :: any).Correct.Value = data.Correct;
		(ls :: any)["Best Streak"].Value = data.BestStreak
	end
end

local function shuffle<T>(t: { T }): { T }
	for i = #t, 2, -1 do
		local j = math.random(1, i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

local ask
local function wrongOnes(q: Q, n: number): { string }
	local out = {}
	for _, c in q.Choices do
		if c ~= q.Answer and #out < n then
			table.insert(out, c)
		end
	end
	return out
end

ask = function(p: Player)
	local pick = Config.Brainrots[math.random(1, #Config.Brainrots)]
	local choices = { pick.Name }
	local pool = shuffle(table.clone(Config.Brainrots))
	for _, b in pool do
		if #choices >= 4 then
			break
		end
		if b.Id ~= pick.Id then
			table.insert(choices, b.Name)
		end
	end
	shuffle(choices)
	local seconds = Config.QuestionTime + (if MonetizationService.OwnsPass(p, "ExtraTime") then 5 else 0)
	local token = ((current[p] and current[p].Token) or 0) + 1
	local q: Q = { Id = pick.Id, Choices = choices, Answer = pick.Name, Ends = os.clock() + seconds, Token = token }
	current[p] = q
	QuestionRemote:FireClient(p, pick.Id, choices, seconds, if MonetizationService.OwnsPass(p, "AutoHint") then wrongOnes(q, 1) else {})
	task.delay(seconds + 0.5, function()
		if current[p] == q then
			local data = DataService.Get(p)
			if data then
				data.Streak = 0
				sync(p)
			end
			NotifyRemote:FireClient(p, "Time's up! It was " .. q.Answer, Color3.fromRGB(255, 120, 90))
			ask(p)
		end
	end)
end

AnswerRemote.OnServerEvent:Connect(function(p, choice)
	local q = current[p]
	local data = DataService.Get(p)
	if not q or not data or type(choice) ~= "string" then
		return
	end
	current[p] = nil
	if choice == q.Answer then
		data.Streak += 1
		data.Correct += 1
		data.BestStreak = math.max(data.BestStreak, data.Streak)
		local timeBonus = math.max(0, q.Ends - os.clock()) / 2
		local m = (if MonetizationService.OwnsPass(p, "DoubleCoins") then 2 else 1) * (if MonetizationService.OwnsPass(p, "VIP") then 1.5 else 1)
		local coins = math.floor((Config.Coins + timeBonus + data.Streak) * m)
		data.Coins += coins
		NotifyRemote:FireClient(p, "✅ Correct! +" .. coins .. " coins (streak " .. data.Streak .. ")", Color3.fromRGB(90, 255, 90))
		if data.Streak % 10 == 0 then
			NotifyRemote:FireAllClients(p.DisplayName .. " is on a " .. data.Streak .. " streak!", Color3.fromRGB(255, 215, 0))
		end
	else
		data.Streak = 0
		NotifyRemote:FireClient(p, "❌ Nope! It was " .. q.Answer, Color3.fromRGB(255, 90, 90))
	end
	sync(p)
	task.delay(1, ask, p)
end)

DataService.ProfileLoaded:Connect(function(p)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, n in { "Correct", "Best Streak" } do
		local v = Instance.new("IntValue")
		v.Name = n
		v.Parent = ls
	end
	ls.Parent = p
	sync(p)
	task.delay(2, ask, p)
end)
Players.PlayerRemoving:Connect(function(p)
	current[p] = nil
end)

MonetizationService.Init({
	Passes = Config.Passes,
	Products = Config.Products,
	ProductHandlers = {
		Hint = function(p, data)
			local q = current[p]
			if q then
				QuestionRemote:FireClient(p, q.Id, q.Choices, math.max(1, math.floor(q.Ends - os.clock())), wrongOnes(q, 2))
			else
				data.Coins += 50
				sync(p)
			end
			return true
		end,
		Skip = function(p)
			current[p] = nil
			task.defer(ask, p)
			return true
		end,
		Coins = function(p, data)
			data.Coins += 1000
			sync(p)
			return true
		end,
	},
	OnPassOwned = function(p, name)
		NotifyRemote:FireClient(p, "Unlocked " .. name .. "!", Color3.fromRGB(255, 215, 0))
	end,
})

DataService.Init("GuessTheBrainrot_v1", { Coins = 0, Correct = 0, Streak = 0, BestStreak = 0 })
