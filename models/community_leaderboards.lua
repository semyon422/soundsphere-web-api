local Model = require("lapis.db.model").Model
local toboolean = require("util.toboolean")

local Community_leaderboards = Model:extend(
	"community_leaderboards",
	{
		relations = {
			{"community", belongs_to = "communities", key = "community_id"},
			{"leaderboard", belongs_to = "leaderboards", key = "leaderboard_id"},
			{"sender", belongs_to = "users", key = "sender_id"},
		}
	}
)

local _load = Community_leaderboards.load
function Community_leaderboards:load(row)
	row.is_owner = toboolean(row.is_owner)
	row.accepted = toboolean(row.accepted)
	return _load(self, row)
end

return Community_leaderboards
