-- Pizza Restaurant Tycoon. Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	DoubleCash = 0,
	AutoServe = 0,
	FastOvens = 0,
	VIP = 0,
}
Config.PassInfo = {
	{ Key = "DoubleCash", Name = "2x Cash", Price = 199, Description = "Every order pays double" },
	{ Key = "AutoServe", Name = "Robot Waiter", Price = 249, Description = "Finished pizzas are served automatically" },
	{ Key = "FastOvens", Name = "Turbo Ovens", Price = 199, Description = "Every oven bakes 2x faster" },
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "+50% tips, golden sign, VIP tag" },
}
Config.Products = {
	RushHour = 0,
	Celebrity = 0,
	CashPack = 0,
}
Config.ProductInfo = {
	{ Key = "RushHour", Name = "Rush Hour (10m)", Price = 49, Description = "Customers arrive 3x faster" },
	{ Key = "Celebrity", Name = "Celebrity Visit", Price = 79, Description = "A celebrity orders and tips 50x" },
	{ Key = "CashPack", Name = "Cash Register", Price = 49, Description = "Cash worth 30 min of business" },
}

Config.BasePrice = 10
Config.BakeTime = 6
Config.SpawnEvery = 6
Config.PatienceSeconds = 60
Config.MaxCustomers = 8

-- Upgrades bought in order. Kind: Oven (adds an oven), Speed (oven speed), Price (menu price),
-- Tips (decor -> tip %), Chef (auto-bakes), Seats (more customers at once).
Config.Upgrades = {
	{ Id = "oven2", Name = "Second Oven", Kind = "Oven", Cost = 150 },
	{ Id = "menu1", Name = "Pepperoni on the Menu", Kind = "Price", Value = 1.5, Cost = 400 },
	{ Id = "decor1", Name = "Checkered Tablecloths", Kind = "Tips", Value = 0.15, Cost = 800 },
	{ Id = "chef1", Name = "Hire a Chef", Kind = "Chef", Cost = 1_500 },
	{ Id = "oven3", Name = "Third Oven", Kind = "Oven", Cost = 3_000 },
	{ Id = "speed1", Name = "Stone Ovens", Kind = "Speed", Value = 1.4, Cost = 6_000 },
	{ Id = "menu2", Name = "Gourmet Pizzas", Kind = "Price", Value = 2.5, Cost = 12_000 },
	{ Id = "seats1", Name = "Patio Seating", Kind = "Seats", Value = 4, Cost = 20_000 },
	{ Id = "decor2", Name = "Neon Sign", Kind = "Tips", Value = 0.3, Cost = 35_000 },
	{ Id = "oven4", Name = "Fourth Oven", Kind = "Oven", Cost = 60_000 },
	{ Id = "speed2", Name = "Wood-Fired Ovens", Kind = "Speed", Value = 2, Cost = 120_000 },
	{ Id = "menu3", Name = "Truffle Pizzas", Kind = "Price", Value = 5, Cost = 250_000 },
	{ Id = "chef2", Name = "Head Chef", Kind = "Chef", Cost = 400_000 },
	{ Id = "decor3", Name = "Chandeliers", Kind = "Tips", Value = 0.6, Cost = 700_000 },
	{ Id = "menu4", Name = "Golden Pizza", Kind = "Price", Value = 12, Cost = 2_000_000 },
}
Config.UpgradeById = {}
for i, u in Config.Upgrades do
	u.Index = i
	Config.UpgradeById[u.Id] = u
end

return Config
