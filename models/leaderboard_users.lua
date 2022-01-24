local Model = require("lapis.db.model").Model
local toboolean = require("util.toboolean")

local Leaderboard_users = Model:extend(
	"leaderboard_users",
	{
		relations = {
			{"leaderboard", belongs_to = "leaderboards", key = "leaderboard_id"},
			{"user", belongs_to = "users", key = "user_id"},
		},
		url_params = function(self, req, ...)
			return "leaderboard.user", {leaderboard_id = self.leaderboard_id, user_id = self.user_id}, ...
		end,
	}
)

local _load = Leaderboard_users.load
function Leaderboard_users:load(row)
	row.active = toboolean(row.active)
	row.latest_activity = tonumber(row.latest_activity)
	return _load(self, row)
end

return Leaderboard_users
