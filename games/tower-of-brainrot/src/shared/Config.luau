-- Tower of Brainrot (Tower of Hell style). Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	SpeedCoil = 0,
	GravityCoil = 0,
	VIP = 0,
	DoubleCoins = 0,
}
Config.PassInfo = {
	{ Key = "SpeedCoil", Name = "Speed Coil", Price = 149, Description = "Toggle super speed" },
	{ Key = "GravityCoil", Name = "Gravity Coil", Price = 149, Description = "Toggle mega jumps" },
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "VIP tag, rainbow trail, +50% coins" },
	{ Key = "DoubleCoins", Name = "2x Coins", Price = 149, Description = "Double coins for reaching the top" },
}
Config.Products = {
	LavaRise = 0,
	SlowTime = 0,
	SkipSection = 0,
	NewTower = 0,
}
Config.ProductInfo = {
	{ Key = "LavaRise", Name = "Rising Lava (mutator)", Price = 49, Description = "Lava slowly rises for EVERYONE this round" },
	{ Key = "SlowTime", Name = "+2 Minutes", Price = 29, Description = "Adds 2 minutes to the round timer" },
	{ Key = "SkipSection", Name = "Skip Section", Price = 25, Description = "Teleport up one section" },
	{ Key = "NewTower", Name = "New Tower Now", Price = 79, Description = "Rebuild the tower immediately" },
}

Config.RoundTime = 480
Config.Sections = 10
Config.SectionHeight = 16
Config.TopCoins = 25
Config.LavaSpeed = 0.6

return Config
