-- Brainrot Lifting Simulator: lift for Strength, arm-wrestle brainrot bosses for Wins, buy heavier weights, rebirth.
-- Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	AutoLift = 0,
	DoubleStrength = 0,
	DoubleWins = 0,
	VIP = 0,
}
Config.PassInfo = {
	{ Key = "AutoLift", Name = "Auto Lift", Price = 199, Description = "Lifts for you 5 times a second, even AFK" },
	{ Key = "DoubleStrength", Name = "2x Strength", Price = 249, Description = "Double strength from every lift" },
	{ Key = "DoubleWins", Name = "2x Wins", Price = 199, Description = "Double wins from every boss" },
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "+50% strength, VIP tag" },
}
Config.Products = {
	StrengthPack = 0,
	WinsPack = 0,
	Protein = 0,
}
Config.ProductInfo = {
	{ Key = "StrengthPack", Name = "Steroid-Free Shake", Price = 29, Description = "20 minutes of lifting instantly" },
	{ Key = "WinsPack", Name = "Trophy Crate", Price = 49, Description = "+wins equal to beating your best boss 5 times" },
	{ Key = "Protein", Name = "Mega Protein (15m)", Price = 79, Description = "3x strength for 15 minutes" },
}

Config.MaxLiftsPerSecond = 12
Config.AutoLiftsPerSecond = 5
Config.RebirthBonus = 1
Config.RebirthWins = 500

-- Weights: Power = strength per lift. Cost in Wins.
Config.Weights = {
	{ Id = "stick", Name = "Twig Dumbbell", Power = 1, Cost = 0, Color = Color3.fromRGB(150, 110, 70) },
	{ Id = "brick", Name = "Brick Dumbbell", Power = 3, Cost = 10, Color = Color3.fromRGB(180, 80, 60) },
	{ Id = "iron", Name = "Iron Dumbbell", Power = 8, Cost = 40, Color = Color3.fromRGB(120, 125, 135) },
	{ Id = "gold", Name = "Gold Dumbbell", Power = 25, Cost = 150, Color = Color3.fromRGB(255, 200, 40) },
	{ Id = "diamond", Name = "Diamond Dumbbell", Power = 80, Cost = 600, Color = Color3.fromRGB(120, 230, 255) },
	{ Id = "sigma", Name = "Sigma Dumbbell", Power = 260, Cost = 2500, Color = Color3.fromRGB(255, 0, 170) },
	{ Id = "brainrot", Name = "Brainrot Dumbbell", Power = 900, Cost = 10000, Color = Color3.fromRGB(0, 255, 200) },
}

-- Bosses: arm-wrestle them. Need = strength required; Wins = reward.
Config.Bosses = {
	{ Id = "noobini", Name = "Noobini Pizzanini", Need = 50, Wins = 1 },
	{ Id = "tim_cheese", Name = "Tim Cheese", Need = 400, Wins = 3 },
	{ Id = "lirili", Name = "Lirili Larila", Need = 2_500, Wins = 8 },
	{ Id = "tung", Name = "Tung Tung Tung Sahur", Need = 15_000, Wins = 20 },
	{ Id = "chimpanzini", Name = "Chimpanzini Bananini", Need = 80_000, Wins = 50 },
	{ Id = "ballerina", Name = "Ballerina Cappuccina", Need = 400_000, Wins = 120 },
	{ Id = "bombardiro", Name = "Bombardiro Crocodilo", Need = 2_000_000, Wins = 300 },
	{ Id = "tralalero", Name = "Tralalero Tralala", Need = 10_000_000, Wins = 800 },
	{ Id = "odin_din", Name = "Odin Din Din Dun", Need = 60_000_000, Wins = 2_000 },
	{ Id = "garama", Name = "Garama and Madundung", Need = 400_000_000, Wins = 6_000 },
}

Config.WeightById = {}
for i, w in Config.Weights do
	w.Index = i
	Config.WeightById[w.Id] = w
end

function Config.RebirthCost(rebirths: number): number
	return Config.RebirthWins * (rebirths + 1) ^ 2
end

return Config
