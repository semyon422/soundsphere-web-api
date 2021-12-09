local Model = require("lapis.db.model").Model
local toboolean = require("util.toboolean")

local Communities = Model:extend(
	"communities",
	{
		relations = {
			{"community_leaderboards", has_many = "community_leaderboards", key = "community_id"},
			{"community_users", has_many = "community_users", key = "community_id"},
			{"community_inputmodes", has_many = "community_inputmodes", key = "community_id"},
		}
	}
)

local _load = Communities.load
function Communities:load(row)
	row.is_public = toboolean(row.is_public)
	return _load(self, row)
end

return Communities
