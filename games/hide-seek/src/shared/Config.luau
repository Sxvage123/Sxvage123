-- Brainrot Hide and Seek: one seeker (dressed as Tung Tung Sahur) hunts everyone else.
local Config = {}

Config.Passes = { DoubleCoins = 0, VIP = 0, Speed = 0, SeekerChance = 0 }
Config.PassInfo = {
	{ Key = "DoubleCoins", Name = "2x Coins", Price = 149, Description = "Double coins every round" },
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "VIP tag, +50% coins" },
	{ Key = "Speed", Name = "Fast Shoes", Price = 149, Description = "Run 15% faster as hider or seeker" },
	{ Key = "SeekerChance", Name = "Seeker Pass", Price = 99, Description = "3x more likely to be the seeker" },
}
Config.Products = { BeSeeker = 0, Radar = 0, Coins = 0 }
Config.ProductInfo = {
	{ Key = "BeSeeker", Name = "Be the Seeker", Price = 29, Description = "You're the seeker next round" },
	{ Key = "Radar", Name = "Radar Ping", Price = 19, Description = "Seeker: reveal every hider for 5 seconds" },
	{ Key = "Coins", Name = "Coin Bag", Price = 49, Description = "+1,000 coins" },
}

Config.Intermission = 15
Config.HideTime = 20
Config.SeekTime = 150
Config.TagRange = 6
Config.HiderWin = 60
Config.TagCoins = 25

return Config
