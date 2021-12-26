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
	["7key1scratch"] = 107,
	["10key2scratch"] = 210,
	["14key2scratch"] = 214,
	["24key"] = 24,
	["48key"] = 48,
	["88key"] = 88,
	["4bt2fx2laserleft2laserright"] = 255,
})

Inputmodes.entries_to_list = function(self, entries)
	local inputmodes = {}
	for _, entry in ipairs(entries) do
		table.insert(inputmodes, Inputmodes:to_name(entry.inputmode))
	end
	return inputmodes
end

return Inputmodes
