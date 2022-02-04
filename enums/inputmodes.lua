local enum = require("lapis.db.model").enum

local Inputmodes = enum({
	["undefined"] = 0,
	["1key"] = 1,
	["2key"] = 2,
	["3key"] = 3,
	["4key"] = 4,
	["5key"] = 5,
	["6key"] = 6,
	["7key"] = 7,
	["8key"] = 8,
	["9key"] = 9,
	["10key"] = 10,
	["12key"] = 12,
	["14key"] = 14,
	["16key"] = 16,
	["18key"] = 18,
	["20key"] = 20,
	["5key1scratch"] = 105,
	["5key1pedal1scratch"] = 115,
	["7key1scratch"] = 107,
	["7key1pedal1scratch"] = 117,
	["10key2scratch"] = 210,
	["14key2scratch"] = 214,
	["24key"] = 24,
	["48key"] = 48,
	["88key"] = 88,
	["4bt2fx2ll2lr"] = 255,
})

Inputmodes.list = {
	"undefined",
	"1key",
	"2key",
	"3key",
	"4key",
	"5key",
	"6key",
	"7key",
	"8key",
	"9key",
	"10key",
	"12key",
	"14key",
	"16key",
	"18key",
	"20key",
	"5key1scratch",
	"5key1pedal1scratch",
	"7key1scratch",
	"7key1pedal1scratch",
	"10key2scratch",
	"14key2scratch",
	"24key",
	"48key",
	"88key",
	"4bt2fx2ll2lr",
}

Inputmodes.entries_to_list = function(self, entries)
	local inputmodes = {}
	for _, entry in ipairs(entries) do
		table.insert(inputmodes, Inputmodes:to_name(entry.inputmode))
	end
	return inputmodes
end

return Inputmodes
