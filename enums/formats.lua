local enum = require("lapis.db.model").enum

local Formats = enum({
	osu = 1,
	quaver = 2,
	bms = 3,
	ksm = 4,
	o2jam = 5,
	midi = 6,
	sph = 255,
})

return Formats
