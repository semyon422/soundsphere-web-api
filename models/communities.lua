local Model = require("lapis.db.model").Model

local communities = Model:extend(
	"communities",
	{
		relations = {
			{"community_leaderboards", has_many = "community_leaderboards", key = "community_id"},
			{"community_users", has_many = "community_users", key = "community_id"},
			{"community_inputmodes", has_many = "community_inputmodes", key = "community_id"},
		}
	}
)

return communities
