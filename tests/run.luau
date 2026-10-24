-- Run with: luau tests/run.luau   (from the repo root)
local H = require("./harness")
H.sources = SOURCES

local passed, failed = 0, 0
local function check(cond, name)
	if cond then
		passed += 1
	else
		failed += 1
		print("FAIL: " .. name)
	end
end

local ROOT = "shared/"
local function loadServices(passes, products, handlers)
	local DataService = H.load(ROOT .. "server/DataService.luau")
	local Monetization = H.load(ROOT .. "server/MonetizationService.luau", { DataService = DataService })
	return DataService, Monetization
end

---------------------------------------------------------------- Format
do
	local Format = H.load(ROOT .. "common/Format.luau")
	check(Format.Abbreviate(999) == "999", "format 999")
	check(Format.Abbreviate(1500) == "1.5K", "format 1.5K got " .. Format.Abbreviate(1500))
	check(Format.Abbreviate(1_000_000) == "1M", "format 1M got " .. Format.Abbreviate(1_000_000))
	check(Format.Abbreviate(123_456_789) == "123M", "format 123M got " .. Format.Abbreviate(123_456_789))
	check(Format.Cash(2_500_000_000) == "$2.5B", "format $2.5B got " .. Format.Cash(2_500_000_000))
	check(Format.Abbreviate(-1500) == "-1.5K", "format negative")
	check(Format.Time(125) == "2:05", "time 2:05")
	check(Format.Time(3725) == "1h 02m", "time 1h 02m got " .. Format.Time(3725))
end

---------------------------------------------------------------- DataService basics
H.newServer("job-A")
local DataService, Monetization = loadServices()
DataService.Init("Test", { Cash = 100, Items = {}, Nested = { A = 1 } })
local alice = H.newPlayer(1)
H.join(alice)
H.advance(1)
local data = DataService.Get(alice)
check(data ~= nil, "profile loads")
check(data and data.Cash == 100, "template applied")
check(data and data.LoginCount == 1, "login count")
data.Cash = 777
data.Items.sword = true

-- Purchases
local granted = 0
Monetization.Init({
	Passes = { VIP = 11 },
	Products = { Cash = 22, Broken = 33, Refuse = 44 },
	ProductHandlers = {
		Cash = function(player, d)
			d.Cash += 1000
			granted += 1
			return true
		end,
		Broken = function()
			error("boom")
		end,
		Refuse = function()
			return false
		end,
	},
})
local process = H.MarketplaceService.ProcessReceipt
local Decision = H.Enum.ProductPurchaseDecision
local r1 = process({ PlayerId = 1, PurchaseId = "p1", ProductId = 22, CurrencySpent = 25 })
check(r1 == Decision.PurchaseGranted, "receipt granted")
check(data.Cash == 1777 and granted == 1, "receipt applied once")
local r2 = process({ PlayerId = 1, PurchaseId = "p1", ProductId = 22, CurrencySpent = 25 })
check(r2 == Decision.PurchaseGranted and granted == 1, "duplicate receipt not re-applied")
check(process({ PlayerId = 1, PurchaseId = "p2", ProductId = 33 }) == Decision.NotProcessedYet, "handler error -> not processed")
check(process({ PlayerId = 1, PurchaseId = "p3", ProductId = 44 }) == Decision.NotProcessedYet, "handler false -> not processed")
check(process({ PlayerId = 1, PurchaseId = "p4", ProductId = 999 }) == Decision.NotProcessedYet, "unknown product -> not processed")
check(data.RobuxSpent == 25, "robux spent tracked")
-- Save failure must not report granted
H.failWrites = true
local r5 = process({ PlayerId = 1, PurchaseId = "p5", ProductId = 22 })
check(r5 == Decision.NotProcessedYet, "failed save -> not processed")
H.failWrites = false
local r5b = process({ PlayerId = 1, PurchaseId = "p5", ProductId = 22 })
check(r5b == Decision.PurchaseGranted, "retry after failed save is granted")
check(granted == 2, "retry did not double-grant (granted=" .. granted .. ")")

-- Pass ownership via purchase prompt
H.MarketplaceService.PromptGamePassPurchaseFinished:Fire(alice, 11, true)
check(Monetization.OwnsPass(alice, "VIP"), "pass granted on purchase")

---------------------------------------------------------------- session lock: second server can't load while A holds it
H.newServer("job-B")
local DataServiceB = loadServices()
DataServiceB.Init("Test", { Cash = 100, Items = {}, Nested = { A = 1 } })
local aliceOnB = H.newPlayer(1)
H.join(aliceOnB)
H.advance(3)
check(DataServiceB.Get(aliceOnB) == nil, "locked profile not loaded immediately on other server")

-- Server A saves on leave (releases the lock); B should then load the saved data.
DataService.Save(alice, true)
H.advance(30)
local loaded = DataServiceB.Get(aliceOnB)
check(loaded ~= nil, "loads after lock released")
check(loaded and loaded.Cash == 2777, "data persisted across servers (cash=" .. tostring(loaded and loaded.Cash) .. ")")
check(loaded and loaded.Items.sword == true, "nested data persisted")
check(loaded and loaded.LoginCount == 2, "login count incremented")

-- Old server A must not overwrite B's newer data now that B owns the lock.
data.Cash = -1
DataService.Save(alice, false)
local again = DataServiceB.Get(aliceOnB)
local stored = H.storeData["Test/Player_1"]
check(stored.Data.Cash == 2777, "stale server cannot overwrite (stored=" .. tostring(stored.Data.Cash) .. ")")
check(stored.Lock.JobId == "job-B", "lock held by new server")

-- Leaving saves + releases
again.Cash = 5000
H.leave(aliceOnB)
H.advance(1)
check(H.storeData["Test/Player_1"].Data.Cash == 5000, "save on leave")
check(H.storeData["Test/Player_1"].Lock == nil, "lock released on leave")

---------------------------------------------------------------- dead server lock gets stolen eventually
H.storeData["Test/Player_2"] = { Data = { Cash = 42 }, Lock = { JobId = "crashed", Time = 1_700_000_000 } }
H.newServer("job-C")
local DataServiceC = loadServices()
DataServiceC.Init("Test", { Cash = 100, Items = {}, Nested = { A = 1 } })
local bob = H.newPlayer(2)
H.join(bob)
H.advance(60)
local bobData = DataServiceC.Get(bob)
check(bobData ~= nil and bobData.Cash == 42, "stale lock stolen after retries")
check(bobData and bobData.Items ~= nil and bobData.Nested.A == 1, "reconcile adds missing keys")

-- Shutdown saves everyone
bobData.Cash = 99
H.shutdown()
H.advance(1)
check(H.storeData["Test/Player_2"].Data.Cash == 99, "BindToClose saves")

-- DataStore totally down: player is kicked rather than given a blank profile that would overwrite.
H.newServer("job-D")
local DataServiceD = loadServices()
DataServiceD.Init("Test", { Cash = 100 })
H.failWrites = true
local carol = H.newPlayer(3)
H.join(carol)
H.advance(60)
check(DataServiceD.Get(carol) == nil and carol.kicked ~= nil, "kick when data can't load")
H.failWrites = false

---------------------------------------------------------------- RNG odds roughly match "1 in N"
do
	local RNG = H.load("games/brainrot-rng/src/shared/Config.luau")
	local counts = {}
	local n = 400_000
	for _ = 1, n do
		local id = RNG.Roll(1, math.random)
		counts[id] = (counts[id] or 0) + 1
	end
	for _, id in { "tim", "talpa", "tung" } do
		local expected = n / RNG.AuraById[id].Chance
		local got = counts[id] or 0
		check(got > expected * 0.75 and got < expected * 1.25, "rng odds for " .. id .. " expected ~" .. math.floor(expected) .. " got " .. got)
	end
	-- 10x luck should make a 1-in-500 roughly 10x as common
	local lucky = 0
	for _ = 1, 100_000 do
		if RNG.Roll(10, math.random) == "tung" then
			lucky += 1
		end
	end
	check(lucky > 1400 and lucky < 2600, "luck scales odds (got " .. lucky .. " /100k, expected ~2000)")
end

print(string.format("%d passed, %d failed", passed, failed))
if failed > 0 then
	error("tests failed")
end
