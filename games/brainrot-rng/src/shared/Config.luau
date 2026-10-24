-- Brainrot RNG: roll for auras with "1 in N" odds. Replace the 0s with real IDs.
local Config = {}

Config.Passes = {
	AutoRoll = 0,
	QuickRoll = 0,
	Lucky = 0,
	VIP = 0,
}
Config.PassInfo = {
	{ Key = "AutoRoll", Name = "Auto Roll", Price = 149, Description = "Rolls for you nonstop, even AFK" },
	{ Key = "QuickRoll", Name = "Quick Roll", Price = 199, Description = "Roll twice as fast" },
	{ Key = "Lucky", Name = "Permanent Luck", Price = 299, Description = "+50% luck forever" },
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "+20% luck, VIP tag, rainbow name" },
}
Config.Products = {
	LuckPotion = 0,
	SuperPotion = 0,
	HeavenlyPotion = 0,
	ServerLuck = 0,
}
Config.ProductInfo = {
	{ Key = "LuckPotion", Name = "Luck Potion", Price = 29, Description = "2x luck for 10 minutes" },
	{ Key = "SuperPotion", Name = "Super Luck Potion", Price = 99, Description = "5x luck for 10 minutes" },
	{ Key = "HeavenlyPotion", Name = "Heavenly Potion", Price = 149, Description = "Your next roll has 200x luck!" },
	{ Key = "ServerLuck", Name = "2x Server Luck", Price = 99, Description = "2x luck for EVERYONE for 15 minutes" },
}

Config.RollCooldown = 1.2
Config.LuckyEvery = 10 -- every Nth roll gets 2x luck
Config.AnnounceAt = 10_000

-- Chance is "1 in N". Sorted rarest-first at runtime.
Config.Auras = {
	{ Id = "common", Name = "Common", Chance = 2, Color = Color3.fromRGB(200, 200, 200) },
	{ Id = "uncommon", Name = "Uncommon", Chance = 4, Color = Color3.fromRGB(110, 230, 110) },
	{ Id = "noobini", Name = "Noobini", Chance = 9, Color = Color3.fromRGB(255, 180, 90) },
	{ Id = "lirili", Name = "Lirili Larila", Chance = 16, Color = Color3.fromRGB(120, 200, 90) },
	{ Id = "tim", Name = "Tim Cheese", Chance = 32, Color = Color3.fromRGB(255, 230, 80) },
	{ Id = "fluri", Name = "Fluriflura", Chance = 64, Color = Color3.fromRGB(255, 140, 200) },
	{ Id = "talpa", Name = "Talpa di Fero", Chance = 128, Color = Color3.fromRGB(130, 130, 140) },
	{ Id = "trippi", Name = "Trippi Troppi", Chance = 250, Color = Color3.fromRGB(80, 180, 255) },
	{ Id = "tung", Name = "Tung Tung Sahur", Chance = 500, Color = Color3.fromRGB(190, 130, 70) },
	{ Id = "patapim", Name = "Brr Brr Patapim", Chance = 1_000, Color = Color3.fromRGB(70, 160, 60) },
	{ Id = "ballerina", Name = "Ballerina Cappuccina", Chance = 2_000, Color = Color3.fromRGB(255, 200, 220) },
	{ Id = "chimpanzini", Name = "Chimpanzini Bananini", Chance = 4_000, Color = Color3.fromRGB(255, 220, 40) },
	{ Id = "tralalero", Name = "Tralalero Tralala", Chance = 8_000, Color = Color3.fromRGB(70, 160, 255) },
	{ Id = "bombardiro", Name = "Bombardiro Crocodilo", Chance = 15_000, Color = Color3.fromRGB(40, 140, 60) },
	{ Id = "cappuccino", Name = "Cappuccino Assassino", Chance = 30_000, Color = Color3.fromRGB(120, 70, 40) },
	{ Id = "frigo", Name = "Frigo Camelo", Chance = 60_000, Color = Color3.fromRGB(190, 240, 255) },
	{ Id = "cocofanto", Name = "Cocofanto Elefanto", Chance = 120_000, Color = Color3.fromRGB(170, 170, 200) },
	{ Id = "odin", Name = "Odin Din Din Dun", Chance = 250_000, Color = Color3.fromRGB(220, 220, 255) },
	{ Id = "vacca", Name = "La Vacca Saturno Saturnita", Chance = 600_000, Color = Color3.fromRGB(255, 255, 255) },
	{ Id = "garama", Name = "Garama and Madundung", Chance = 1_500_000, Color = Color3.fromRGB(180, 60, 20) },
	{ Id = "skibidi", Name = "SKIBIDI OVERLORD", Chance = 5_000_000, Color = Color3.fromRGB(255, 0, 170) },
	{ Id = "sigma", Name = "THE SIGMA", Chance = 20_000_000, Color = Color3.fromRGB(0, 0, 0) },
}

Config.AuraById = {}
for _, aura in Config.Auras do
	Config.AuraById[aura.Id] = aura
end
Config.RarestFirst = table.clone(Config.Auras)
table.sort(Config.RarestFirst, function(a, b)
	return a.Chance > b.Chance
end)

-- Rolls one aura. Luck divides every chance (but never below "1 in 1").
function Config.Roll(luck: number, random: () -> number): string
	for _, aura in Config.RarestFirst do
		if aura.Chance > 1 and random() < luck / aura.Chance then
			return aura.Id
		end
	end
	return Config.Auras[1].Id
end

return Config
