-- Brainrot Jump Rope: two giant brainrots swing a rope that gets faster. Jump or you're out.
local Config = {}

Config.Passes = { DoubleCoins = 0, VIP = 0, SuperJump = 0, Shield = 0 }
Config.PassInfo = {
	{ Key = "DoubleCoins", Name = "2x Coins", Price = 149, Description = "Double coins for every jump" },
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "VIP tag, +50% coins" },
	{ Key = "SuperJump", Name = "Super Jump", Price = 149, Description = "Jump higher and hang in the air longer" },
	{ Key = "Shield", Name = "Rope Shield", Price = 199, Description = "Survive one rope hit every round" },
}
Config.Products = { Revive = 0, Coins = 0, SpeedUp = 0 }
Config.ProductInfo = {
	{ Key = "Revive", Name = "Revive", Price = 25, Description = "Jump back in" },
	{ Key = "Coins", Name = "Coin Bag", Price = 49, Description = "+1,000 coins" },
	{ Key = "SpeedUp", Name = "TURBO ROPE", Price = 29, Description = "Make the rope spin way faster. Chaos!" },
}

Config.Intermission = 12
Config.StartSpin = 1.6 -- radians per second
Config.SpinGrowth = 0.06 -- per rotation
Config.MaxSpin = 9
Config.CoinsPerJump = 2
Config.WinCoins = 60
Config.RoundMax = 120

return Config
