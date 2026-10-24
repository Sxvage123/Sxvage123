-- Merge Brainrots: buy, merge two of the same level into the next, earn idle cash.
-- Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	DoubleCash = 0,
	AutoMerge = 0,
	MoreSlots = 0,
	FastDrops = 0,
}
Config.PassInfo = {
	{ Key = "DoubleCash", Name = "2x Cash", Price = 199, Description = "Double all income forever" },
	{ Key = "AutoMerge", Name = "Auto Merge", Price = 249, Description = "Merges matching brainrots for you" },
	{ Key = "MoreSlots", Name = "+10 Slots", Price = 149, Description = "A bigger board for more brainrots" },
	{ Key = "FastDrops", Name = "Fast Drops", Price = 149, Description = "Free brainrots drop 2x as often" },
}
Config.Products = {
	CashPack = 0,
	LevelUp = 0,
	MegaDrop = 0,
}
Config.ProductInfo = {
	{ Key = "CashPack", Name = "Cash Pile", Price = 29, Description = "1 hour of income instantly" },
	{ Key = "LevelUp", Name = "Level Up All", Price = 99, Description = "Every brainrot on your board +1 level" },
	{ Key = "MegaDrop", Name = "Mega Drop", Price = 49, Description = "Drops a brainrot 3 levels above your best buy" },
}

Config.BaseSlots = 20
Config.ExtraSlots = 10
Config.DropEvery = 15
Config.BaseBuyCost = 10
Config.BuyCostGrowth = 1.03
Config.IncomeGrowth = 2.15
Config.CostLevelFactor = 2.6
Config.OfflineCap = 3 * 3600
Config.OfflineRate = 0.5
Config.RebirthLevel = 20
Config.RebirthBonus = 0.5

Config.Names = {
	"Noobini", "Pizzanini", "Tim Cheese", "Lirili Larila", "Fluriflura", "Talpa di Fero", "Svinina", "Pipi Kiwi",
	"Trippi Troppi", "Tung Tung Sahur", "Gangster Footera", "Brr Brr Patapim", "Chimpanzini", "Ballerina Cappuccina",
	"Cappuccino Assassino", "Frigo Camelo", "Bombardiro Crocodilo", "Orangutini", "Cocofanto", "Tralalero Tralala",
	"Odin Din Din Dun", "La Vacca Saturno", "Garama", "Skibidi Overlord", "Rizzler Supreme", "Gyatt Emperor",
	"Ohio Final Boss", "Sigma Deity", "Brainrot Singularity", "THE ULTIMATE BRAINROT",
}
Config.MaxLevel = #Config.Names

function Config.Income(level: number): number
	return math.floor(Config.IncomeGrowth ^ (level - 1))
end

function Config.Color(level: number): Color3
	return Color3.fromHSV(((level - 1) * 0.083) % 1, 0.65, 1)
end

-- Highest level you can buy directly grows with your best brainrot.
function Config.BuyLevel(best: number): number
	return math.max(1, best - 4)
end

function Config.BuyCost(level: number, purchases: number): number
	return math.floor(Config.BaseBuyCost * Config.CostLevelFactor ^ (level - 1) * Config.BuyCostGrowth ^ purchases)
end

return Config
