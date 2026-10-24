-- Brainrot Hotel (DOORS style): go door to door, loot drawers, hide in closets when Sahur rushes through.
-- Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	VIP = 0,
	DoubleKnobs = 0,
	SixthSense = 0,
	Lantern = 0,
}
Config.PassInfo = {
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "VIP tag, +50% knobs, 1 free revive every run" },
	{ Key = "DoubleKnobs", Name = "2x Knobs", Price = 149, Description = "Double knobs from drawers and runs" },
	{ Key = "SixthSense", Name = "Sixth Sense", Price = 199, Description = "Get warned about Sahur 3 seconds earlier" },
	{ Key = "Lantern", Name = "Lantern", Price = 99, Description = "A warm light that follows you through dark rooms" },
}
Config.Products = {
	Revive = 0,
	Knobs = 0,
	SkipRooms = 0,
	SummonSahur = 0,
}
Config.ProductInfo = {
	{ Key = "Revive", Name = "Revive", Price = 25, Description = "Come back at the newest door" },
	{ Key = "Knobs", Name = "Knob Bag", Price = 49, Description = "+750 knobs" },
	{ Key = "SkipRooms", Name = "Skip 10 Rooms", Price = 39, Description = "Jump 10 doors ahead" },
	{ Key = "SummonSahur", Name = "Summon Sahur", Price = 19, Description = "Sahur rushes through RIGHT NOW. Troll your friends!" },
}

Config.RoomLength = 60
Config.RoomWidth = 36
Config.RoomHeight = 18
Config.FinalRoom = 100
Config.RushChance = 0.18
Config.RushMinRoom = 4
Config.RushWarning = 3
Config.RushSpeed = 110
Config.KnobsPerRoom = 2
Config.FinishBonus = 2000

-- Knob shop: permanent upgrades.
Config.Upgrades = {
	{ Id = "Boots", Name = "Running Boots", Cost = 300, Description = "+3 walk speed forever" },
	{ Id = "Pockets", Name = "Deep Pockets", Cost = 500, Description = "Drawers give 50% more knobs" },
	{ Id = "Crucifix", Name = "Lucky Crucifix", Cost = 1500, Description = "Survive one Sahur hit per run" },
}

return Config
