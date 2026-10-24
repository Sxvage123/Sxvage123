-- Game pass ownership + developer product receipts, done safely:
-- every receipt is granted exactly once and saved before Roblox is told it succeeded.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent.DataService)

local MonetizationService = {}

type Config = {
	Passes: { [string]: number },
	Products: { [string]: number },
	ProductHandlers: { [string]: (Player, { [string]: any }) -> boolean? },
	OnPassOwned: ((Player, string) -> ())?,
}

local passes: { [string]: number } = {}
local passIdToName: { [number]: string } = {}
local productIdToName: { [number]: string } = {}
local handlers = {}
local onPassOwned: ((Player, string) -> ())? = nil

local MAX_RECEIPTS = 100

local function setPass(player: Player, name: string)
	if player:GetAttribute("Pass_" .. name) then
		return
	end
	player:SetAttribute("Pass_" .. name, true)
	if onPassOwned then
		task.spawn(onPassOwned, player, name)
	end
end

function MonetizationService.OwnsPass(player: Player, name: string): boolean
	return player:GetAttribute("Pass_" .. name) == true
end

local function checkPasses(player: Player)
	for name, id in passes do
		if id and id > 0 then
			task.spawn(function()
				local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
				if ok and owns and player.Parent then
					setPass(player, name)
				end
			end)
		end
	end
end

local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = DataService.WaitFor(player, 20)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if table.find(data.Receipts, receipt.PurchaseId) then
		-- Already applied in memory; only confirm once it's actually saved
		-- (an earlier save may have failed).
		if DataService.Save(player, false) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local name = productIdToName[receipt.ProductId]
	local handler = name and handlers[name]
	if not handler then
		warn("[Monetization] no handler for product", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, result = pcall(handler, player, data)
	if not ok then
		warn("[Monetization] handler error", name, result)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if result == false then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	table.insert(data.Receipts, receipt.PurchaseId)
	while #data.Receipts > MAX_RECEIPTS do
		table.remove(data.Receipts, 1)
	end
	data.RobuxSpent = (data.RobuxSpent or 0) + (receipt.CurrencySpent or 0)
	if DataService.Save(player, false) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationService.Init(config: Config)
	passes = config.Passes
	handlers = config.ProductHandlers
	onPassOwned = config.OnPassOwned
	for name, id in config.Passes do
		passIdToName[id] = name
	end
	for name, id in config.Products do
		productIdToName[id] = name
	end

	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local name = passIdToName[passId]
		if purchased and name then
			setPass(player, name)
		end
	end)

	-- In Studio, buttons for passes/products whose ID is still 0 grant instantly so you can test.
	local testRemote = Instance.new("RemoteEvent")
	testRemote.Name = "StudioTestPurchase"
	testRemote.Parent = ReplicatedStorage
	testRemote.OnServerEvent:Connect(function(player, kind, name)
		if not RunService:IsStudio() or type(name) ~= "string" then
			return
		end
		if kind == "Pass" and passes[name] ~= nil then
			setPass(player, name)
		elseif kind == "Product" and handlers[name] then
			local data = DataService.Get(player)
			if data then
				handlers[name](player, data)
			end
		end
	end)

	Players.PlayerAdded:Connect(checkPasses)
	for _, player in Players:GetPlayers() do
		checkPasses(player)
	end
end

-- Lets admins / testers grant passes in Studio before IDs exist.
function MonetizationService.GrantPassForTesting(player: Player, name: string)
	setPass(player, name)
end

return MonetizationService
