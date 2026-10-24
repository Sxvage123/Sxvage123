-- Escape the Brainrot Obby. Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	SpeedCoil = 0,
	GravityCoil = 0,
	VIP = 0,
	DoubleWins = 0,
}
Config.PassInfo = {
	{ Key = "SpeedCoil", Name = "Speed Coil", Price = 99, Description = "Toggle super speed" },
	{ Key = "GravityCoil", Name = "Gravity Coil", Price = 99, Description = "Toggle mega jumps" },
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "Rainbow trail, VIP tag, +1 free skip every finish" },
	{ Key = "DoubleWins", Name = "2x Wins", Price = 149, Description = "Get 2 wins every time you finish" },
}

Config.Products = {
	SkipStage = 0,
	Skip5 = 0,
	SkipToEnd = 0,
}
Config.ProductInfo = {
	{ Key = "SkipStage", Name = "Skip Stage", Price = 15, Description = "Skip the stage you're on" },
	{ Key = "Skip5", Name = "Skip 5 Stages", Price = 59, Description = "Jump ahead 5 stages" },
	{ Key = "SkipToEnd", Name = "Skip to End", Price = 399, Description = "Teleport to the final stage" },
}

Config.StageCount = 60
Config.SpeedCoilWalkSpeed = 30
Config.GravityCoilJump = 85
Config.NormalWalkSpeed = 16
Config.NormalJump = 50

return Config
