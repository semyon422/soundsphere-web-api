local Community_leaderboards = require("models.community_leaderboards")
local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local Inputmodes = require("enums.inputmodes")
local preload = require("lapis.db.model").preload

local community_leaderboards_c = {}

community_leaderboards_c.path = "/communities/:community_id/leaderboards"
community_leaderboards_c.methods = {"GET"}
community_leaderboards_c.context = {}
community_leaderboards_c.policies = {
	GET = require("policies.public"),
}

community_leaderboards_c.GET = function(request)
	local params = request.params
    local community_leaderboards = Community_leaderboards:find_all({params.community_id}, "community_id")
	preload(community_leaderboards, {leaderboard = "leaderboard_inputmodes"})

	local leaderboards = {}
	for _, community_leaderboard in ipairs(community_leaderboards) do
		local leaderboard = community_leaderboard.leaderboard
		leaderboard.inputmodes = Leaderboard_inputmodes:get_inputmodes(leaderboard.leaderboard_inputmodes)
		leaderboard.leaderboard_inputmodes = nil
		leaderboard.is_owner = community_leaderboard.is_owner
		table.insert(leaderboards, leaderboard)
	end

	local count = #community_leaderboards

	return 200, {
		total = count,
		filtered = count,
		leaderboards = leaderboards
	}
end

return community_leaderboards_c
