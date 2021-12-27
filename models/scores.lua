local Model = require("lapis.db.model").Model
local toboolean = require("util.toboolean")

local Scores = Model:extend(
	"scores",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
			{"notechart", belongs_to = "notecharts", key = "notechart_id"},
			{"modifierset", belongs_to = "modifiersets", key = "modifierset_id"},
		},
		url_params = function(self, req, ...)
			return "score", {score_id = self.id}, ...
		end,
	}
)

local _load = Scores.load
function Scores:load(row)
	row.is_valid = toboolean(row.is_valid)
	row.calculated = toboolean(row.calculated)
	row.replay_uploaded = toboolean(row.replay_uploaded)
	row.created_at = tonumber(row.created_at)
	return _load(self, row)
end

return Scores
