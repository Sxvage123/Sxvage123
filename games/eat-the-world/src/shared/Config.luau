-- Eat the Brainrot World: eat the city to grow huge, upgrade your bite, eat smaller players.
-- Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	DoubleSize = 0,
	VIP = 0,
	AutoEat = 0,
	MegaBite = 0,
}
Config.PassInfo = {
	{ Key = "DoubleSize", Name = "2x Size", Price = 199, Description = "Grow twice as fast from everything you eat" },
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "VIP tag, +50% size and coins" },
	{ Key = "AutoEat", Name = "Auto Eat", Price = 299, Description = "Eat automatically, no clicking needed" },
	{ Key = "MegaBite", Name = "Mega Bite", Price = 149, Description = "Eat 3x as many chunks per bite" },
}
Config.Products = {
	Size1 = 0,
	Size2 = 0,
	ShrinkRay = 0,
	Coins = 0,
}
Config.ProductInfo = {
	{ Key = "Size1", Name = "Growth Snack", Price = 29, Description = "+25% size instantly (min +200)" },
	{ Key = "Size2", Name = "Giant Feast", Price = 149, Description = "+150% size instantly (min +2,000)" },
	{ Key = "ShrinkRay", Name = "Shrink Ray", Price = 49, Description = "Shrinks the BIGGEST other player by half!" },
	{ Key = "Coins", Name = "Coin Bag", Price = 49, Description = "+2,000 coins (scales with rebirths)" },
}

Config.BiteCooldown = 0.3
Config.RespawnTime = 90
Config.EatPlayerRatio = 1.6 -- you can eat players this many times smaller than you
Config.MaxScale = 14

-- Character scale from size: grows quickly early, then slows down.
function Config.ScaleFor(size: number): number
	return math.min(Config.MaxScale, 1 + math.sqrt(size) / 12)
end

Config.Upgrades = {
	{ Id = "Bite", Name = "Bite Size", Description = "+1 chunk per bite", Base = 50, Growth = 2.2, Max = 15 },
	{ Id = "Reach", Name = "Jaw Reach", Description = "+15% reach", Base = 80, Growth = 2.0, Max = 15 },
	{ Id = "Speed", Name = "Giant Legs", Description = "+2 walk speed", Base = 60, Growth = 1.9, Max = 15 },
	{ Id = "Stomach", Name = "Stomach", Description = "+20% size from food", Base = 150, Growth = 2.4, Max = 20 },
}
function Config.UpgradeCost(u, level: number): number
	return math.floor(u.Base * u.Growth ^ level)
end

Config.RebirthSize = 5_000
Config.RebirthGrowth = 4
Config.RebirthBonus = 0.5
function Config.RebirthCost(rebirths: number): number
	return Config.RebirthSize * Config.RebirthGrowth ^ rebirths
end

-- Districts: rings around the centre. Bigger blocks need a bigger eater and are worth more.
Config.Districts = {
	{ Name = "Noobini Suburbs", Radius = 90, MinSize = 0, Food = 1, Block = 5, Floors = { 2, 3 }, Count = 10 },
	{ Name = "Tralalero Town", Radius = 190, MinSize = 60, Food = 6, Block = 7, Floors = { 4, 6 }, Count = 10 },
	{ Name = "Sigma City", Radius = 300, MinSize = 600, Food = 40, Block = 10, Floors = { 7, 10 }, Count = 10 },
}
Config.TitanMinSize = 4_000
Config.TitanFood = 600

return Config
