-- Brainrot Ball (Blade Ball style). Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	DoubleCoins = 0,
	VIP = 0,
	QuickDash = 0,
	LuckyCrates = 0,
}
Config.PassInfo = {
	{ Key = "DoubleCoins", Name = "2x Coins", Price = 199, Description = "Double coins from wins and kills" },
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "+50% coins, VIP tag, gold trail" },
	{ Key = "QuickDash", Name = "Quick Dash", Price = 99, Description = "Dash cooldown 3s instead of 6s" },
	{ Key = "LuckyCrates", Name = "Lucky Crates", Price = 199, Description = "2x chance for Epic+ swords" },
}
Config.Products = {
	CoinsSmall = 0,
	CoinsLarge = 0,
	Respawn = 0,
}
Config.ProductInfo = {
	{ Key = "CoinsSmall", Name = "1,000 Coins", Price = 49, Description = "Open more sword crates" },
	{ Key = "CoinsLarge", Name = "6,000 Coins", Price = 249, Description = "Best value coin pile" },
	{ Key = "Respawn", Name = "Second Chance", Price = 29, Description = "Jump back into this round!" },
}

Config.MinPlayers = 2
Config.Intermission = 12
Config.BallStartSpeed = 30
Config.BallSpeedGain = 4
Config.BallMaxSpeed = 180
Config.ParryWindow = 0.45
Config.ParryCooldown = 0.9
Config.DashCooldown = 6
Config.WinCoins = 60
Config.KillCoins = 15
Config.CrateCost = 400

Config.Rarities = {
	{ Name = "Common", Weight = 60, Color = Color3.fromRGB(200, 200, 200) },
	{ Name = "Rare", Weight = 28, Color = Color3.fromRGB(60, 140, 255) },
	{ Name = "Epic", Weight = 9, Color = Color3.fromRGB(170, 70, 255) },
	{ Name = "Legendary", Weight = 2.7, Color = Color3.fromRGB(255, 200, 0) },
	{ Name = "Mythic", Weight = 0.3, Color = Color3.fromRGB(255, 50, 50) },
}

Config.Swords = {
	{ Id = "stick", Name = "Tung Stick", Rarity = "Common", Color = Color3.fromRGB(150, 100, 50), Material = Enum.Material.Wood },
	{ Id = "pizza", Name = "Pizza Slicer", Rarity = "Common", Color = Color3.fromRGB(255, 200, 80), Material = Enum.Material.SmoothPlastic },
	{ Id = "cheese", Name = "Cheese Blade", Rarity = "Common", Color = Color3.fromRGB(255, 230, 90), Material = Enum.Material.SmoothPlastic },
	{ Id = "tralala", Name = "Shark Fin", Rarity = "Rare", Color = Color3.fromRGB(80, 160, 255), Material = Enum.Material.Metal },
	{ Id = "banana", Name = "Banana Katana", Rarity = "Rare", Color = Color3.fromRGB(255, 230, 40), Material = Enum.Material.SmoothPlastic },
	{ Id = "croc", Name = "Croc Cutter", Rarity = "Epic", Color = Color3.fromRGB(50, 150, 60), Material = Enum.Material.Metal },
	{ Id = "frost", Name = "Frigo Frostblade", Rarity = "Epic", Color = Color3.fromRGB(170, 230, 255), Material = Enum.Material.Ice },
	{ Id = "rizz", Name = "Rizz Rapier", Rarity = "Legendary", Color = Color3.fromRGB(255, 120, 220), Material = Enum.Material.Neon },
	{ Id = "gold", Name = "Golden Sahur Bat", Rarity = "Legendary", Color = Color3.fromRGB(255, 200, 0), Material = Enum.Material.Neon },
	{ Id = "sigma", Name = "Sigma Saber", Rarity = "Mythic", Color = Color3.fromRGB(255, 0, 170), Material = Enum.Material.ForceField },
}

Config.SwordById = {}
for _, s in Config.Swords do
	Config.SwordById[s.Id] = s
end
Config.RarityColor = {}
for _, r in Config.Rarities do
	Config.RarityColor[r.Name] = r.Color
end

return Config
