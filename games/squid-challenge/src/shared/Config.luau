-- Squid Challenge: Red Light Green Light, then the Glass Bridge. Replace the 0s with real IDs.
local Config = {}

Config.Passes = {
	Speed = 0,
	DoubleWins = 0,
	VIP = 0,
	GlassVision = 0,
}
Config.PassInfo = {
	{ Key = "Speed", Name = "Fast Shoes", Price = 149, Description = "Run 20% faster" },
	{ Key = "DoubleWins", Name = "2x Coins", Price = 149, Description = "Double coins from every round" },
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "VIP tag, gold trail, +50% coins" },
	{ Key = "GlassVision", Name = "Glass Vision", Price = 299, Description = "Safe glass panels glow faintly for you" },
}
Config.Products = {
	Revive = 0,
	SkipStage = 0,
	Coins = 0,
}
Config.ProductInfo = {
	{ Key = "Revive", Name = "Revive", Price = 25, Description = "Back into the current stage!" },
	{ Key = "SkipStage", Name = "Skip Stage", Price = 49, Description = "Jump straight to the next stage" },
	{ Key = "Coins", Name = "Coin Bag", Price = 49, Description = "+1,000 coins" },
}

Config.Intermission = 15
Config.RLGLTime = 60
Config.BridgeTime = 70
Config.MoveTolerance = 0.6
Config.WinCoins = 60
Config.BridgeSteps = 12

return Config
