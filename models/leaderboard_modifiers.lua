local Model = require("lapis.db.model").Model
local toboolean = require("util.toboolean")

local Leaderboard_modifiers = Model:extend(
	"leaderboard_modifiers",
	{
		relations = {
			{"leaderboard", belongs_to = "communities", key = "leaderboard_id"},
		}
	}
)

local _load = Leaderboard_modifiers.load
function Leaderboard_modifiers:load(row)
	row.required = toboolean(row.required)
	return _load(self, row)
end

return Leaderboard_modifiers
