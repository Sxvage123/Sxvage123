-- Number formatting helpers shared by every game.
local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Format.Abbreviate(n: number): string
	if n ~= n then
		return "0"
	end
	local negative = n < 0
	n = math.abs(n)
	local index = 1
	while n >= 1000 and index < #SUFFIXES do
		n /= 1000
		index += 1
	end
	local text
	if index == 1 then
		text = tostring(math.floor(n))
	elseif n >= 100 then
		text = string.format("%d%s", math.floor(n), SUFFIXES[index])
	else
		text = string.format("%.2f", math.floor(n * 100) / 100):gsub("%.?0+$", "") .. SUFFIXES[index]
	end
	return (negative and "-" or "") .. text
end

function Format.Cash(n: number): string
	return "$" .. Format.Abbreviate(n)
end

function Format.Time(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	if m >= 60 then
		return string.format("%dh %02dm", math.floor(m / 60), m % 60)
	end
	return string.format("%d:%02d", m, s)
end

return Format
