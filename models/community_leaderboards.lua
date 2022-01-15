local Model = require("lapis.db.model").Model
local toboolean = require("util.toboolean")

local Community_leaderboards = Model:extend(
	"community_leaderboards",
	{
		relations = {
			{"community", belongs_to = "communities", key = "community_id"},
			{"leaderboard", belongs_to = "leaderboards", key = "leaderboard_id"},
			{"user", belongs_to = "users", key = "user_id"},
		},
		url_params = function(self, req, ...)
			return "community.leaderboard", {community_id = self.community_id, leaderboard_id = self.leaderboard_id}, ...
		end,
	}
)

local _load = Community_leaderboards.load
function Community_leaderboards:load(row)
	row.is_owner = toboolean(row.is_owner)
	row.accepted = toboolean(row.accepted)
	row.created_at = tonumber(row.created_at)
	return _load(self, row)
end

return Community_leaderboards
