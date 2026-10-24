-- Answer 5 questions correctly (the figure id comes with each question), then one wrong.
return function(R, game, player)
	local rs = game:GetService("ReplicatedStorage")
	local Config = R.requireCached(rs.Shared.Config)
	local currentId
	rs.Remotes.Question.OnClientEvent:Connect(function(id)
		currentId = id
	end)
	R.advance(8)
	for _ = 1, 5 do
		for _, b in Config.Brainrots do
			if b.Id == currentId then
				R.signalFor(rs.Remotes.Answer, "OnServerEvent"):Fire(player, b.Name)
			end
		end
		R.advance(1.5)
	end
	R.signalFor(rs.Remotes.Answer, "OnServerEvent"):Fire(player, "Definitely Wrong")
	R.advance(1.5)
	return string.format("guess: correct=%s best=%s", tostring(player:GetAttribute("Correct")), tostring(player:GetAttribute("BestStreak")))
end
