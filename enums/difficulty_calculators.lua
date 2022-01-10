local enum = require("lapis.db.model").enum

local Difficulty_calculators = enum({
	enps = 0,
	difftable = 1,
	osu_stars = 2,
})

Difficulty_calculators.list = {
	"enps",
	"difftable",
	"osu_stars",
}

return Difficulty_calculators
