-- Fish a Brainrot. Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	AutoFish = 0,
	DoubleSell = 0,
	Lucky = 0,
	SellAnywhere = 0,
}
Config.PassInfo = {
	{ Key = "AutoFish", Name = "Auto Fish", Price = 299, Description = "Catches fish automatically (AFK friendly)" },
	{ Key = "DoubleSell", Name = "2x Sell", Price = 199, Description = "Every fish sells for double" },
	{ Key = "Lucky", Name = "Lucky Fisher", Price = 199, Description = "+50% luck forever" },
	{ Key = "SellAnywhere", Name = "Sell Anywhere", Price = 99, Description = "Sell fish from the menu" },
}
Config.Products = {
	LuckTotem = 0,
	CashPack = 0,
	SigmaRod = 0,
	BigBait = 0,
}
Config.ProductInfo = {
	{ Key = "LuckTotem", Name = "Luck Totem", Price = 79, Description = "3x luck for the WHOLE server for 10 min" },
	{ Key = "BigBait", Name = "Mega Bait x20", Price = 49, Description = "Next 20 casts: 3x luck + instant bites" },
	{ Key = "CashPack", Name = "Treasure Chest", Price = 49, Description = "Cash worth 30 min of fishing (min $5K)" },
	{ Key = "SigmaRod", Name = "Sigma Rod", Price = 399, Description = "The best rod in the game, instantly" },
}

Config.InventoryCap = 100
Config.MaxCastDistance = 70
Config.MinCatchSeconds = 1.5

-- Rods: Luck multiplies rare odds, Speed shortens bite wait, Control = catch bar size (0..1).
Config.Rods = {
	{ Id = "stick", Name = "Stick Rod", Price = 0, Luck = 1, Speed = 1, Control = 0.28, Color = Color3.fromRGB(150, 100, 50) },
	{ Id = "plastic", Name = "Plastic Rod", Price = 750, Luck = 1.2, Speed = 1.15, Control = 0.32, Color = Color3.fromRGB(80, 160, 255) },
	{ Id = "lucky", Name = "Lucky Rod", Price = 8_000, Luck = 1.8, Speed = 1.2, Control = 0.3, Color = Color3.fromRGB(90, 230, 90) },
	{ Id = "fast", Name = "Speedy Rod", Price = 25_000, Luck = 1.5, Speed = 2, Control = 0.34, Color = Color3.fromRGB(255, 220, 60) },
	{ Id = "steady", Name = "Steady Rod", Price = 90_000, Luck = 2.2, Speed = 1.6, Control = 0.45, Color = Color3.fromRGB(200, 200, 220) },
	{ Id = "golden", Name = "Golden Rod", Price = 400_000, Luck = 3.5, Speed = 2, Control = 0.4, Color = Color3.fromRGB(255, 200, 0) },
	{ Id = "sigma", Name = "Sigma Rod", Price = -1, Luck = 6, Speed = 2.5, Control = 0.5, Color = Color3.fromRGB(255, 0, 170) }, -- Robux only
}

Config.Rarities = {
	{ Name = "Common", Weight = 60, Color = Color3.fromRGB(200, 200, 200), Difficulty = 0.8 },
	{ Name = "Uncommon", Weight = 25, Color = Color3.fromRGB(90, 220, 90), Difficulty = 1 },
	{ Name = "Rare", Weight = 10, Color = Color3.fromRGB(60, 140, 255), Difficulty = 1.25 },
	{ Name = "Legendary", Weight = 3.5, Color = Color3.fromRGB(255, 200, 0), Difficulty = 1.6 },
	{ Name = "Mythic", Weight = 1.2, Color = Color3.fromRGB(255, 50, 50), Difficulty = 2 },
	{ Name = "Secret", Weight = 0.15, Color = Color3.fromRGB(255, 0, 170), Difficulty = 2.6 },
}

Config.Fish = {
	{ Id = "noob_fish", Name = "Noobini Guppy", Rarity = "Common", Value = 6 },
	{ Id = "pizza_fish", Name = "Pizzanini Perch", Rarity = "Common", Value = 9 },
	{ Id = "cheese_fish", Name = "Tim Cheese Carp", Rarity = "Common", Value = 12 },
	{ Id = "lirili_eel", Name = "Lirili Eel", Rarity = "Uncommon", Value = 30 },
	{ Id = "tung_tuna", Name = "Tung Tung Tuna", Rarity = "Uncommon", Value = 45 },
	{ Id = "tralala_shark", Name = "Tralalero Shark", Rarity = "Rare", Value = 160 },
	{ Id = "patapim_pike", Name = "Patapim Pike", Rarity = "Rare", Value = 220 },
	{ Id = "croc_fish", Name = "Bombardiro Crocfish", Rarity = "Legendary", Value = 1_200 },
	{ Id = "ballerina_ray", Name = "Ballerina Manta", Rarity = "Legendary", Value = 1_700 },
	{ Id = "frigo_whale", Name = "Frigo Whale", Rarity = "Mythic", Value = 9_000 },
	{ Id = "skibidi_squid", Name = "Skibidi Squid", Rarity = "Mythic", Value = 14_000 },
	{ Id = "sigma_kraken", Name = "Sigma Kraken", Rarity = "Secret", Value = 120_000 },
	{ Id = "garama_leviathan", Name = "Garama Leviathan", Rarity = "Secret", Value = 250_000 },
}

Config.RodById = {}
for _, rod in Config.Rods do
	Config.RodById[rod.Id] = rod
end
Config.FishById = {}
Config.FishByRarity = {}
Config.RarityByName = {}
for _, r in Config.Rarities do
	Config.FishByRarity[r.Name] = {}
	Config.RarityByName[r.Name] = r
end
for _, fish in Config.Fish do
	Config.FishById[fish.Id] = fish
	table.insert(Config.FishByRarity[fish.Rarity], fish)
end

function Config.FishValue(entry): number
	local fish = Config.FishById[entry.Id]
	return if fish then math.floor(fish.Value * (entry.W or 1)) else 0
end

return Config
