local enum = require("lapis.db.model").enum

local Combiners = enum({
	average = 0,
	logarithmic = 1,
	additive = 2,
	osu = 3,
	sdvx = 4,
})

Combiners.list = {
	"average",
	"logarithmic",
	"additive",
	"osu",
	"sdvx",
}

return Combiners
