local enum = require("lapis.db.model").enum

local Combiners = enum({
	average = 0,
	additive = 1,
	logarithmic = 2,
})

Combiners.list = {
	"average",
	"additive",
	"logarithmic",
}

return Combiners
