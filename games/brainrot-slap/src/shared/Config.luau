-- Brainrot Slap Battles. Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	DoubleSlaps = 0,
	VIP = 0,
	SigmaGlove = 0,
	BombGlove = 0,
}
Config.PassInfo = {
	{ Key = "DoubleSlaps", Name = "2x Slaps", Price = 199, Description = "Earn double slaps from every hit and kill" },
	{ Key = "VIP", Name = "VIP", Price = 249, Description = "+50% slaps, VIP tag, gold glove trail" },
	{ Key = "SigmaGlove", Name = "Sigma Glove", Price = 399, Description = "Massive knockback + shockwave ability" },
	{ Key = "BombGlove", Name = "Bombardiro Glove", Price = 249, Description = "Every slap explodes and launches nearby players" },
}
Config.Products = {
	SlapsSmall = 0,
	SlapsLarge = 0,
	Shield = 0,
}
Config.ProductInfo = {
	{ Key = "SlapsSmall", Name = "500 Slaps", Price = 29, Description = "Unlock gloves faster" },
	{ Key = "SlapsLarge", Name = "4,000 Slaps", Price = 149, Description = "Best value slap pile" },
	{ Key = "Shield", Name = "Anti-Slap Shield (2m)", Price = 39, Description = "Nobody can slap you for 2 minutes" },
}

Config.SlapRange = 9
Config.SlapReward = 1
Config.KillReward = 10
Config.KillCreditSeconds = 8
Config.VoidHeight = -40

-- Kind: "slap" (single target), "aoe" (everyone around you), "dash" (ability dashes you forward),
-- "explode" (slap target + blast nearby). Cost in slaps; Pass = Robux-only.
Config.Gloves = {
	{ Id = "default", Name = "Default", Power = 70, Cooldown = 0.8, Kind = "slap", Cost = 0, Color = Color3.fromRGB(240, 210, 180) },
	{ Id = "tung", Name = "Tung Tung Bat", Power = 110, Cooldown = 1.3, Kind = "slap", Cost = 100, Color = Color3.fromRGB(170, 115, 60) },
	{ Id = "tralalero", Name = "Tralalero Fin", Power = 80, Cooldown = 0.8, Kind = "dash", Cost = 300, Color = Color3.fromRGB(95, 140, 195), Ability = 5 },
	{ Id = "ballerina", Name = "Ballerina Spin", Power = 75, Cooldown = 2.0, Kind = "aoe", Cost = 800, Color = Color3.fromRGB(245, 160, 185) },
	{ Id = "chimp", Name = "Banana Peel", Power = 95, Cooldown = 1.0, Kind = "slap", Cost = 1500, Color = Color3.fromRGB(255, 215, 60) },
	{ Id = "bomb", Name = "Bombardiro Glove", Power = 100, Cooldown = 1.6, Kind = "explode", Pass = "BombGlove", Color = Color3.fromRGB(70, 135, 70) },
	{ Id = "sigma", Name = "Sigma Glove", Power = 170, Cooldown = 1.2, Kind = "aoe", Pass = "SigmaGlove", Color = Color3.fromRGB(255, 0, 170) },
}

Config.GloveById = {}
for i, g in Config.Gloves do
	g.Index = i
	Config.GloveById[g.Id] = g
end

return Config
