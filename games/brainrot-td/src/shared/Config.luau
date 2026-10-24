-- Brainrot Tower Defense. Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	DoubleSpeed = 0,
	ExtraSlot = 0,
	LuckySummon = 0,
	VIP = 0,
}
Config.PassInfo = {
	{ Key = "DoubleSpeed", Name = "2x Speed", Price = 149, Description = "Toggle 2x game speed in matches" },
	{ Key = "ExtraSlot", Name = "+1 Unit Slot", Price = 199, Description = "Equip 5 units instead of 4" },
	{ Key = "LuckySummon", Name = "Lucky Summons", Price = 299, Description = "2x chance for Epic+ units" },
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "+50% gems from matches, VIP tag" },
}
Config.Products = {
	GemsSmall = 0,
	GemsLarge = 0,
	ReviveBase = 0,
	StarterPack = 0,
}
Config.ProductInfo = {
	{ Key = "GemsSmall", Name = "500 Gems", Price = 49, Description = "10 summons worth of gems" },
	{ Key = "GemsLarge", Name = "2,500 Gems", Price = 199, Description = "Best value: 50 summons" },
	{ Key = "ReviveBase", Name = "Revive Base", Price = 39, Description = "Base back to full HP, keep playing!" },
	{ Key = "StarterPack", Name = "Mythic Unit", Price = 299, Description = "A random Mythic unit, guaranteed" },
}

Config.SummonCost = 50
Config.StartGems = 150
Config.StartCash = 400
Config.BaseHealth = 100
Config.MaxPlacedPerPlayer = 12
Config.WinWave = 25
Config.GemsPerWave = 4
Config.WinBonusGems = 150
Config.AutoStartSeconds = 25
Config.WaveGap = 6

Config.RarityWeights = {
	{ Name = "Common", Weight = 58, Color = Color3.fromRGB(200, 200, 200) },
	{ Name = "Rare", Weight = 30, Color = Color3.fromRGB(60, 140, 255) },
	{ Name = "Epic", Weight = 10, Color = Color3.fromRGB(170, 70, 255) },
	{ Name = "Legendary", Weight = 1.8, Color = Color3.fromRGB(255, 200, 0) },
	{ Name = "Mythic", Weight = 0.2, Color = Color3.fromRGB(255, 50, 50) },
}

-- Cost = cash to place. Upgrades cost Cost * level and add +60% damage, +10% range.
-- Splash > 0 damages every enemy within that radius of the target.
Config.Units = {
	{ Id = "noobini", Name = "Noobini Shooter", Rarity = "Common", Cost = 150, Damage = 4, Range = 18, Cooldown = 0.8, Splash = 0, Color = Color3.fromRGB(255, 180, 90) },
	{ Id = "tung", Name = "Tung Tung Bonker", Rarity = "Common", Cost = 200, Damage = 12, Range = 10, Cooldown = 1.4, Splash = 4, Color = Color3.fromRGB(190, 130, 70) },
	{ Id = "lirili", Name = "Lirili Sniper", Rarity = "Rare", Cost = 350, Damage = 25, Range = 38, Cooldown = 2.5, Splash = 0, Color = Color3.fromRGB(120, 200, 90) },
	{ Id = "trippi", Name = "Trippi Gunner", Rarity = "Rare", Cost = 400, Damage = 5, Range = 20, Cooldown = 0.3, Splash = 0, Color = Color3.fromRGB(80, 180, 255) },
	{ Id = "bombardiro", Name = "Bombardiro Bomber", Rarity = "Epic", Cost = 700, Damage = 30, Range = 26, Cooldown = 2, Splash = 9, Color = Color3.fromRGB(60, 120, 60) },
	{ Id = "ballerina", Name = "Ballerina Blade", Rarity = "Epic", Cost = 600, Damage = 14, Range = 14, Cooldown = 0.45, Splash = 3, Color = Color3.fromRGB(255, 200, 220) },
	{ Id = "tralalero", Name = "Tralalero Tidal", Rarity = "Legendary", Cost = 1200, Damage = 40, Range = 30, Cooldown = 1, Splash = 7, Color = Color3.fromRGB(70, 160, 255) },
	{ Id = "cocofanto", Name = "Cocofanto Cannon", Rarity = "Legendary", Cost = 1500, Damage = 120, Range = 34, Cooldown = 2.2, Splash = 10, Color = Color3.fromRGB(160, 160, 190) },
	{ Id = "sigma", Name = "Sigma Overlord", Rarity = "Mythic", Cost = 2500, Damage = 90, Range = 45, Cooldown = 0.6, Splash = 8, Color = Color3.fromRGB(255, 0, 170) },
}
Config.MaxLevel = 4

-- Enemies by wave. HP scales by wave; bosses every 5th wave.
Config.Enemies = {
	{ Id = "pizzanini", Name = "Pizzanini", Health = 10, Speed = 7, Reward = 8, Color = Color3.fromRGB(255, 90, 60), Size = 2.5 },
	{ Id = "fluri", Name = "Fluriflura", Health = 6, Speed = 11, Reward = 8, Color = Color3.fromRGB(255, 140, 200), Size = 2 },
	{ Id = "talpa", Name = "Talpa Tank", Health = 35, Speed = 4.5, Reward = 15, Color = Color3.fromRGB(110, 110, 120), Size = 3.5 },
	{ Id = "skibidi", Name = "Skibidi Runner", Health = 14, Speed = 13, Reward = 12, Color = Color3.fromRGB(230, 230, 230), Size = 2.2 },
}
Config.Bosses = {
	{ Id = "boss_patapim", Name = "BOSS Brr Brr Patapim", Health = 400, Speed = 3.5, Reward = 250, Color = Color3.fromRGB(70, 140, 60), Size = 6 },
	{ Id = "boss_frigo", Name = "BOSS Frigo Camelo", Health = 900, Speed = 3, Reward = 500, Color = Color3.fromRGB(200, 240, 255), Size = 7 },
	{ Id = "boss_garama", Name = "BOSS Garama", Health = 2200, Speed = 2.6, Reward = 1000, Color = Color3.fromRGB(150, 70, 30), Size = 8 },
}

function Config.HealthScale(wave: number): number
	return 1.2 ^ (wave - 1)
end

function Config.WaveSize(wave: number): number
	return 6 + wave * 2
end

Config.UnitById = {}
for _, u in Config.Units do
	Config.UnitById[u.Id] = u
end
Config.RarityColor = {}
for _, r in Config.RarityWeights do
	Config.RarityColor[r.Name] = r.Color
end

function Config.UnitStats(unit, level: number)
	return {
		Damage = unit.Damage * (1 + (level - 1) * 0.6),
		Range = unit.Range * (1 + (level - 1) * 0.1),
		Cooldown = unit.Cooldown,
		Splash = unit.Splash,
	}
end

function Config.UpgradeCost(unit, level: number): number
	return math.floor(unit.Cost * level * 0.8)
end

return Config
