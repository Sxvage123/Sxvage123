-- Brainrot Disaster Survival: survive random disasters on a little island town. Replace the 0s with real IDs.
local Config = {}

Config.Passes = {
	DoubleCoins = 0,
	VIP = 0,
	Balloon = 0,
	Medkit = 0,
}
Config.PassInfo = {
	{ Key = "DoubleCoins", Name = "2x Coins", Price = 149, Description = "Double coins for every survival" },
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "VIP tag, +50% coins, gold trail" },
	{ Key = "Balloon", Name = "Balloon", Price = 199, Description = "Super jump: float above floods and stampedes" },
	{ Key = "Medkit", Name = "Medkit", Price = 99, Description = "Slowly heal during every disaster" },
}
Config.Products = {
	Revive = 0,
	ChooseDisaster = 0,
	Coins = 0,
}
Config.ProductInfo = {
	{ Key = "Revive", Name = "Revive", Price = 25, Description = "Jump back into the current disaster" },
	{ Key = "ChooseDisaster", Name = "Pick Next Disaster", Price = 39, Description = "You choose what hits next round" },
	{ Key = "Coins", Name = "Coin Bag", Price = 49, Description = "+1,500 coins" },
}

Config.Intermission = 15
Config.DisasterTime = 50
Config.SurviveCoins = 40
Config.HealthPerLevel = 15
Config.SpeedPerLevel = 1.5
Config.MaxLevel = 10

function Config.UpgradeCost(level: number): number
	return math.floor(100 * 1.8 ^ level)
end

Config.Disasters = {
	{ Id = "Flood", Name = "Flood", Color = Color3.fromRGB(60, 140, 255), Tip = "Get up high!" },
	{ Id = "Meteors", Name = "Meteor Shower", Color = Color3.fromRGB(255, 120, 40), Tip = "Keep moving, watch the sky!" },
	{ Id = "Tornado", Name = "Tornado", Color = Color3.fromRGB(170, 170, 170), Tip = "Stay away from the funnel!" },
	{ Id = "AcidRain", Name = "Acid Rain", Color = Color3.fromRGB(120, 255, 60), Tip = "Get under a roof!" },
	{ Id = "Stampede", Name = "Tung Tung Stampede", Color = Color3.fromRGB(190, 130, 70), Tip = "Jump on a building!" },
	{ Id = "Lava", Name = "Floor is Lava", Color = Color3.fromRGB(255, 60, 30), Tip = "Don't touch the ground!" },
}

return Config
