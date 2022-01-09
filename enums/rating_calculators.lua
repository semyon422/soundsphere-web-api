local enum = require("lapis.db.model").enum

local Rating_calculators = enum({
	acc_inv = 0,
	acc_inv_erf = 1,
	osu_mania = 2,
	sdvx = 3,
})

Rating_calculators.list = {
	"acc_inv",
	"acc_inv_erf",
	"osu_mania",
	"sdvx",
}

return Rating_calculators
