-- Brainrot Card Clash: open card packs, build the strongest 3-card deck, beat the boss ladder.
-- Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	VIP = 0,
	DoubleGems = 0,
	LuckyPacks = 0,
	FastOpen = 0,
}
Config.PassInfo = {
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "VIP tag, +50% gems, 5-card deck" },
	{ Key = "DoubleGems", Name = "2x Gems", Price = 199, Description = "Double gems from every battle and passive income" },
	{ Key = "LuckyPacks", Name = "Lucky Packs", Price = 299, Description = "2x chance of rare cards and mutations" },
	{ Key = "FastOpen", Name = "Open x5", Price = 149, Description = "Open 5 packs at once" },
}
Config.Products = {
	Gems = 0,
	GemsBig = 0,
	MegaPack = 0,
	ServerLuck = 0,
}
Config.ProductInfo = {
	{ Key = "Gems", Name = "Gem Pouch", Price = 29, Description = "+500 gems (scales with your stage)" },
	{ Key = "GemsBig", Name = "Gem Chest", Price = 149, Description = "+4,000 gems (scales with your stage)" },
	{ Key = "MegaPack", Name = "Mega Pack", Price = 99, Description = "A guaranteed Mythic or better card!" },
	{ Key = "ServerLuck", Name = "2x Server Luck", Price = 79, Description = "Rarer packs for EVERYONE for 15 min" },
}

Config.DeckSize = 3
Config.VIPDeckSize = 5
Config.MaxCards = 150
Config.PassiveGems = 2 -- per 10 seconds, scales with best stage
Config.ServerLuckTime = 900

Config.Rarities = {
	{ Name = "Common", Color = Color3.fromRGB(200, 200, 200), Power = 5, HP = 20, Sell = 2 },
	{ Name = "Rare", Color = Color3.fromRGB(60, 140, 255), Power = 15, HP = 60, Sell = 10 },
	{ Name = "Epic", Color = Color3.fromRGB(170, 70, 255), Power = 40, HP = 160, Sell = 50 },
	{ Name = "Legendary", Color = Color3.fromRGB(255, 200, 0), Power = 110, HP = 450, Sell = 250 },
	{ Name = "Mythic", Color = Color3.fromRGB(255, 50, 50), Power = 300, HP = 1200, Sell = 1200 },
	{ Name = "Brainrot God", Color = Color3.fromRGB(0, 255, 200), Power = 900, HP = 3600, Sell = 6000 },
	{ Name = "Secret", Color = Color3.fromRGB(30, 30, 30), Power = 2500, HP = 10000, Sell = 25000 },
}

-- Mutations multiply a card's stats. Chances are per card opened.
Config.Mutations = {
	{ Name = "Gold", Mult = 2, Chance = 0.06, Color = Color3.fromRGB(255, 215, 0) },
	{ Name = "Diamond", Mult = 3, Chance = 0.02, Color = Color3.fromRGB(120, 230, 255) },
	{ Name = "Rainbow", Mult = 5, Chance = 0.005, Color = Color3.fromRGB(255, 80, 200) },
}

Config.Cards = {
	{ Id = "noobini", Name = "Noobini Pizzanini", Rarity = "Common" },
	{ Id = "lirili", Name = "Lirili Larila", Rarity = "Common" },
	{ Id = "tim_cheese", Name = "Tim Cheese", Rarity = "Common" },
	{ Id = "fluri", Name = "Fluriflura", Rarity = "Common" },
	{ Id = "talpa", Name = "Talpa di Fero", Rarity = "Rare" },
	{ Id = "svinina", Name = "Svinina Bombardino", Rarity = "Rare" },
	{ Id = "pipi_kiwi", Name = "Pipi Kiwi", Rarity = "Rare" },
	{ Id = "trippi", Name = "Trippi Troppi", Rarity = "Epic" },
	{ Id = "tung", Name = "Tung Tung Tung Sahur", Rarity = "Epic" },
	{ Id = "gangster", Name = "Gangster Footera", Rarity = "Epic" },
	{ Id = "patapim", Name = "Brr Brr Patapim", Rarity = "Legendary" },
	{ Id = "chimpanzini", Name = "Chimpanzini Bananini", Rarity = "Legendary" },
	{ Id = "ballerina", Name = "Ballerina Cappuccina", Rarity = "Legendary" },
	{ Id = "frigo", Name = "Frigo Camelo", Rarity = "Mythic" },
	{ Id = "bombardiro", Name = "Bombardiro Crocodilo", Rarity = "Mythic" },
	{ Id = "orangutini", Name = "Orangutini Ananasini", Rarity = "Mythic" },
	{ Id = "cocofanto", Name = "Cocofanto Elefanto", Rarity = "Brainrot God" },
	{ Id = "tralalero", Name = "Tralalero Tralala", Rarity = "Brainrot God" },
	{ Id = "odin_din", Name = "Odin Din Din Dun", Rarity = "Brainrot God" },
	{ Id = "la_vacca", Name = "La Vacca Saturno Saturnita", Rarity = "Secret" },
	{ Id = "skibidi", Name = "Sigma Skibidi Rizzler", Rarity = "Secret" },
	{ Id = "garama", Name = "Garama and Madundung", Rarity = "Secret" },
}

Config.Packs = {
	{ Id = "Basic", Name = "Basic Pack", Cost = 40, Color = Color3.fromRGB(180, 180, 190), Weights = { Common = 70, Rare = 25, Epic = 5 } },
	{ Id = "Silver", Name = "Silver Pack", Cost = 350, Color = Color3.fromRGB(200, 220, 240), Weights = { Rare = 60, Epic = 30, Legendary = 9, Mythic = 1 } },
	{ Id = "Gold", Name = "Gold Pack", Cost = 3_000, Color = Color3.fromRGB(255, 200, 40), Weights = { Epic = 55, Legendary = 35, Mythic = 9, ["Brainrot God"] = 1 } },
	{ Id = "Brainrot", Name = "Brainrot Pack", Cost = 30_000, Color = Color3.fromRGB(255, 60, 180), Weights = { Legendary = 60, Mythic = 30, ["Brainrot God"] = 9, Secret = 1 } },
	{ Id = "Void", Name = "Void Pack", Cost = 300_000, Color = Color3.fromRGB(90, 30, 160), Weights = { Mythic = 60, ["Brainrot God"] = 33, Secret = 7 } },
}

-- The boss ladder. Beat one to unlock the next.
Config.Bosses = {
	{ Id = "noobini", Name = "Big Noobini", HP = 120, Power = 6, Reward = 30 },
	{ Id = "tim_cheese", Name = "Tim Cheese Supreme", HP = 400, Power = 14, Reward = 70 },
	{ Id = "pipi_kiwi", Name = "Pipi Kiwi King", HP = 1_100, Power = 35, Reward = 160 },
	{ Id = "tung", Name = "Tung Tung Overlord", HP = 3_000, Power = 80, Reward = 400 },
	{ Id = "gangster", Name = "Gangster Footera Boss", HP = 8_000, Power = 200, Reward = 1_000 },
	{ Id = "chimpanzini", Name = "Chimpanzini Prime", HP = 22_000, Power = 500, Reward = 2_500 },
	{ Id = "ballerina", Name = "Ballerina Queen", HP = 60_000, Power = 1_300, Reward = 6_000 },
	{ Id = "frigo", Name = "Frigo Camelo Titan", HP = 170_000, Power = 3_500, Reward = 15_000 },
	{ Id = "bombardiro", Name = "Bombardiro Warlord", HP = 480_000, Power = 9_000, Reward = 40_000 },
	{ Id = "tralalero", Name = "Tralalero Leviathan", HP = 1_400_000, Power = 25_000, Reward = 100_000 },
	{ Id = "odin_din", Name = "Odin Din Din Dun God", HP = 4_000_000, Power = 70_000, Reward = 260_000 },
	{ Id = "garama", Name = "Garama the Final Boss", HP = 12_000_000, Power = 200_000, Reward = 700_000 },
}

Config.ById = {}
Config.ByRarity = {}
Config.RarityByName = {}
Config.RarityIndex = {}
for i, r in Config.Rarities do
	Config.RarityByName[r.Name] = r
	Config.RarityIndex[r.Name] = i
	Config.ByRarity[r.Name] = {}
end
for _, c in Config.Cards do
	Config.ById[c.Id] = c
	table.insert(Config.ByRarity[c.Rarity], c)
end

function Config.MutationMult(name: string?): number
	for _, m in Config.Mutations do
		if m.Name == name then
			return m.Mult
		end
	end
	return 1
end

-- Card stats: rarity base, +25% per position within its rarity, times mutation.
function Config.Stats(id: string, mutation: string?): (number, number)
	local card = Config.ById[id]
	if not card then
		return 0, 0
	end
	local r = Config.RarityByName[card.Rarity]
	local pos = table.find(Config.ByRarity[card.Rarity], card) or 1
	local m = (1 + (pos - 1) * 0.25) * Config.MutationMult(mutation)
	return math.floor(r.Power * m), math.floor(r.HP * m)
end

return Config
