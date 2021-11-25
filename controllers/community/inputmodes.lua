local Community_inputmodes = require("models.community_inputmodes")
local Community_leaderboards = require("models.community_leaderboards")
local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local Inputmodes = require("enums.inputmodes")
local preload = require("lapis.db.model").preload

local community_inputmodes_c = {}

community_inputmodes_c.path = "/communities/:community_id/inputmodes"
community_inputmodes_c.methods = {"GET"}
community_inputmodes_c.context = {}
community_inputmodes_c.policies = {
	GET = require("policies.public"),
}

community_inputmodes_c.GET = function(request)
	local params = request.params

	local community_leaderboards = Community_leaderboards:find_all({params.community_id}, "community_id")
	preload(community_leaderboards, {leaderboard = "leaderboard_inputmodes"})

	local actual_inputmodes = {}
	for _, community_leaderboard in ipairs(community_leaderboards) do
		local leaderboard_inputmodes = community_leaderboard.leaderboard.leaderboard_inputmodes
		for _, leaderboard_inputmode in ipairs(leaderboard_inputmodes) do
			actual_inputmodes[leaderboard_inputmode.inputmode] = true
		end
	end

	local community_inputmodes = Community_inputmodes:find_all({params.community_id}, "community_id")

	local cached_inputmodes = {}
	for _, community_inputmode in ipairs(community_inputmodes) do
		cached_inputmodes[community_inputmode.inputmode] = true
	end

	local new_inputmodes = {}
	local old_inputmodes = {}
	for inputmode in pairs(actual_inputmodes) do
		if not cached_inputmodes[inputmode] then
			table.insert(new_inputmodes, inputmode)
		end
	end
	for inputmode in pairs(cached_inputmodes) do
		if not actual_inputmodes[inputmode] then
			table.insert(old_inputmodes, inputmode)
		end
	end

	local db = Community_inputmodes.db
	if old_inputmodes[1] then
		db.delete("community_inputmodes", {inputmode = db.list(old_inputmodes)})
	end
	for _, inputmode in ipairs(new_inputmodes) do
		db.insert("community_inputmodes", {
			community_id = params.community_id,
			inputmode = inputmode,
		})
	end

	local inputmodes = {}
	for inputmode in pairs(actual_inputmodes) do
		table.insert(inputmodes, Inputmodes:to_name(inputmode))
	end

	return 200, {
		total = #inputmodes,
		filtered = #inputmodes,
		inputmodes = inputmodes
	}
end

return community_inputmodes_c
