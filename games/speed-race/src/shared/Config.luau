-- +1 Speed Brainrot Race: you get faster every second, run further for more wins. Replace the 0s with real IDs.
local Config = {}

Config.Passes = {
	DoubleSpeed = 0,
	DoubleWins = 0,
	VIP = 0,
	SuperLegs = 0,
}
Config.PassInfo = {
	{ Key = "DoubleSpeed", Name = "2x Speed", Price = 199, Description = "Gain speed twice as fast, forever" },
	{ Key = "DoubleWins", Name = "2x Wins", Price = 149, Description = "Double wins from every finish line" },
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "VIP tag, rainbow trail, +50% speed gain" },
	{ Key = "SuperLegs", Name = "Super Legs", Price = 399, Description = "3x speed gain (stacks with 2x Speed!)" },
}
Config.Products = {
	Speed1K = 0,
	Speed25K = 0,
	SkipZone = 0,
	ServerBoost = 0,
}
Config.ProductInfo = {
	{ Key = "Speed1K", Name = "+1,000 Speed", Price = 29, Description = "Instantly +1,000 speed" },
	{ Key = "Speed25K", Name = "+25,000 Speed", Price = 199, Description = "Instantly +25,000 speed" },
	{ Key = "SkipZone", Name = "Skip Zone", Price = 19, Description = "Teleport to the next finish line" },
	{ Key = "ServerBoost", Name = "3x Server Speed", Price = 99, Description = "3x speed gain for EVERYONE for 10 minutes" },
}

-- Speed shown to players. Actual WalkSpeed = 16 + Speed * WalkPerSpeed, capped so physics stays sane.
Config.WalkPerSpeed = 0.5
Config.MaxWalkSpeed = 1200
Config.ServerBoostTime = 600

-- Finish lines along the track. Dist = studs from the start line; Boss = brainrot statue guarding it.
Config.Zones = {
	{ Name = "Noobini Meadow", Dist = 250, Wins = 1, Color = Color3.fromRGB(110, 200, 90), Boss = "noobini" },
	{ Name = "Tung Tung Forest", Dist = 700, Wins = 3, Color = Color3.fromRGB(70, 150, 70), Boss = "tung" },
	{ Name = "Cappuccino Café", Dist = 1500, Wins = 8, Color = Color3.fromRGB(170, 120, 80), Boss = "cappuccino" },
	{ Name = "Tralalero Beach", Dist = 3000, Wins = 20, Color = Color3.fromRGB(240, 220, 150), Boss = "tralalero" },
	{ Name = "Bombardiro Skies", Dist = 5500, Wins = 50, Color = Color3.fromRGB(140, 190, 255), Boss = "bombardiro" },
	{ Name = "Lirili Desert", Dist = 9000, Wins = 120, Color = Color3.fromRGB(230, 180, 90), Boss = "lirili" },
	{ Name = "Frigo Glacier", Dist = 14000, Wins = 300, Color = Color3.fromRGB(200, 240, 255), Boss = "frigo" },
	{ Name = "Garama Volcano", Dist = 21000, Wins = 800, Color = Color3.fromRGB(200, 70, 50), Boss = "garama" },
	{ Name = "Skibidi Void", Dist = 30000, Wins = 2000, Color = Color3.fromRGB(120, 60, 200), Boss = "skibidi" },
}

-- Trails are bought with wins; the best one you own is equipped and boosts speed gain.
Config.Trails = {
	{ Id = "basic", Name = "Basic Trail", Cost = 10, Boost = 0.25, Color = Color3.fromRGB(255, 255, 255) },
	{ Id = "fire", Name = "Fire Trail", Cost = 75, Boost = 0.75, Color = Color3.fromRGB(255, 120, 30) },
	{ Id = "ocean", Name = "Ocean Trail", Cost = 400, Boost = 1.5, Color = Color3.fromRGB(40, 160, 255) },
	{ Id = "toxic", Name = "Toxic Trail", Cost = 2000, Boost = 3, Color = Color3.fromRGB(120, 255, 60) },
	{ Id = "galaxy", Name = "Galaxy Trail", Cost = 10000, Boost = 6, Color = Color3.fromRGB(180, 80, 255) },
	{ Id = "sigma", Name = "Sigma Trail", Cost = 50000, Boost = 12, Color = Color3.fromRGB(255, 215, 0) },
}

-- Rebirth: spend wins, reset speed, and gain speed faster forever after.
Config.RebirthBaseCost = 50
Config.RebirthBoost = 0.5

function Config.RebirthCost(rebirths: number): number
	return math.floor(Config.RebirthBaseCost * (rebirths + 1) ^ 1.6)
end

return Config
