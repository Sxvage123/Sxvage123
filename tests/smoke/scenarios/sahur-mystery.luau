-- Three players: wait for a round, then Sahur bonks the closest innocent and the sheriff shoots Sahur.
return function(R, game, player)
	local p2 = R.addPlayer(2002)
	local p3 = R.addPlayer(2003)
	R.advance(3)
	R.spawnCharacter(p2)
	R.spawnCharacter(p3)
	R.advance(20)
	local players = { player, p2, p3 }
	local sahur, sheriff
	for _, p in players do
		if p:GetAttribute("Role") == "Sahur" then
			sahur = p
		elseif p:GetAttribute("Role") == "Sheriff" then
			sheriff = p
		end
	end
	if not sahur or not sheriff then
		return "mystery: roles not assigned! state=" .. tostring(game:GetService("Workspace"):GetAttribute("RoundState"))
	end
	local remotes = game:GetService("ReplicatedStorage").Remotes
	-- equip tools
	for _, p in { sahur, sheriff } do
		for _, t in p.Backpack:GetChildren() do
			t.Parent = p.Character
		end
	end
	local victim
	for _, p in players do
		if p ~= sahur and p ~= sheriff then
			victim = p
		end
	end
	sahur.Character.HumanoidRootPart.CFrame = R.D.CFrame.new(0, 3, 300)
	victim.Character.HumanoidRootPart.CFrame = R.D.CFrame.new(3, 3, 300)
	R.signalFor(remotes.Bat, "OnServerEvent"):Fire(sahur)
	R.advance(1)
	local victimDead = victim.Character:FindFirstChildOfClass("Humanoid").Health <= 0
	-- sheriff shoots sahur: stub a raycast hit on sahur's root
	R.raycastHandler = function()
		local r = sahur.Character.HumanoidRootPart
		return { Instance = r, Position = r.Position }
	end
	sheriff.Character.Head.CFrame = R.D.CFrame.new(10, 4, 300)
	R.signalFor(remotes.Gun, "OnServerEvent"):Fire(sheriff, R.D.Vector3.new(0, 3, 300))
	R.advance(2)
	R.raycastHandler = nil
	R.advance(8)
	return string.format("mystery: victimDead=%s sahurAlive=%s sheriffWins=%s state=%s", tostring(victimDead), tostring(sahur.Character and sahur.Character:FindFirstChildOfClass("Humanoid") and sahur.Character:FindFirstChildOfClass("Humanoid").Health > 0), tostring(sheriff:GetAttribute("Wins")), tostring(game:GetService("Workspace"):GetAttribute("RoundState")))
end
