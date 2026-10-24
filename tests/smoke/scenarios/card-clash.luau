-- Starter cards, fight stage 1, open a Basic pack, sell a non-deck card.
return function(R, game, player)
	R.advance(4)
	local remotes = game:GetService("ReplicatedStorage").Remotes
	local startCards = player:GetAttribute("CardCount")
	local won = remotes.Fight.OnServerInvoke(player, 1)
	R.advance(11)
	local gemsAfterFight = player:GetAttribute("Gems")
	local opened = remotes.OpenPack.OnServerInvoke(player, "Basic")
	local afterOpen = player:GetAttribute("CardCount")
	local sold = remotes.Sell.OnServerInvoke(player, afterOpen)
	return string.format("cards: start=%s won=%s stage=%s gems=%s opened=%s count=%s sold=%s power=%s", tostring(startCards), tostring(won), tostring(player:GetAttribute("Stage")), tostring(gemsAfterFight), tostring(opened), tostring(afterOpen), tostring(sold), tostring(player:GetAttribute("DeckPower")))
end
