-- All tuning + monetization IDs for Yoink a Brainrot.
-- Replace the 0s with your real Game Pass / Developer Product IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	DoubleCash = 0, -- 2x cash forever
	VIP = 0, -- 1.5x cash, longer base lock, VIP tag
	ExtraSlots = 0, -- +5 base slots
	SpeedCoil = 0, -- run faster (great for stealing)
}

Config.PassInfo = {
	{ Key = "DoubleCash", Name = "2x Cash", Price = 199, Description = "Double ALL cash forever!" },
	{ Key = "VIP", Name = "VIP", Price = 299, Description = "1.5x cash, 2x base lock time, VIP tag" },
	{ Key = "ExtraSlots", Name = "+5 Slots", Price = 149, Description = "Hold 5 more brainrots in your base" },
	{ Key = "SpeedCoil", Name = "Speed Coil", Price = 99, Description = "Run 40% faster. Steal & escape!" },
}

Config.Products = {
	CashSmall = 0,
	CashMedium = 0,
	CashLarge = 0,
	ServerLuck = 0,
	SpawnSecret = 0,
	InstantLock = 0,
}

Config.ProductInfo = {
	{ Key = "CashSmall", Name = "Cash Pack", Price = 25, Description = "10 minutes of your income (min $5K)" },
	{ Key = "CashMedium", Name = "Cash Bag", Price = 99, Description = "1 hour of your income (min $50K)" },
	{ Key = "CashLarge", Name = "Cash Vault", Price = 399, Description = "8 hours of your income (min $1M)" },
	{ Key = "ServerLuck", Name = "2x Server Luck", Price = 79, Description = "Doubles rare spawns for EVERYONE for 15 min" },
	{ Key = "SpawnSecret", Name = "Summon Secret", Price = 149, Description = "Spawns a SECRET brainrot. You get first dibs!" },
	{ Key = "InstantLock", Name = "Instant Lock", Price = 19, Description = "Lock your base right now, skipping cooldown" },
}

-- Cash pack sizes in seconds of income, with a floor.
Config.CashPacks = {
	CashSmall = { Seconds = 600, Min = 5_000 },
	CashMedium = { Seconds = 3600, Min = 50_000 },
	CashLarge = { Seconds = 8 * 3600, Min = 1_000_000 },
}

Config.StartingCash = 100
Config.BaseSlots = 10
Config.ExtraSlots = 5
Config.SpawnInterval = 2.2
Config.WalkTime = 38
Config.SellRefund = 0.5
Config.LockDuration = 60
Config.LockCooldown = 30
Config.StealHoldTime = 1.6
Config.StealTimeout = 45
Config.CarrySpeed = 13
Config.WalkSpeed = 18
Config.SpeedCoilMultiplier = 1.4
Config.OfflineCapSeconds = 2 * 3600
Config.OfflineRate = 0.5
Config.ServerLuckMinutes = 15
Config.RebirthBaseCost = 1_000_000
Config.RebirthCostGrowth = 5
Config.RebirthBonus = 0.5
Config.EventEvery = 600
Config.EventDuration = 120

Config.Rarities = {
	{ Name = "Common", Weight = 600, Color = Color3.fromRGB(200, 200, 200), Luck = false },
	{ Name = "Rare", Weight = 250, Color = Color3.fromRGB(60, 140, 255), Luck = false },
	{ Name = "Epic", Weight = 100, Color = Color3.fromRGB(170, 70, 255), Luck = true },
	{ Name = "Legendary", Weight = 35, Color = Color3.fromRGB(255, 200, 0), Luck = true },
	{ Name = "Mythic", Weight = 10, Color = Color3.fromRGB(255, 50, 50), Luck = true },
	{ Name = "Brainrot God", Weight = 2.5, Color = Color3.fromRGB(0, 255, 200), Luck = true },
	{ Name = "Secret", Weight = 0.4, Color = Color3.fromRGB(20, 20, 20), Luck = true },
}

-- Shape: body style used by the procedural model. Income is $/second.
Config.Brainrots = {
	{ Id = "noobini", Name = "Noobini Pizzanini", Rarity = "Common", Price = 25, Income = 1, Color = Color3.fromRGB(255, 180, 90), Shape = "Ball" },
	{ Id = "lirili", Name = "Lirili Larila", Rarity = "Common", Price = 60, Income = 3, Color = Color3.fromRGB(120, 200, 90), Shape = "Tall" },
	{ Id = "tim_cheese", Name = "Tim Cheese", Rarity = "Common", Price = 120, Income = 5, Color = Color3.fromRGB(255, 230, 80), Shape = "Block" },
	{ Id = "fluri", Name = "Fluriflura", Rarity = "Common", Price = 200, Income = 8, Color = Color3.fromRGB(255, 140, 200), Shape = "Ball" },
	{ Id = "talpa", Name = "Talpa di Fero", Rarity = "Rare", Price = 1_000, Income = 25, Color = Color3.fromRGB(110, 110, 120), Shape = "Block" },
	{ Id = "svinina", Name = "Svinina Bombardino", Rarity = "Rare", Price = 1_800, Income = 40, Color = Color3.fromRGB(255, 150, 160), Shape = "Ball" },
	{ Id = "pipi_kiwi", Name = "Pipi Kiwi", Rarity = "Rare", Price = 3_000, Income = 60, Color = Color3.fromRGB(140, 100, 50), Shape = "Tall" },
	{ Id = "trippi", Name = "Trippi Troppi", Rarity = "Epic", Price = 12_000, Income = 150, Color = Color3.fromRGB(80, 180, 255), Shape = "Ball" },
	{ Id = "tung", Name = "Tung Tung Tung Sahur", Rarity = "Epic", Price = 22_000, Income = 250, Color = Color3.fromRGB(190, 130, 70), Shape = "Tall" },
	{ Id = "gangster", Name = "Gangster Footera", Rarity = "Epic", Price = 35_000, Income = 380, Color = Color3.fromRGB(60, 60, 60), Shape = "Block" },
	{ Id = "brr_patapim", Name = "Brr Brr Patapim", Rarity = "Legendary", Price = 120_000, Income = 1_000, Color = Color3.fromRGB(70, 140, 60), Shape = "Tall" },
	{ Id = "chimpanzini", Name = "Chimpanzini Bananini", Rarity = "Legendary", Price = 220_000, Income = 1_700, Color = Color3.fromRGB(255, 220, 40), Shape = "Ball" },
	{ Id = "ballerina", Name = "Ballerina Cappuccina", Rarity = "Legendary", Price = 380_000, Income = 2_600, Color = Color3.fromRGB(240, 210, 180), Shape = "Tall" },
	{ Id = "frigo", Name = "Frigo Camelo", Rarity = "Mythic", Price = 1_500_000, Income = 8_000, Color = Color3.fromRGB(200, 240, 255), Shape = "Block" },
	{ Id = "bombardiro", Name = "Bombardiro Crocodilo", Rarity = "Mythic", Price = 3_000_000, Income = 14_000, Color = Color3.fromRGB(60, 120, 60), Shape = "Long" },
	{ Id = "orangutini", Name = "Orangutini Ananasini", Rarity = "Mythic", Price = 5_000_000, Income = 22_000, Color = Color3.fromRGB(255, 140, 40), Shape = "Ball" },
	{ Id = "cocofanto", Name = "Cocofanto Elefanto", Rarity = "Brainrot God", Price = 20_000_000, Income = 70_000, Color = Color3.fromRGB(150, 150, 170), Shape = "Block" },
	{ Id = "tralalero", Name = "Tralalero Tralala", Rarity = "Brainrot God", Price = 45_000_000, Income = 140_000, Color = Color3.fromRGB(70, 160, 255), Shape = "Long" },
	{ Id = "odin_din", Name = "Odin Din Din Dun", Rarity = "Brainrot God", Price = 80_000_000, Income = 230_000, Color = Color3.fromRGB(220, 220, 255), Shape = "Tall" },
	{ Id = "la_vacca", Name = "La Vacca Saturno Saturnita", Rarity = "Secret", Price = 250_000_000, Income = 600_000, Color = Color3.fromRGB(255, 255, 255), Shape = "Block" },
	{ Id = "skibidi_sigma", Name = "Sigma Skibidi Rizzler", Rarity = "Secret", Price = 600_000_000, Income = 1_300_000, Color = Color3.fromRGB(255, 0, 170), Shape = "Tall" },
	{ Id = "garama", Name = "Garama and Madundung", Rarity = "Secret", Price = 1_500_000_000, Income = 3_000_000, Color = Color3.fromRGB(140, 60, 20), Shape = "Long" },
}

Config.ById = {}
Config.RarityByName = {}
Config.ByRarity = {}
for _, rarity in Config.Rarities do
	Config.RarityByName[rarity.Name] = rarity
	Config.ByRarity[rarity.Name] = {}
end
for _, info in Config.Brainrots do
	Config.ById[info.Id] = info
	table.insert(Config.ByRarity[info.Rarity], info)
end

function Config.RebirthCost(rebirths: number): number
	return Config.RebirthBaseCost * Config.RebirthCostGrowth ^ rebirths
end

return Config
