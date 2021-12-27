local Model = require("lapis.db.model").Model
local toboolean = require("util.toboolean")

local Leaderboard_requirements = Model:extend(
	"leaderboard_requirements",
	{
		relations = {
			{"leaderboard", belongs_to = "communities", key = "leaderboard_id"},
		},
		url_params = function(self, req, ...)
			return "leaderboard.requirement", {
				leaderboard_id = req.params.leaderboard_id,
				requirement_id = self.id
			}, ...
		end,
	}
)

local _load = Leaderboard_requirements.load
function Leaderboard_requirements:load(row)
	row.required = toboolean(row.required)
	return _load(self, row)
end

return Leaderboard_requirements
