local enum = require("lapis.db.model").enum
local Modifiers = require("enums.modifiers")
local Score_elements = require("enums.score_elements")

local Requirements = enum({
	modifier = 0,
	score = 1,
})

Requirements.list = {
	"modifier",
	"score",
}

Requirements.get_key_enum = function(self, requirement)
	if requirement == "modifier" or requirement == 0 then
		return Modifiers
	elseif requirement == "score" or requirement == 1 then
		return Score_elements
	end
end

return Requirements
