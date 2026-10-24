-- Dig to the Brainrot Core. Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	DoubleCoins = 0,
	BigBackpack = 0,
	SellAnywhere = 0,
	Lucky = 0,
}
Config.PassInfo = {
	{ Key = "DoubleCoins", Name = "2x Coins", Price = 199, Description = "Every ore sells for double" },
	{ Key = "BigBackpack", Name = "Mega Backpack", Price = 149, Description = "3x backpack space" },
	{ Key = "SellAnywhere", Name = "Sell Anywhere", Price = 99, Description = "Sell from the menu, even deep underground" },
	{ Key = "Lucky", Name = "Lucky Miner", Price = 199, Description = "2x chance for rare ores and fossils" },
}
Config.Products = {
	Dynamite = 0,
	CoinPack = 0,
	MegaDrill = 0,
}
Config.ProductInfo = {
	{ Key = "Dynamite", Name = "Dynamite x5", Price = 25, Description = "Blow up a 3x3x3 area instantly" },
	{ Key = "CoinPack", Name = "Treasure Chest", Price = 49, Description = "Coins worth 20 min of mining (min 2K)" },
	{ Key = "MegaDrill", Name = "Mega Drill (10m)", Price = 79, Description = "5x mining power for 10 minutes" },
}

Config.BlockSize = 4
Config.PitWidth = 12
Config.PitDepth = 120
Config.ResetEvery = 1800
Config.ReachDistance = 18
Config.BaseBackpack = 30

-- Ores: MinDepth = first layer they appear on. Weight is relative chance once reachable.
Config.Ores = {
	{ Id = "dirt", Name = "Dirt", Value = 1, Health = 1, MinDepth = 0, MaxDepth = 12, Weight = 100, Color = Color3.fromRGB(120, 85, 55), Material = "Ground" },
	{ Id = "stone", Name = "Stone", Value = 2, Health = 3, MinDepth = 8, Weight = 100, Color = Color3.fromRGB(125, 125, 130), Material = "Slate" },
	{ Id = "coal", Name = "Coal", Value = 8, Health = 4, MinDepth = 5, Weight = 14, Color = Color3.fromRGB(40, 40, 45), Material = "Slate" },
	{ Id = "iron", Name = "Iron", Value = 25, Health = 8, MinDepth = 15, Weight = 10, Color = Color3.fromRGB(200, 160, 130), Material = "Metal" },
	{ Id = "gold", Name = "Gold", Value = 80, Health = 15, MinDepth = 30, Weight = 6, Color = Color3.fromRGB(255, 200, 40), Material = "Metal" },
	{ Id = "ruby", Name = "Ruby", Value = 250, Health = 30, MinDepth = 50, Weight = 4, Color = Color3.fromRGB(230, 40, 70), Material = "Glass" },
	{ Id = "diamond", Name = "Diamond", Value = 800, Health = 60, MinDepth = 70, Weight = 3, Color = Color3.fromRGB(120, 230, 255), Material = "Glass" },
	{ Id = "brainrotium", Name = "Brainrotium", Value = 3000, Health = 120, MinDepth = 95, Weight = 2, Color = Color3.fromRGB(0, 255, 180), Material = "Neon" },
	{ Id = "fossil", Name = "Brainrot Fossil", Value = 0, Health = 20, MinDepth = 10, Weight = 0.6, Color = Color3.fromRGB(235, 225, 190), Material = "Marble" },
}
Config.LuckyOres = { gold = true, ruby = true, diamond = true, brainrotium = true, fossil = true }

-- Fossils contain brainrots; deeper fossils roll rarer ones. Each unique brainrot gives +10% coins.
Config.Fossils = {
	{ Id = "noobini", Name = "Noobini Pizzanini", MinDepth = 0 },
	{ Id = "tim_cheese", Name = "Tim Cheese", MinDepth = 0 },
	{ Id = "fluri", Name = "Fluriflura", MinDepth = 0 },
	{ Id = "lirili", Name = "Lirili Larila", MinDepth = 15 },
	{ Id = "talpa", Name = "Talpa di Fero", MinDepth = 15 },
	{ Id = "tung", Name = "Tung Tung Tung Sahur", MinDepth = 25 },
	{ Id = "trippi", Name = "Trippi Troppi", MinDepth = 25 },
	{ Id = "chimpanzini", Name = "Chimpanzini Bananini", MinDepth = 40 },
	{ Id = "ballerina", Name = "Ballerina Cappuccina", MinDepth = 40 },
	{ Id = "cappuccino", Name = "Cappuccino Assassino", MinDepth = 55 },
	{ Id = "bombardiro", Name = "Bombardiro Crocodilo", MinDepth = 65 },
	{ Id = "tralalero", Name = "Tralalero Tralala", MinDepth = 75 },
	{ Id = "cocofanto", Name = "Cocofanto Elefanto", MinDepth = 85 },
	{ Id = "la_vacca", Name = "La Vacca Saturno Saturnita", MinDepth = 100 },
	{ Id = "garama", Name = "Garama and Madundung", MinDepth = 110 },
}
Config.FossilBonus = 0.1

-- Pickaxes: Power = damage per hit, Speed = hits per second. Cost in coins.
Config.Pickaxes = {
	{ Id = "wood", Name = "Wooden Pickaxe", Power = 1, Speed = 3, Cost = 0, Color = Color3.fromRGB(150, 110, 70) },
	{ Id = "stone", Name = "Stone Pickaxe", Power = 2, Speed = 3.5, Cost = 150, Color = Color3.fromRGB(130, 130, 135) },
	{ Id = "iron", Name = "Iron Pickaxe", Power = 5, Speed = 4, Cost = 1_200, Color = Color3.fromRGB(200, 200, 210) },
	{ Id = "gold", Name = "Gold Pickaxe", Power = 12, Speed = 4.5, Cost = 8_000, Color = Color3.fromRGB(255, 200, 40) },
	{ Id = "diamond", Name = "Diamond Pickaxe", Power = 30, Speed = 5, Cost = 50_000, Color = Color3.fromRGB(120, 230, 255) },
	{ Id = "brainrot", Name = "Brainrot Pickaxe", Power = 80, Speed = 6, Cost = 400_000, Color = Color3.fromRGB(0, 255, 180) },
}
Config.Backpacks = {
	{ Id = "pouch", Name = "Pouch", Capacity = 30, Cost = 0 },
	{ Id = "bag", Name = "Bag", Capacity = 80, Cost = 300 },
	{ Id = "pack", Name = "Backpack", Capacity = 200, Cost = 3_000 },
	{ Id = "crate", Name = "Crate", Capacity = 500, Cost = 25_000 },
	{ Id = "vault", Name = "Vault", Capacity = 1500, Cost = 200_000 },
}

Config.OreById = {}
for _, o in Config.Ores do
	Config.OreById[o.Id] = o
end
Config.PickaxeById = {}
for i, p in Config.Pickaxes do
	p.Index = i
	Config.PickaxeById[p.Id] = p
end
Config.BackpackById = {}
for _, b in Config.Backpacks do
	Config.BackpackById[b.Id] = b
end

return Config
