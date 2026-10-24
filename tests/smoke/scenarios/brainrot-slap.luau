-- Two players on the island: the first slaps the second off the edge.
return function(R, game, player)
	local other = R.addPlayer(2002)
	R.advance(3)
	R.spawnCharacter(other)
	R.advance(2)
	local root = player.Character.HumanoidRootPart
	local oroot = other.Character.HumanoidRootPart
	root.CFrame = R.D.CFrame.new(0, 3, 0)
	oroot.CFrame = R.D.CFrame.new(4, 3, 0)
	-- equip glove
	local glove = player.Backpack:FindFirstChild("Glove")
	if glove then
		glove.Parent = player.Character
	end
	local slaps = R.signalFor(game:GetService("ReplicatedStorage").Remotes.Slap, "OnServerEvent")
	slaps:Fire(player, other)
	R.advance(1)
	-- push them into the void as if the knockback landed
	oroot.CFrame = R.D.CFrame.new(200, -60, 0)
	R.advance(1)
	return string.format("slap: slaps=%s kills=%s otherHealth=%s", tostring(player:GetAttribute("Slaps")), tostring(player:GetAttribute("Kills")), tostring(other.Character and other.Character:FindFirstChildOfClass("Humanoid") and other.Character:FindFirstChildOfClass("Humanoid").Health))
end
