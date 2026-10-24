-- Brainrot Color Block: a colour (and a brainrot) is called, every other tile drops. Last one standing wins.
local Config = {}

Config.Passes = { DoubleCoins = 0, VIP = 0, Speed = 0, ColorSense = 0 }
Config.PassInfo = {
	{ Key = "DoubleCoins", Name = "2x Coins", Price = 149, Description = "Double coins every round" },
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "VIP tag, +50% coins" },
	{ Key = "Speed", Name = "Fast Shoes", Price = 99, Description = "Run 20% faster" },
	{ Key = "ColorSense", Name = "Color Sense", Price = 199, Description = "Know the next colour 1 second early" },
}
Config.Products = { Revive = 0, Coins = 0, ExtraTime = 0 }
Config.ProductInfo = {
	{ Key = "Revive", Name = "Revive", Price = 25, Description = "Back onto the board right now" },
	{ Key = "Coins", Name = "Coin Bag", Price = 49, Description = "+1,000 coins" },
	{ Key = "ExtraTime", Name = "Slow Mode", Price = 39, Description = "+2 seconds to find the colour, for everyone, this round" },
}

Config.Intermission = 12
Config.GridSize = 12
Config.TileSize = 10
Config.StartTime = 5
Config.MinTime = 1.6
Config.Shrink = 0.25
Config.CoinsPerTurn = 3
Config.WinCoins = 50

Config.Colors = {
	{ Name = "RED", Color = Color3.fromRGB(235, 60, 60), Brainrot = "tung" },
	{ Name = "BLUE", Color = Color3.fromRGB(60, 120, 240), Brainrot = "tralalero" },
	{ Name = "GREEN", Color = Color3.fromRGB(70, 200, 80), Brainrot = "lirili" },
	{ Name = "YELLOW", Color = Color3.fromRGB(250, 220, 50), Brainrot = "chimpanzini" },
	{ Name = "PURPLE", Color = Color3.fromRGB(160, 80, 220), Brainrot = "trippi" },
	{ Name = "ORANGE", Color = Color3.fromRGB(255, 150, 40), Brainrot = "orangutini" },
	{ Name = "PINK", Color = Color3.fromRGB(255, 130, 200), Brainrot = "ballerina" },
	{ Name = "WHITE", Color = Color3.fromRGB(240, 240, 240), Brainrot = "frigo" },
}

return Config
