local Leaderboards = require("models.leaderboards")
local Community_leaderboards = require("models.community_leaderboards")
local Roles = require("models.roles")
local preload = require("lapis.db.model").preload

local leaderboards_c = {}

leaderboards_c.path = "/leaderboards"
leaderboards_c.methods = {"GET", "POST"}
leaderboards_c.context = {}
leaderboards_c.policies = {
	GET = require("policies.public"),
	POST = require("policies.public"),
}

leaderboards_c.GET = function(request)
	local params = request.params
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = Leaderboards:paginated(
		"order by id asc",
		{
			per_page = per_page,
			prepare_results = function(entries)
				preload(entries, {leaderboard_inputmodes = "inputmode"})
				return entries
			end
		}
	)
	local leaderboards = paginator:get_page(page_num)

	for _, leaderboard in ipairs(leaderboards) do
		local inputmodes = {}
		for _, entry in ipairs(leaderboard.leaderboard_inputmodes) do
			table.insert(inputmodes, entry.inputmode)
		end
		leaderboard.inputmodes = inputmodes
		leaderboard.leaderboard_inputmodes = nil
	end

	local count = Leaderboards:count()

	return 200, {
		total = count,
		filtered = count,
		leaderboards = leaderboards
	}
end

leaderboards_c.POST = function(request)
	local params = request.params
	local leaderboard = Leaderboards:create({
		name = params.name or "Leaderboard",
		description = params.description,
	})

	Roles:assign("creator", {
		user_id = params.user_id,
		leaderboard_id = leaderboard.id
	})
	Community_leaderboards:create({
		community_id = params.community_id,
		leaderboard_id = leaderboard.id
	})

	return 200, {leaderboard = leaderboard}
end

return leaderboards_c
