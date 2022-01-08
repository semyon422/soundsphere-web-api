local Model = require("lapis.db.model").Model
local preload = require("lapis.db.model").preload
local Inputmodes = require("enums.inputmodes")

local Leaderboards = Model:extend(
	"leaderboards",
	{
		relations = {
			{"leaderboard_difftables", has_many = "leaderboard_difftables", key = "leaderboard_id"},
			{"leaderboard_inputmodes", has_many = "leaderboard_inputmodes", key = "leaderboard_id"},
			{"leaderboard_requirements", has_many = "leaderboard_requirements", key = "leaderboard_id"},
			{"community_leaderboards", has_many = "community_leaderboards", key = "leaderboard_id"},
			{"top_user", belongs_to = "users", key = "top_user_id"},
			-- {"inputmodes",
			-- 	fetch = true,
			-- 	preload = function(leaderboards)
			-- 		local preload_leaderboard_inputmodes = false
			-- 		if #leaderboards == 0 then
			-- 			return
			-- 		elseif not leaderboards[1].leaderboard_inputmodes then
			-- 			preload(leaderboards, "leaderboard_inputmodes")
			-- 			preload_leaderboard_inputmodes = true
			-- 		end
			-- 		for _, leaderboard in ipairs(leaderboards) do
			-- 			if leaderboard.leaderboard_inputmodes then
			-- 				leaderboard.inputmodes = Inputmodes:entries_to_list(leaderboard.leaderboard_inputmodes)
			-- 			end
			-- 			if preload_leaderboard_inputmodes then
			-- 				leaderboard.leaderboard_inputmodes = nil
			-- 			end
			-- 		end
			-- 	end,
			-- },
		},
		url_params = function(self, req, ...)
			return "leaderboard", {leaderboard_id = self.id}, ...
		end,
	}
)

return Leaderboards
