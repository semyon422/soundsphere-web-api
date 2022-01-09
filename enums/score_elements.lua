local enum = require("lapis.db.model").enum

local Score_elements = enum({
	score = 0,
	accuracy = 1,
	rating = 2,
})

return Score_elements
