-- 99 Nights with Sahur: keep the campfire burning, chop wood, eat, and survive Tung Tung Sahur every night.
-- Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	VIP = 0,
	BigBag = 0,
	DoubleDiamonds = 0,
	GoldenAxe = 0,
}
Config.PassInfo = {
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "VIP tag, +25% diamonds, start every run with 3 wood" },
	{ Key = "BigBag", Name = "Big Bag", Price = 149, Description = "Carry 12 wood instead of 5" },
	{ Key = "DoubleDiamonds", Name = "2x Diamonds", Price = 199, Description = "Double diamonds for every night survived" },
	{ Key = "GoldenAxe", Name = "Golden Axe", Price = 299, Description = "Chop trees instantly and get 2 wood each" },
}
Config.Products = {
	Revive = 0,
	Diamonds = 0,
	FuelFire = 0,
	BanishSahur = 0,
}
Config.ProductInfo = {
	{ Key = "Revive", Name = "Revive", Price = 25, Description = "Come back to life at the campfire right now" },
	{ Key = "Diamonds", Name = "Diamond Pack", Price = 49, Description = "+60 diamonds" },
	{ Key = "FuelFire", Name = "Fill the Fire", Price = 19, Description = "Instantly refuel the campfire for everyone" },
	{ Key = "BanishSahur", Name = "Banish Sahur", Price = 49, Description = "Sahur leaves for the rest of this night" },
}

Config.DayLength = 75
Config.NightLength = 60
Config.MaxFuel = 100
Config.StartFuel = 70
Config.FuelDrain = 0.4 -- per second, x1.6 at night
Config.FuelPerWood = 12
Config.BaseSafeRadius = 12
Config.SafePerFuel = 0.22
Config.CarryWood = 5
Config.BigBagWood = 12
Config.ChopTime = 1.2
Config.TreeRespawn = 40
Config.HungerDrain = 0.35
Config.BerryFood = 30
Config.BerryRegrow = 30
Config.MonsterSpeed = 17
Config.MonsterSpeedPerNight = 0.6
Config.MonsterDamage = 40 -- per second when touching
Config.DiamondsPerNight = 2

-- Classes are bought with diamonds and keep their perks forever.
Config.Classes = {
	{ Id = "Lumberjack", Cost = 40, Description = "Chop trees twice as fast, +1 wood per tree" },
	{ Id = "Forager", Cost = 40, Description = "Berries fill twice as much, hunger drains slower" },
	{ Id = "Runner", Cost = 60, Description = "Run 25% faster" },
	{ Id = "Firekeeper", Cost = 100, Description = "Your wood gives 50% more fuel" },
	{ Id = "Tank", Cost = 150, Description = "+60 max health, Sahur hurts you less" },
}

return Config
