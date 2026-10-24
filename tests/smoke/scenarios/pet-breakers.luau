-- Target a coin pile with the starter pets until it breaks, then hatch an egg.
return function(R, game, player)
	local folder = game:GetService("Workspace"):FindFirstChild("Breakables")
	local remotes = game:GetService("ReplicatedStorage").Remotes
	local target = nil
	for _, b in folder:GetChildren() do
		if b:GetAttribute("Area") == 1 and b.Name == "coins" then
			target = b
			break
		end
	end
	player.Character.HumanoidRootPart.CFrame = R.D.CFrame.new(target.Position + R.D.Vector3.new(3, 2, 0))
	R.signalFor(remotes.Target, "OnServerEvent"):Fire(player, target)
	R.advance(8)
	local broke = target.Parent == nil
	local coins = player:GetAttribute("Coins")
	return string.format("pets: broke=%s coins=%s power=%s", tostring(broke), tostring(coins), tostring(player:GetAttribute("Power")))
end
