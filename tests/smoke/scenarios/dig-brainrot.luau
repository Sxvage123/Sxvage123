-- Mines straight down through the pit, sells, buys a pickaxe, uses dynamite.
return function(R, game, player)
	local pit = game:GetService("Workspace"):FindFirstChild("Pit")
	local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
	local mine = R.signalFor(remotes.Mine, "OnServerEvent")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local broken = 0
	for _ = 1, 400 do
		-- pick the shallowest block near the pit centre and stand next to it
		local best
		for _, b in pit:GetChildren() do
			if math.abs(b.Position.X) <= 2 and math.abs(b.Position.Z) <= 2 and (not best or b.Position.Y > best.Position.Y) then
				best = b
			end
		end
		if not best then
			break
		end
		root.CFrame = R.D.CFrame.new(best.Position + R.D.Vector3.new(0, 4, 0))
		local before = #pit:GetChildren()
		mine:Fire(player, best)
		R.advance(0.4)
		if not best.Parent then
			broken += 1
		end
		local _ = before
	end
	R.advance(2)
	local depth = tostring(player:GetAttribute("Depth")) .. " y=" .. tostring(root.Position.Y) .. " same=" .. tostring(player.Character and player.Character:FindFirstChild("HumanoidRootPart") == root)
	R.signalFor(remotes.Dynamite, "OnServerEvent"):Fire(player, pit:GetChildren()[1])
	R.advance(1)
	local sell = remotes.Sell
	local ok = R.state[sell].props.OnServerInvoke(player)
	local _ = ok
	return string.format("dig: broke %d blocks, depth attr %s, coins %s, bag %s", broken, tostring(depth), tostring(player:GetAttribute("Coins")), tostring(player:GetAttribute("BagCount")))
end
