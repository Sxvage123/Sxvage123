-- Find the Brainrots. Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	Radar = 0,
	Teleporter = 0,
	SpeedCoil = 0,
	GravityCoil = 0,
}
Config.PassInfo = {
	{ Key = "Radar", Name = "Brainrot Radar", Price = 199, Description = "A beam always points to the nearest brainrot you haven't found" },
	{ Key = "Teleporter", Name = "Teleporter", Price = 99, Description = "Teleport to any zone instantly" },
	{ Key = "SpeedCoil", Name = "Speed Coil", Price = 79, Description = "Run 75% faster" },
	{ Key = "GravityCoil", Name = "Gravity Coil", Price = 79, Description = "Jump way higher" },
}
Config.Products = {
	Hint = 0,
	AutoFind = 0,
}
Config.ProductInfo = {
	{ Key = "Hint", Name = "Show Me One", Price = 15, Description = "A beam leads you to an unfound brainrot for 60s" },
	{ Key = "AutoFind", Name = "Instant Find", Price = 49, Description = "Instantly collect a random brainrot you're missing" },
}

Config.Names = {
	"Noobini Pizzanini", "Lirili Larila", "Tim Cheese", "Fluriflura", "Talpa di Fero", "Svinina Bombardino",
	"Pipi Kiwi", "Trippi Troppi", "Tung Tung Tung Sahur", "Gangster Footera", "Brr Brr Patapim",
	"Chimpanzini Bananini", "Ballerina Cappuccina", "Cappuccino Assassino", "Frigo Camelo",
	"Bombardiro Crocodilo", "Orangutini Ananasini", "Cocofanto Elefanto", "Tralalero Tralala",
	"Odin Din Din Dun", "La Vacca Saturno", "Garama", "Madundung", "Skibidi Toilet", "Rizzler",
	"Gyatt Gator", "Ohio Ohio", "Sigma Boy", "Mewing Mango", "Fanum Tax Fox", "Bombombini Gusini",
	"Burbaloni Lulilolli", "Glorbo Fruttodrillo", "Trulimero Trulicina", "Bobritto Bandito",
	"Zibra Zubra Zibralini", "Tric Trac Baraboom", "Spaghetti Tualetti", "Il Cacto Hipopotamo", "Blueberrinni Octopussini",
}

Config.ZoneSpawns = {
	{ Name = "Town", Position = Vector3.new(0, 4, 0) },
	{ Name = "Forest", Position = Vector3.new(220, 4, 0) },
	{ Name = "Desert", Position = Vector3.new(-220, 4, 0) },
	{ Name = "Pond", Position = Vector3.new(0, 4, 95) },
	{ Name = "Sky Islands", Position = Vector3.new(0, 4, -100) },
}

return Config
