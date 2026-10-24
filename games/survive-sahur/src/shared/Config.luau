-- Survive Tung Tung Sahur. Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	Speed = 0,
	DoubleCoins = 0,
	VIP = 0,
	StartShield = 0,
}
Config.PassInfo = {
	{ Key = "Speed", Name = "Speedy Legs", Price = 149, Description = "Run 20% faster every round" },
	{ Key = "DoubleCoins", Name = "2x Coins", Price = 149, Description = "Double coins from surviving" },
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "+50% coins, VIP tag, gold trail" },
	{ Key = "StartShield", Name = "Free Shield", Price = 199, Description = "Start every round with a shield" },
}
Config.Products = {
	Revive = 0,
	SlowSahur = 0,
	ExtraSahur = 0,
	Coins = 0,
}
Config.ProductInfo = {
	{ Key = "Revive", Name = "Revive", Price = 25, Description = "Come back to life this round!" },
	{ Key = "SlowSahur", Name = "Slow Sahur", Price = 39, Description = "Every Sahur moves at half speed for 15s" },
	{ Key = "ExtraSahur", Name = "Spawn Extra Sahur", Price = 49, Description = "Chaos! Another Sahur joins the hunt" },
	{ Key = "Coins", Name = "Coin Bag", Price = 49, Description = "+500 coins" },
}

Config.Intermission = 15
Config.RoundTime = 120
Config.MinPlayers = 1
Config.SurviveCoins = 50
Config.CoinPerSecondAlive = 1
Config.PlayerSpeed = 16
Config.SahurSpeed = 15
Config.SahurSpeedGain = 0.06 -- per second of round
Config.SahurMaxSpeed = 24
Config.KillRange = 4.5
Config.ExtraSahurAt = { 50, 90 }

-- Coin shop consumables
Config.ShieldCost = 150
Config.SpeedPotionCost = 100

return Config
