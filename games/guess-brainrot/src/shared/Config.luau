-- Guess the Brainrot: a figure appears, pick its name from 4 choices. Streaks, levels, coins.
local Config = {}

Config.Passes = { DoubleCoins = 0, VIP = 0, ExtraTime = 0, AutoHint = 0 }
Config.PassInfo = {
	{ Key = "DoubleCoins", Name = "2x Coins", Price = 99, Description = "Double coins for every right answer" },
	{ Key = "VIP", Name = "VIP", Price = 199, Description = "VIP tag, +50% coins" },
	{ Key = "ExtraTime", Name = "Extra Time", Price = 99, Description = "+5 seconds on every question" },
	{ Key = "AutoHint", Name = "Auto Hint", Price = 249, Description = "One wrong answer is removed on every question" },
}
Config.Products = { Hint = 0, Skip = 0, Coins = 0 }
Config.ProductInfo = {
	{ Key = "Hint", Name = "50/50 Hint", Price = 9, Description = "Removes two wrong answers" },
	{ Key = "Skip", Name = "Skip", Price = 15, Description = "Skip this one and keep your streak" },
	{ Key = "Coins", Name = "Coin Bag", Price = 49, Description = "+1,000 coins" },
}

Config.QuestionTime = 12
Config.Coins = 10

Config.Brainrots = {
	{ Id = "noobini", Name = "Noobini Pizzanini" },
	{ Id = "lirili", Name = "Lirili Larila" },
	{ Id = "tim_cheese", Name = "Tim Cheese" },
	{ Id = "fluri", Name = "Fluriflura" },
	{ Id = "talpa", Name = "Talpa di Fero" },
	{ Id = "svinina", Name = "Svinina Bombardino" },
	{ Id = "pipi_kiwi", Name = "Pipi Kiwi" },
	{ Id = "trippi", Name = "Trippi Troppi" },
	{ Id = "tung", Name = "Tung Tung Tung Sahur" },
	{ Id = "gangster", Name = "Gangster Footera" },
	{ Id = "patapim", Name = "Brr Brr Patapim" },
	{ Id = "chimpanzini", Name = "Chimpanzini Bananini" },
	{ Id = "ballerina", Name = "Ballerina Cappuccina" },
	{ Id = "cappuccino", Name = "Cappuccino Assassino" },
	{ Id = "frigo", Name = "Frigo Camelo" },
	{ Id = "bombardiro", Name = "Bombardiro Crocodilo" },
	{ Id = "orangutini", Name = "Orangutini Ananasini" },
	{ Id = "cocofanto", Name = "Cocofanto Elefanto" },
	{ Id = "tralalero", Name = "Tralalero Tralala" },
	{ Id = "odin_din", Name = "Odin Din Din Dun" },
	{ Id = "la_vacca", Name = "La Vacca Saturno Saturnita" },
	{ Id = "skibidi", Name = "Sigma Skibidi Rizzler" },
	{ Id = "garama", Name = "Garama and Madundung" },
}

return Config
