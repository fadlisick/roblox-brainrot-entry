-- FormatMoney: short human-readable money strings for HUDs and labels.
-- 999 -> "$999", 1500 -> "$1.5K", 2_500_000 -> "$2.5M", 1_200_000_000 -> "$1.2B".

local FormatMoney = {}

local SUFFIXES = {
	{ threshold = 1e12, suffix = "T" },
	{ threshold = 1e9, suffix = "B" },
	{ threshold = 1e6, suffix = "M" },
	{ threshold = 1e3, suffix = "K" },
}

-- Format a number of dollars as "$1.5K" style. Always returns a string.
function FormatMoney.format(amount)
	local value = math.floor(tonumber(amount) or 0)
	if value < 0 then
		return "-$" .. FormatMoney.format(-value):sub(2)
	end
	for _, entry in ipairs(SUFFIXES) do
		if value >= entry.threshold then
			local scaled = value / entry.threshold
			if scaled >= 100 then
				return string.format("$%d%s", math.floor(scaled + 0.5), entry.suffix)
			else
				return string.format("$%.1f%s", math.floor(scaled * 10 + 0.5) / 10, entry.suffix)
			end
		end
	end
	return "$" .. tostring(value)
end

-- Format a per-second rate, e.g. "$125/s".
function FormatMoney.formatRate(amount)
	return FormatMoney.format(amount) .. "/s"
end

return FormatMoney
