-- Escape the Tsunami for Brainrots: run out, grab a brainrot, get back to base before the wave hits.
-- Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	DoubleCash = 0,
	VIP = 0,
	CarryMore = 0,
	SpeedCoil = 0,
}
Config.PassInfo = {
	{ Key = "DoubleCash", Name = "2x Cash", Price = 199, Description = "Double ALL cash forever!" },
	{ Key = "VIP", Name = "VIP", Price = 299, Description = "1.5x cash, VIP tag, gold trail" },
	{ Key = "CarryMore", Name = "Big Backpack", Price = 249, Description = "Carry 3 brainrots at once" },
	{ Key = "SpeedCoil", Name = "Speed Coil", Price = 149, Description = "Run 30% faster. Outrun the wave!" },
}
Config.Products = {
	CashPack = 0,
	CashVault = 0,
	ServerLuck = 0,
	StopTsunami = 0,
	SummonSecret = 0,
}
Config.ProductInfo = {
	{ Key = "CashPack", Name = "Cash Pack", Price = 29, Description = "10 minutes of income (min $5K)" },
	{ Key = "CashVault", Name = "Cash Vault", Price = 199, Description = "3 hours of income (min $250K)" },
	{ Key = "ServerLuck", Name = "2x Server Luck", Price = 79, Description = "Rarer brainrots for EVERYONE for 15 min" },
	{ Key = "StopTsunami", Name = "Stop the Tsunami", Price = 99, Description = "No waves for 5 minutes, for the whole server" },
	{ Key = "SummonSecret", Name = "Summon Secret", Price = 149, Description = "A SECRET brainrot spawns at the far end!" },
}
Config.CashPacks = {
	CashPack = { Seconds = 600, Min = 5_000 },
	CashVault = { Seconds = 3 * 3600, Min = 250_000 },
}

Config.StartingCash = 50
Config.BaseSlots = 10
Config.WalkSpeed = 22
Config.SpeedPerLevel = 3
Config.MaxSpeedLevel = 25
Config.SpeedCoilMultiplier = 1.3
Config.WaveInterval = 45
Config.WaveSpeed = 85
Config.StopTsunamiTime = 300
Config.ServerLuckTime = 900
Config.SellRefund = 0.5
Config.OfflineCapSeconds = 2 * 3600
Config.OfflineRate = 0.4
Config.RebirthBaseCost = 1_000_000
Config.RebirthCostGrowth = 6
Config.RebirthBonus = 0.5

function Config.SpeedUpgradeCost(level: number): number
	return math.floor(80 * 2.1 ^ level)
end
function Config.RebirthCost(rebirths: number): number
	return Config.RebirthBaseCost * Config.RebirthCostGrowth ^ rebirths
end

Config.Rarities = {
	{ Name = "Common", Color = Color3.fromRGB(200, 200, 200) },
	{ Name = "Rare", Color = Color3.fromRGB(60, 140, 255) },
	{ Name = "Epic", Color = Color3.fromRGB(170, 70, 255) },
	{ Name = "Legendary", Color = Color3.fromRGB(255, 200, 0) },
	{ Name = "Mythic", Color = Color3.fromRGB(255, 50, 50) },
	{ Name = "Brainrot God", Color = Color3.fromRGB(0, 255, 200) },
	{ Name = "Secret", Color = Color3.fromRGB(30, 30, 30) },
}

-- Zones run outward from the base. The further you go, the rarer the brainrots, and the harder to get back.
Config.Zones = {
	{ Name = "Common Shore", From = 20, To = 220, Rarity = "Common", Color = Color3.fromRGB(240, 220, 160), Max = 10 },
	{ Name = "Rare Reef", From = 220, To = 480, Rarity = "Rare", Color = Color3.fromRGB(150, 200, 240), Max = 8 },
	{ Name = "Epic Lagoon", From = 480, To = 780, Rarity = "Epic", Color = Color3.fromRGB(190, 150, 240), Max = 6 },
	{ Name = "Legendary Dunes", From = 780, To = 1100, Rarity = "Legendary", Color = Color3.fromRGB(255, 220, 120), Max = 5 },
	{ Name = "Mythic Wastes", From = 1100, To = 1420, Rarity = "Mythic", Color = Color3.fromRGB(240, 130, 120), Max = 4 },
	{ Name = "Godly Abyss", From = 1420, To = 1700, Rarity = "Brainrot God", Color = Color3.fromRGB(100, 230, 210), Max = 3 },
}
Config.TrackEnd = 1760

Config.Brainrots = {
	{ Id = "noobini", Name = "Noobini Pizzanini", Rarity = "Common", Income = 1 },
	{ Id = "lirili", Name = "Lirili Larila", Rarity = "Common", Income = 3 },
	{ Id = "tim_cheese", Name = "Tim Cheese", Rarity = "Common", Income = 5 },
	{ Id = "fluri", Name = "Fluriflura", Rarity = "Common", Income = 8 },
	{ Id = "talpa", Name = "Talpa di Fero", Rarity = "Rare", Income = 25 },
	{ Id = "svinina", Name = "Svinina Bombardino", Rarity = "Rare", Income = 40 },
	{ Id = "pipi_kiwi", Name = "Pipi Kiwi", Rarity = "Rare", Income = 60 },
	{ Id = "trippi", Name = "Trippi Troppi", Rarity = "Epic", Income = 150 },
	{ Id = "tung", Name = "Tung Tung Tung Sahur", Rarity = "Epic", Income = 250 },
	{ Id = "gangster", Name = "Gangster Footera", Rarity = "Epic", Income = 380 },
	{ Id = "patapim", Name = "Brr Brr Patapim", Rarity = "Legendary", Income = 1_000 },
	{ Id = "chimpanzini", Name = "Chimpanzini Bananini", Rarity = "Legendary", Income = 1_700 },
	{ Id = "ballerina", Name = "Ballerina Cappuccina", Rarity = "Legendary", Income = 2_600 },
	{ Id = "frigo", Name = "Frigo Camelo", Rarity = "Mythic", Income = 8_000 },
	{ Id = "bombardiro", Name = "Bombardiro Crocodilo", Rarity = "Mythic", Income = 14_000 },
	{ Id = "orangutini", Name = "Orangutini Ananasini", Rarity = "Mythic", Income = 22_000 },
	{ Id = "cocofanto", Name = "Cocofanto Elefanto", Rarity = "Brainrot God", Income = 70_000 },
	{ Id = "tralalero", Name = "Tralalero Tralala", Rarity = "Brainrot God", Income = 140_000 },
	{ Id = "odin_din", Name = "Odin Din Din Dun", Rarity = "Brainrot God", Income = 230_000 },
	{ Id = "la_vacca", Name = "La Vacca Saturno Saturnita", Rarity = "Secret", Income = 600_000 },
	{ Id = "skibidi", Name = "Sigma Skibidi Rizzler", Rarity = "Secret", Income = 1_300_000 },
	{ Id = "garama", Name = "Garama and Madundung", Rarity = "Secret", Income = 3_000_000 },
}

Config.ById = {}
Config.ByRarity = {}
Config.RarityByName = {}
Config.RarityIndex = {}
for i, rarity in Config.Rarities do
	Config.RarityByName[rarity.Name] = rarity
	Config.ByRarity[rarity.Name] = {}
	Config.RarityIndex[rarity.Name] = i
end
for _, info in Config.Brainrots do
	Config.ById[info.Id] = info
	table.insert(Config.ByRarity[info.Rarity], info)
end

return Config
