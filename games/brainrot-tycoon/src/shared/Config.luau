-- Brainrot Tycoon. Replace the 0s with real IDs from the Creator Dashboard.
local Config = {}

Config.Passes = {
	DoubleCash = 0,
	AutoCollect = 0,
	FastDroppers = 0,
	VIP = 0,
}
Config.PassInfo = {
	{ Key = "DoubleCash", Name = "2x Cash", Price = 199, Description = "Double all tycoon income forever" },
	{ Key = "AutoCollect", Name = "Auto Collect", Price = 149, Description = "Cash goes straight to you, no pad needed" },
	{ Key = "FastDroppers", Name = "Fast Droppers", Price = 249, Description = "All droppers drop 2x as fast" },
	{ Key = "VIP", Name = "VIP", Price = 299, Description = "Exclusive Sigma VIP Dropper + VIP tag" },
}
Config.Products = {
	CashSmall = 0,
	CashLarge = 0,
	GoldenHour = 0,
}
Config.ProductInfo = {
	{ Key = "CashSmall", Name = "Cash Stack", Price = 29, Description = "10 min of income (min $1K)" },
	{ Key = "CashLarge", Name = "Cash Truck", Price = 149, Description = "2 hours of income (min $50K)" },
	{ Key = "GoldenHour", Name = "Golden Hour", Price = 79, Description = "5x cash for 15 minutes" },
}

Config.DropInterval = 2
Config.RebirthBonus = 1

-- Dropper slots along the conveyor (local X). Conveyor runs along local +X at z = 0.
Config.DropperX = { -26, -18, -10, -2, -26, -18, -10, -2 }
Config.DropperSide = { -1, -1, -1, -1, 1, 1, 1, 1 }

-- Purchase chain. Kind: Dropper (Slot, Value), Upgrader (X, Mult), Build (Parts).
-- Each button appears once its Requires item is owned.
Config.Items = {
	{ Id = "d1", Name = "Noobini Dropper", Cost = 0, Kind = "Dropper", Slot = 1, Value = 1, Color = Color3.fromRGB(255, 180, 90) },
	{ Id = "d2", Name = "Lirili Dropper", Cost = 50, Requires = "d1", Kind = "Dropper", Slot = 2, Value = 3, Color = Color3.fromRGB(120, 200, 90) },
	{ Id = "floor", Name = "Floor", Cost = 120, Requires = "d2", Kind = "Build", Parts = {
		{ Size = Vector3.new(80, 1, 80), Offset = CFrame.new(0, 0.5, 0), Color = Color3.fromRGB(220, 220, 230), Material = Enum.Material.SmoothPlastic },
	} },
	{ Id = "d3", Name = "Tim Cheese Dropper", Cost = 250, Requires = "floor", Kind = "Dropper", Slot = 3, Value = 7, Color = Color3.fromRGB(255, 230, 80) },
	{ Id = "walls", Name = "Walls", Cost = 600, Requires = "d3", Kind = "Build", Parts = {
		{ Size = Vector3.new(80, 12, 1), Offset = CFrame.new(0, 7, 40), Color = Color3.fromRGB(90, 160, 255) },
		{ Size = Vector3.new(1, 12, 80), Offset = CFrame.new(-40, 7, 0), Color = Color3.fromRGB(90, 160, 255) },
		{ Size = Vector3.new(1, 12, 80), Offset = CFrame.new(40, 7, 0), Color = Color3.fromRGB(90, 160, 255) },
	} },
	{ Id = "u1", Name = "Rizz Upgrader (x2)", Cost = 1_200, Requires = "walls", Kind = "Upgrader", X = 8, Mult = 2, Color = Color3.fromRGB(0, 255, 200) },
	{ Id = "d4", Name = "Tung Tung Dropper", Cost = 2_500, Requires = "u1", Kind = "Dropper", Slot = 4, Value = 15, Color = Color3.fromRGB(190, 130, 70) },
	{ Id = "statue", Name = "Tung Tung Statue", Cost = 4_000, Requires = "d4", Kind = "Build", Parts = {
		{ Size = Vector3.new(4, 2, 4), Offset = CFrame.new(-30, 2, 30), Color = Color3.fromRGB(80, 80, 80) },
		{ Size = Vector3.new(3, 9, 3), Offset = CFrame.new(-30, 7.5, 30), Color = Color3.fromRGB(190, 130, 70), Material = Enum.Material.Wood },
		{ Size = Vector3.new(0.6, 6, 0.6), Offset = CFrame.new(-28, 8, 30) * CFrame.Angles(0, 0, math.rad(-30)), Color = Color3.fromRGB(120, 80, 40), Material = Enum.Material.Wood },
	} },
	{ Id = "d5", Name = "Tralalero Dropper", Cost = 8_000, Requires = "statue", Kind = "Dropper", Slot = 5, Value = 40, Color = Color3.fromRGB(70, 160, 255) },
	{ Id = "u2", Name = "Sigma Upgrader (x2)", Cost = 18_000, Requires = "d5", Kind = "Upgrader", X = 14, Mult = 2, Color = Color3.fromRGB(255, 0, 170) },
	{ Id = "d6", Name = "Patapim Dropper", Cost = 40_000, Requires = "u2", Kind = "Dropper", Slot = 6, Value = 110, Color = Color3.fromRGB(70, 140, 60) },
	{ Id = "lamps", Name = "Neon Lamps", Cost = 70_000, Requires = "d6", Kind = "Build", Parts = {
		{ Size = Vector3.new(1, 14, 1), Offset = CFrame.new(-36, 8, -36), Color = Color3.fromRGB(255, 255, 150), Material = Enum.Material.Neon },
		{ Size = Vector3.new(1, 14, 1), Offset = CFrame.new(36, 8, -36), Color = Color3.fromRGB(255, 255, 150), Material = Enum.Material.Neon },
		{ Size = Vector3.new(1, 14, 1), Offset = CFrame.new(-36, 8, 36), Color = Color3.fromRGB(255, 255, 150), Material = Enum.Material.Neon },
		{ Size = Vector3.new(1, 14, 1), Offset = CFrame.new(36, 8, 36), Color = Color3.fromRGB(255, 255, 150), Material = Enum.Material.Neon },
	} },
	{ Id = "d7", Name = "Bombardiro Dropper", Cost = 150_000, Requires = "lamps", Kind = "Dropper", Slot = 7, Value = 320, Color = Color3.fromRGB(60, 120, 60) },
	{ Id = "u3", Name = "Gyatt Upgrader (x3)", Cost = 400_000, Requires = "d7", Kind = "Upgrader", X = 20, Mult = 3, Color = Color3.fromRGB(255, 200, 0) },
	{ Id = "d8", Name = "Cocofanto Dropper", Cost = 1_000_000, Requires = "u3", Kind = "Dropper", Slot = 8, Value = 900, Color = Color3.fromRGB(150, 150, 170) },
	{ Id = "throne", Name = "Sigma Throne", Cost = 2_500_000, Requires = "d8", Kind = "Build", Parts = {
		{ Size = Vector3.new(8, 2, 8), Offset = CFrame.new(28, 2, 30), Color = Color3.fromRGB(255, 215, 0), Material = Enum.Material.Neon },
		{ Size = Vector3.new(8, 10, 1), Offset = CFrame.new(28, 8, 34), Color = Color3.fromRGB(255, 215, 0) },
		{ Size = Vector3.new(6, 1, 6), Offset = CFrame.new(28, 3.5, 30), Color = Color3.fromRGB(170, 0, 0), Material = Enum.Material.Fabric },
	} },
	{ Id = "golden", Name = "Golden Brainrot (Finish!)", Cost = 6_000_000, Requires = "throne", Kind = "Build", Parts = {
		{ Size = Vector3.new(10, 10, 10), Offset = CFrame.new(0, 12, 30), Color = Color3.fromRGB(255, 215, 0), Material = Enum.Material.Neon, Shape = Enum.PartType.Ball },
	} },
}

-- VIP pass dropper (no button: granted by pass). Sits on its own spout at the conveyor start.
Config.VIPDropper = { Id = "vip", Name = "Sigma VIP Dropper", Kind = "Dropper", Slot = 0, Value = 25, Color = Color3.fromRGB(255, 215, 0) }

Config.ItemById = {}
for _, item in Config.Items do
	Config.ItemById[item.Id] = item
end

function Config.RebirthMult(rebirths: number): number
	return 1 + rebirths * Config.RebirthBonus
end

return Config
