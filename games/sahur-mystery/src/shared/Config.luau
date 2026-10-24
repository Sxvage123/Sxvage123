-- Sahur Mystery (Murder Mystery style). Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	DoubleCoins = 0,
	VIP = 0,
	CoinMagnet = 0,
}
Config.PassInfo = {
	{ Key = "DoubleCoins", Name = "2x Coins", Price = 199, Description = "Double coins from every round" },
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "+50% coins, VIP tag, bigger coin bag (60)" },
	{ Key = "CoinMagnet", Name = "Coin Magnet", Price = 149, Description = "Coins near you fly into your bag" },
}
Config.Products = {
	SahurPerk = 0,
	SheriffPerk = 0,
	CoinPack = 0,
}
Config.ProductInfo = {
	{ Key = "SahurPerk", Name = "Be Sahur Next", Price = 49, Description = "Hugely boosts your chance to be Tung Tung Sahur next round" },
	{ Key = "SheriffPerk", Name = "Be Sheriff Next", Price = 39, Description = "Hugely boosts your chance to be Sheriff next round" },
	{ Key = "CoinPack", Name = "1,000 Coins", Price = 49, Description = "Open more weapon crates" },
}

Config.MinPlayers = 2
Config.Intermission = 15
Config.RoundTime = 180
Config.BatRange = 7
Config.BatCooldown = 1.0
Config.GunCooldown = 2.5
Config.GunRange = 200
Config.CoinBag = 40
Config.VIPCoinBag = 60
Config.CrateCost = 500
Config.WinCoins = 50

Config.Rarities = {
	{ Name = "Common", Weight = 60, Color = Color3.fromRGB(200, 200, 200) },
	{ Name = "Rare", Weight = 28, Color = Color3.fromRGB(60, 140, 255) },
	{ Name = "Epic", Weight = 9, Color = Color3.fromRGB(170, 70, 255) },
	{ Name = "Legendary", Weight = 2.7, Color = Color3.fromRGB(255, 200, 0) },
	{ Name = "Godly", Weight = 0.3, Color = Color3.fromRGB(255, 50, 50) },
}

-- Skins for the Sahur bat and the Sheriff gun. Kind = "Bat" or "Gun".
Config.Skins = {
	{ Id = "bat_wood", Name = "Wooden Bat", Kind = "Bat", Rarity = "Common", Color = Color3.fromRGB(150, 100, 50), Material = "Wood" },
	{ Id = "bat_metal", Name = "Metal Bat", Kind = "Bat", Rarity = "Common", Color = Color3.fromRGB(170, 175, 185), Material = "Metal" },
	{ Id = "bat_banana", Name = "Banana Bat", Kind = "Bat", Rarity = "Rare", Color = Color3.fromRGB(255, 215, 60), Material = "SmoothPlastic" },
	{ Id = "bat_ice", Name = "Frigo Ice Bat", Kind = "Bat", Rarity = "Epic", Color = Color3.fromRGB(170, 230, 255), Material = "Ice" },
	{ Id = "bat_gold", Name = "Golden Sahur Bat", Kind = "Bat", Rarity = "Legendary", Color = Color3.fromRGB(255, 200, 0), Material = "Neon" },
	{ Id = "bat_void", Name = "Void Bat", Kind = "Bat", Rarity = "Godly", Color = Color3.fromRGB(90, 0, 160), Material = "ForceField" },
	{ Id = "gun_basic", Name = "Revolver", Kind = "Gun", Rarity = "Common", Color = Color3.fromRGB(60, 60, 65), Material = "Metal" },
	{ Id = "gun_pink", Name = "Ballerina Blaster", Kind = "Gun", Rarity = "Rare", Color = Color3.fromRGB(245, 160, 185), Material = "SmoothPlastic" },
	{ Id = "gun_shark", Name = "Tralalero Cannon", Kind = "Gun", Rarity = "Epic", Color = Color3.fromRGB(95, 140, 195), Material = "Metal" },
	{ Id = "gun_croc", Name = "Croc Bomber", Kind = "Gun", Rarity = "Legendary", Color = Color3.fromRGB(70, 140, 60), Material = "Neon" },
	{ Id = "gun_sigma", Name = "Sigma Ray", Kind = "Gun", Rarity = "Godly", Color = Color3.fromRGB(255, 0, 170), Material = "Neon" },
}
Config.SkinById = {}
for _, s in Config.Skins do
	Config.SkinById[s.Id] = s
end
Config.RarityColor = {}
for _, r in Config.Rarities do
	Config.RarityColor[r.Name] = r.Color
end

return Config
