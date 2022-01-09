local enum = require("lapis.db.model").enum

local Difficulty_calculators = enum({
	enps = 0,
	table_level = 1,
	osu_stars = 2,
})

Difficulty_calculators.list = {
	"enps",
	"table_level",
	"osu_stars",
}

return Difficulty_calculators
