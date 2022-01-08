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
			-- {"inputmodes",
			-- 	fetch = true,
			-- 	preload = function(communities)
			-- 		local preload_community_inputmodes = false
			-- 		if #communities == 0 then
			-- 			return
			-- 		elseif not communities[1].community_inputmodes then
			-- 			preload(communities, "community_inputmodes")
			-- 			preload_community_inputmodes = true
			-- 		end
			-- 		for _, community in ipairs(communities) do
			-- 			if community.community_inputmodes then
			-- 				community.inputmodes = Inputmodes:entries_to_list(community.community_inputmodes)
			-- 			end
			-- 			if preload_community_inputmodes then
			-- 				community.community_inputmodes = nil
			-- 			end
			-- 		end
			-- 	end,
			-- },
		},
		url_params = function(self, req, ...)
			return "community", {community_id = self.id}, ...
		end,
	}
)

local _load = Communities.load
function Communities:load(row)
	row.is_public = toboolean(row.is_public)
	return _load(self, row)
end

return Communities
