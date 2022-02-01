local Model = require("lapis.db.model").Model
local toboolean = require("util.toboolean")
local preload = require("lapis.db.model").preload
local Inputmodes = require("enums.inputmodes")

local Communities = Model:extend(
	"communities",
	{
		relations = {
			{"community_leaderboards", has_many = "community_leaderboards", key = "community_id"},
			{"community_users", has_many = "community_users", key = "community_id", deny_auto = true},
			{"community_inputmodes", has_many = "community_inputmodes", key = "community_id"},
		},
		url_params = function(self, req, ...)
			return "community", {community_id = self.id}, ...
		end,
	}
)

local _load = Communities.load
function Communities:load(row)
	row.created_at = tonumber(row.created_at)
	row.is_public = toboolean(row.is_public)
	return _load(self, row)
end

return Communities
