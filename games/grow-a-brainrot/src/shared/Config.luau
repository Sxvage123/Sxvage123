-- Grow a Brainrot: buy seeds from a rotating shop, plant, wait, harvest mutated fruit, sell.
-- Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	DoubleSell = 0,
	SellAnywhere = 0,
	MoreSpots = 0,
	FastGrow = 0,
	LuckyHarvest = 0,
}
Config.PassInfo = {
	{ Key = "DoubleSell", Name = "2x Sell", Price = 249, Description = "Every fruit sells for double" },
	{ Key = "SellAnywhere", Name = "Sell Anywhere", Price = 99, Description = "Sell from the menu, no walking" },
	{ Key = "MoreSpots", Name = "+12 Garden Spots", Price = 199, Description = "Plant 12 more seeds at once" },
	{ Key = "FastGrow", Name = "Fast Grow", Price = 149, Description = "Plants grow 1.5x faster" },
	{ Key = "LuckyHarvest", Name = "Lucky Harvest", Price = 199, Description = "2x mutation chance" },
}

Config.Products = {
	Restock = 0,
	GrowAll = 0,
	MythicSeed = 0,
	Weather = 0,
	CashPack = 0,
}
Config.ProductInfo = {
	{ Key = "Restock", Name = "Restock Shop", Price = 29, Description = "Instantly restock seeds for the WHOLE server" },
	{ Key = "GrowAll", Name = "Grow All", Price = 49, Description = "Finish growing every plant in your garden" },
	{ Key = "MythicSeed", Name = "Mythic Seed Pack", Price = 99, Description = "A random Mythic or Secret seed" },
	{ Key = "Weather", Name = "Summon Storm", Price = 79, Description = "Start a Brainrot Storm (huge mutations) for everyone" },
	{ Key = "CashPack", Name = "Cash Crate", Price = 49, Description = "Cash worth 30 min of farming (min $10K)" },
}

Config.StartingCash = 50
Config.StartingSeeds = { carrot = 3 }
Config.BaseSpots = 24
Config.ExtraSpots = 12
Config.FruitCap = 300
Config.RestockEvery = 300
Config.WeatherEvery = 900
Config.WeatherDuration = 180
Config.FastGrowFactor = 1.5

Config.Rarities = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(90, 220, 90),
	Rare = Color3.fromRGB(60, 140, 255),
	Legendary = Color3.fromRGB(255, 200, 0),
	Mythic = Color3.fromRGB(255, 50, 50),
	Secret = Color3.fromRGB(255, 0, 170),
}

-- Regrow = seconds until the plant fruits again after harvest (multi-harvest plants), nil = single harvest.
-- StockChance = probability the seed appears each restock; Stock = max per player per restock.
Config.Seeds = {
	{ Id = "carrot", Name = "Noobini Carrot", Rarity = "Common", Price = 10, Grow = 20, Value = 18, Color = Color3.fromRGB(255, 140, 40), StockChance = 1, Stock = 25 },
	{ Id = "tomato", Name = "Tomatini", Rarity = "Common", Price = 40, Grow = 45, Value = 30, Regrow = 30, Color = Color3.fromRGB(230, 50, 50), StockChance = 1, Stock = 15 },
	{ Id = "berry", Name = "Lirili Berry", Rarity = "Uncommon", Price = 250, Grow = 60, Value = 70, Regrow = 40, Color = Color3.fromRGB(80, 60, 200), StockChance = 0.8, Stock = 10 },
	{ Id = "corn", Name = "Tung Tung Corn", Rarity = "Uncommon", Price = 800, Grow = 120, Value = 1_300, Color = Color3.fromRGB(255, 220, 60), StockChance = 0.7, Stock = 8 },
	{ Id = "melon", Name = "Tralalero Melon", Rarity = "Rare", Price = 3_000, Grow = 180, Value = 400, Regrow = 90, Color = Color3.fromRGB(60, 200, 90), StockChance = 0.5, Stock = 5 },
	{ Id = "pumpkin", Name = "Patapim Pumpkin", Rarity = "Rare", Price = 9_000, Grow = 300, Value = 15_000, Color = Color3.fromRGB(255, 120, 20), StockChance = 0.4, Stock = 4 },
	{ Id = "banana", Name = "Chimpanzini Banana", Rarity = "Legendary", Price = 40_000, Grow = 400, Value = 3_500, Regrow = 150, Color = Color3.fromRGB(255, 235, 80), StockChance = 0.25, Stock = 3 },
	{ Id = "coconut", Name = "Cocofanto Coconut", Rarity = "Legendary", Price = 120_000, Grow = 600, Value = 9_000, Regrow = 240, Color = Color3.fromRGB(130, 90, 50), StockChance = 0.15, Stock = 2 },
	{ Id = "dragonfruit", Name = "Bombardiro Dragonfruit", Rarity = "Mythic", Price = 600_000, Grow = 900, Value = 40_000, Regrow = 300, Color = Color3.fromRGB(255, 60, 160), StockChance = 0.07, Stock = 1 },
	{ Id = "mango", Name = "Sahur Mango", Rarity = "Mythic", Price = 2_000_000, Grow = 1_200, Value = 110_000, Regrow = 400, Color = Color3.fromRGB(255, 170, 40), StockChance = 0.04, Stock = 1 },
	{ Id = "sigma_bean", Name = "Sigma Beanstalk", Rarity = "Secret", Price = 10_000_000, Grow = 1_800, Value = 450_000, Regrow = 600, Color = Color3.fromRGB(30, 255, 200), StockChance = 0.015, Stock = 1 },
}

-- Mutations multiply fruit value. Chance is per harvest; Weather boosts specific ones.
Config.Mutations = {
	{ Id = "Gold", Mult = 20, Chance = 0.01, Color = Color3.fromRGB(255, 215, 0) },
	{ Id = "Rainbow", Mult = 50, Chance = 0.001, Color = Color3.fromRGB(255, 80, 255) },
	{ Id = "Wet", Mult = 2, Chance = 0, Color = Color3.fromRGB(80, 160, 255) },
	{ Id = "Shocked", Mult = 100, Chance = 0, Color = Color3.fromRGB(255, 255, 120) },
	{ Id = "Brainrotted", Mult = 30, Chance = 0, Color = Color3.fromRGB(180, 0, 255) },
}

Config.Weathers = {
	Rain = { Name = "Rain", Boosts = { Wet = 0.5 } },
	Thunder = { Name = "Thunderstorm", Boosts = { Wet = 0.5, Shocked = 0.01 } },
	Brainrot = { Name = "BRAINROT STORM", Boosts = { Brainrotted = 0.15, Rainbow = 0.01, Gold = 0.05 } },
}

Config.SeedById = {}
for _, seed in Config.Seeds do
	Config.SeedById[seed.Id] = seed
end
Config.MutationById = {}
for _, m in Config.Mutations do
	Config.MutationById[m.Id] = m
end

-- Fruit weight (kg) scales value; rolled per harvest.
function Config.FruitValue(fruit): number
	local seed = Config.SeedById[fruit.S]
	if not seed then
		return 0
	end
	local mult = 1
	if fruit.M then
		local m = Config.MutationById[fruit.M]
		mult = m and m.Mult or 1
	end
	return math.floor(seed.Value * mult * (fruit.W or 1))
end

return Config
