local Model = require("lapis.db.model").Model
local toboolean = require("toboolean")

local Scores = Model:extend(
	"scores",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
			{"notechart", belongs_to = "notecharts", key = "notechart_id"},
			{"modifier", belongs_to = "modifiers", key = "modifier_id"},
			{"inputmode", belongs_to = "inputmodes", key = "inputmode_id"},
		}
	}
)

local _load = Scores.load
function Scores:load(row)
	row.is_valid = toboolean(row.is_valid)
	row.calculated = toboolean(row.calculated)
	row.replay_uploaded = toboolean(row.replay_uploaded)
	return _load(self, row)
end

return Scores
