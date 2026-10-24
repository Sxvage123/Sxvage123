-- Hatch a Brainrot: click for Brainpower, hatch eggs for brainrot pets that multiply clicks.
-- Replace the 0s with your real Game Pass / Developer Product IDs.
local Config = {}

Config.Passes = {
	AutoClick = 0,
	DoubleClicks = 0,
	TripleHatch = 0,
	Lucky = 0,
	MoreEquips = 0,
	MoreStorage = 0,
}

Config.PassInfo = {
	{ Key = "AutoClick", Name = "Auto Clicker", Price = 149, Description = "Clicks for you 6 times a second, even AFK" },
	{ Key = "DoubleClicks", Name = "2x Brainpower", Price = 199, Description = "Double Brainpower forever" },
	{ Key = "TripleHatch", Name = "Triple Hatch", Price = 249, Description = "Hatch 3 eggs at once" },
	{ Key = "Lucky", Name = "Lucky", Price = 199, Description = "1.5x luck on every egg" },
	{ Key = "MoreEquips", Name = "+3 Equips", Price = 149, Description = "Equip 3 more pets" },
	{ Key = "MoreStorage", Name = "+100 Storage", Price = 49, Description = "Hold 100 more pets" },
}

Config.Products = {
	PowerSmall = 0,
	PowerLarge = 0,
	LuckBoost = 0,
	SuperLuckBoost = 0,
	SecretEgg = 0,
}

Config.ProductInfo = {
	{ Key = "PowerSmall", Name = "Brain Snack", Price = 25, Description = "15 minutes of clicking (min 1K)" },
	{ Key = "PowerLarge", Name = "Brain Feast", Price = 149, Description = "3 hours of clicking (min 100K)" },
	{ Key = "LuckBoost", Name = "2x Luck (30m)", Price = 49, Description = "Double your hatch luck for 30 minutes" },
	{ Key = "SuperLuckBoost", Name = "5x Luck (15m)", Price = 149, Description = "QUINTUPLE luck for 15 minutes" },
	{ Key = "SecretEgg", Name = "Secret Egg", Price = 99, Description = "Guaranteed Mythic or better pet!" },
}

Config.MaxClicksPerSecond = 16
Config.AutoClicksPerSecond = 6
Config.BaseEquips = 4
Config.ExtraEquips = 3
Config.BaseStorage = 60
Config.ExtraStorage = 100
Config.RebirthBaseCost = 50_000
Config.RebirthCostGrowth = 3
Config.RebirthBonus = 1 -- +100% per rebirth
Config.GiftEverySeconds = 300

Config.Rarities = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(90, 220, 90),
	Rare = Color3.fromRGB(60, 140, 255),
	Epic = Color3.fromRGB(170, 70, 255),
	Legendary = Color3.fromRGB(255, 200, 0),
	Mythic = Color3.fromRGB(255, 50, 50),
	Secret = Color3.fromRGB(255, 0, 170),
}
Config.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

-- Multiplier: how much each equipped pet adds to click power.
Config.Pets = {
	-- Brainrot Egg
	{ Id = "noobini", Name = "Noobini", Rarity = "Common", Multiplier = 1.2, Color = Color3.fromRGB(255, 180, 90) },
	{ Id = "pizzanini", Name = "Pizzanini", Rarity = "Uncommon", Multiplier = 1.6, Color = Color3.fromRGB(255, 90, 60) },
	{ Id = "lirili", Name = "Lirili Larila", Rarity = "Rare", Multiplier = 2.5, Color = Color3.fromRGB(120, 200, 90) },
	{ Id = "tim", Name = "Tim Cheese", Rarity = "Epic", Multiplier = 4, Color = Color3.fromRGB(255, 230, 80) },
	-- Sahur Egg
	{ Id = "tung", Name = "Tung Tung Sahur", Rarity = "Common", Multiplier = 3, Color = Color3.fromRGB(190, 130, 70) },
	{ Id = "tralala", Name = "Tralalero", Rarity = "Uncommon", Multiplier = 4.5, Color = Color3.fromRGB(70, 160, 255) },
	{ Id = "patapim", Name = "Brr Brr Patapim", Rarity = "Rare", Multiplier = 7, Color = Color3.fromRGB(70, 140, 60) },
	{ Id = "ballerina", Name = "Ballerina Cappuccina", Rarity = "Legendary", Multiplier = 15, Color = Color3.fromRGB(240, 210, 180) },
	-- Crocodilo Egg
	{ Id = "bombardiro", Name = "Bombardiro", Rarity = "Uncommon", Multiplier = 12, Color = Color3.fromRGB(60, 120, 60) },
	{ Id = "chimpanzini", Name = "Chimpanzini", Rarity = "Rare", Multiplier = 18, Color = Color3.fromRGB(255, 220, 40) },
	{ Id = "frigo", Name = "Frigo Camelo", Rarity = "Epic", Multiplier = 28, Color = Color3.fromRGB(200, 240, 255) },
	{ Id = "cappuccino", Name = "Cappuccino Assassino", Rarity = "Legendary", Multiplier = 55, Color = Color3.fromRGB(110, 70, 40) },
	-- Sigma Egg
	{ Id = "skibidi", Name = "Skibidi Head", Rarity = "Rare", Multiplier = 60, Color = Color3.fromRGB(230, 230, 230) },
	{ Id = "rizzler", Name = "Rizzler", Rarity = "Epic", Multiplier = 100, Color = Color3.fromRGB(255, 140, 200) },
	{ Id = "gyatt", Name = "Gyatt Gator", Rarity = "Legendary", Multiplier = 180, Color = Color3.fromRGB(60, 200, 120) },
	{ Id = "sigma", Name = "Sigma Supreme", Rarity = "Mythic", Multiplier = 400, Color = Color3.fromRGB(20, 20, 30) },
	-- Godly Egg
	{ Id = "odin", Name = "Odin Din Din Dun", Rarity = "Epic", Multiplier = 350, Color = Color3.fromRGB(220, 220, 255) },
	{ Id = "cocofanto", Name = "Cocofanto", Rarity = "Legendary", Multiplier = 650, Color = Color3.fromRGB(150, 150, 170) },
	{ Id = "vacca", Name = "La Vacca Saturno", Rarity = "Mythic", Multiplier = 1_500, Color = Color3.fromRGB(255, 255, 255) },
	{ Id = "garama", Name = "Garamararam", Rarity = "Secret", Multiplier = 5_000, Color = Color3.fromRGB(140, 60, 20) },
	-- Robux-only Secret Egg
	{ Id = "golden_tung", Name = "Golden Tung Tung", Rarity = "Mythic", Multiplier = 900, Color = Color3.fromRGB(255, 215, 0) },
	{ Id = "rainbow_tralala", Name = "Rainbow Tralalero", Rarity = "Secret", Multiplier = 3_000, Color = Color3.fromRGB(255, 80, 255) },
	{ Id = "void_sigma", Name = "Void Sigma", Rarity = "Secret", Multiplier = 12_000, Color = Color3.fromRGB(10, 0, 30) },
}

-- Chance values are relative weights. Lucky rarities get boosted by luck.
Config.Eggs = {
	{ Id = "basic", Name = "Brainrot Egg", Cost = 50, Color = Color3.fromRGB(255, 240, 200), Chances = { noobini = 60, pizzanini = 28, lirili = 10, tim = 2 } },
	{ Id = "sahur", Name = "Sahur Egg", Cost = 2_500, Color = Color3.fromRGB(190, 130, 70), Chances = { tung = 60, tralala = 28, patapim = 10.5, ballerina = 1.5 } },
	{ Id = "croc", Name = "Crocodilo Egg", Cost = 60_000, Color = Color3.fromRGB(60, 140, 70), Chances = { bombardiro = 60, chimpanzini = 28, frigo = 10.8, cappuccino = 1.2 } },
	{ Id = "sigma", Name = "Sigma Egg", Cost = 1_500_000, Color = Color3.fromRGB(40, 40, 60), Chances = { skibidi = 60, rizzler = 30, gyatt = 9.7, sigma = 0.3 } },
	{ Id = "godly", Name = "Godly Egg", Cost = 40_000_000, Color = Color3.fromRGB(0, 255, 200), Chances = { odin = 70, cocofanto = 27, vacca = 2.95, garama = 0.05 } },
}
Config.SecretEgg = { golden_tung = 85, rainbow_tralala = 14, void_sigma = 1 }

Config.LuckyRarities = { Rare = true, Epic = true, Legendary = true, Mythic = true, Secret = true }

Config.PetById = {}
for _, pet in Config.Pets do
	Config.PetById[pet.Id] = pet
end
Config.EggById = {}
for _, egg in Config.Eggs do
	Config.EggById[egg.Id] = egg
end

function Config.RebirthCost(rebirths: number): number
	return Config.RebirthBaseCost * Config.RebirthCostGrowth ^ rebirths
end

function Config.RarityRank(rarity: string): number
	return table.find(Config.RarityOrder, rarity) or 1
end

return Config
