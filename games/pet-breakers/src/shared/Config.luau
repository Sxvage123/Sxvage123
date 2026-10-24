-- Pet Breakers (Pet Simulator style): pets break coins/chests, unlock areas, hatch better pets.
-- Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	AutoFarm = 0,
	TripleHatch = 0,
	MoreEquips = 0,
	DoubleCoins = 0,
	Lucky = 0,
}
Config.PassInfo = {
	{ Key = "AutoFarm", Name = "Auto Farm", Price = 299, Description = "Pets break nearby things on their own" },
	{ Key = "TripleHatch", Name = "Triple Hatch", Price = 249, Description = "Hatch 3 eggs at once" },
	{ Key = "MoreEquips", Name = "+4 Pet Equips", Price = 199, Description = "Equip 4 more pets" },
	{ Key = "DoubleCoins", Name = "2x Coins", Price = 249, Description = "Double coins from everything" },
	{ Key = "Lucky", Name = "Lucky Eggs", Price = 199, Description = "2x chance for Golden, Rainbow and HUGE pets" },
}
Config.Products = {
	ExclusiveEgg = 0,
	CoinsSmall = 0,
	CoinsLarge = 0,
	ServerLuck = 0,
	ServerCoins = 0,
}
Config.ProductInfo = {
	{ Key = "ExclusiveEgg", Name = "Exclusive Egg", Price = 99, Description = "Dragon or Unicorn, 1 in 50 chance of HUGE" },
	{ Key = "ServerLuck", Name = "Server Luck (15m)", Price = 79, Description = "2x egg luck for EVERYONE" },
	{ Key = "ServerCoins", Name = "Server 2x Coins (15m)", Price = 79, Description = "2x coins for EVERYONE" },
	{ Key = "CoinsSmall", Name = "Coin Bag", Price = 29, Description = "Coins worth 20 min of farming" },
	{ Key = "CoinsLarge", Name = "Coin Vault", Price = 149, Description = "Coins worth 3 hours of farming" },
}

Config.BaseEquips = 4
Config.ExtraEquips = 4
Config.Storage = 150
Config.GoldenChance = 0.02
Config.RainbowChance = 0.004
Config.HugeChance = 1 / 4000
Config.Variants = {
	normal = { Mult = 1 },
	golden = { Mult = 3, Tint = Color3.fromRGB(255, 205, 40) },
	rainbow = { Mult = 8, Tint = Color3.fromRGB(255, 90, 255) },
}
Config.HugeMult = 40

Config.Pets = {
	{ Id = "pet_dog", Name = "Dog", Rarity = "Common", Power = 1 },
	{ Id = "pet_cat", Name = "Cat", Rarity = "Common", Power = 1.4 },
	{ Id = "pet_bunny", Name = "Bunny", Rarity = "Uncommon", Power = 3 },
	{ Id = "pet_bear", Name = "Bear", Rarity = "Rare", Power = 8 },
	{ Id = "pet_fox", Name = "Fox", Rarity = "Rare", Power = 15 },
	{ Id = "pet_penguin", Name = "Penguin", Rarity = "Epic", Power = 40 },
	{ Id = "pet_dragon", Name = "Dragon", Rarity = "Legendary", Power = 150 },
	{ Id = "pet_unicorn", Name = "Unicorn", Rarity = "Mythic", Power = 400 },
}
Config.Rarities = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(90, 220, 90),
	Rare = Color3.fromRGB(60, 140, 255),
	Epic = Color3.fromRGB(170, 70, 255),
	Legendary = Color3.fromRGB(255, 200, 0),
	Mythic = Color3.fromRGB(255, 50, 50),
}

-- Areas run along +Z. Unlock = coins to open the gate into it. Mult scales breakable HP and coins.
Config.Areas = {
	{ Name = "Spawn Meadow", Unlock = 0, Mult = 1, Color = Color3.fromRGB(110, 200, 100), Egg = { Cost = 100, Chances = { pet_dog = 60, pet_cat = 35, pet_bunny = 5 } } },
	{ Name = "Pine Forest", Unlock = 2_000, Mult = 6, Color = Color3.fromRGB(60, 140, 70), Egg = { Cost = 1_500, Chances = { pet_cat = 50, pet_bunny = 35, pet_bear = 15 } } },
	{ Name = "Sunny Desert", Unlock = 40_000, Mult = 40, Color = Color3.fromRGB(235, 210, 140), Egg = { Cost = 25_000, Chances = { pet_bunny = 50, pet_bear = 35, pet_fox = 15 } } },
	{ Name = "Frozen Peaks", Unlock = 800_000, Mult = 300, Color = Color3.fromRGB(220, 235, 255), Egg = { Cost = 400_000, Chances = { pet_bear = 50, pet_fox = 38, pet_penguin = 12 } } },
	{ Name = "Volcano", Unlock = 20_000_000, Mult = 2500, Color = Color3.fromRGB(90, 40, 35), Egg = { Cost = 8_000_000, Chances = { pet_fox = 55, pet_penguin = 40, pet_dragon = 5 } } },
	{ Name = "Candy Land", Unlock = 600_000_000, Mult = 25000, Color = Color3.fromRGB(255, 170, 220), Egg = { Cost = 200_000_000, Chances = { pet_penguin = 60, pet_dragon = 37, pet_unicorn = 3 } } },
}
Config.ExclusiveEgg = { pet_dragon = 75, pet_unicorn = 25 }

-- Breakables: Health and Coins are multiplied by the area's Mult.
Config.Breakables = {
	{ Id = "coins", Name = "Coin Pile", Health = 6, Coins = 3, Weight = 70, Size = 3, Color = Color3.fromRGB(255, 200, 40) },
	{ Id = "bigcoins", Name = "Big Coin Pile", Health = 30, Coins = 18, Weight = 20, Size = 4.5, Color = Color3.fromRGB(255, 180, 20) },
	{ Id = "chest", Name = "Chest", Health = 200, Coins = 150, Weight = 8, Size = 4, Color = Color3.fromRGB(150, 95, 45) },
	{ Id = "giant", Name = "Giant Chest", Health = 3000, Coins = 2500, Weight = 2, Size = 7, Color = Color3.fromRGB(200, 60, 200) },
}
Config.BreakablesPerArea = 30
Config.AreaLength = 90

Config.PetById = {}
for _, pet in Config.Pets do
	Config.PetById[pet.Id] = pet
end

function Config.PetPower(entry): number
	local pet = Config.PetById[entry.Id]
	if not pet then
		return 0
	end
	local variant = Config.Variants[entry.V or "normal"] or Config.Variants.normal
	return pet.Power * variant.Mult * (if entry.Huge then Config.HugeMult else 1)
end

return Config
