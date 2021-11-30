local Leaderboards = require("models.leaderboards")
local Users = require("models.users")
local Community_leaderboards = require("models.community_leaderboards")
local Inputmodes = require("enums.inputmodes")
local preload = require("lapis.db.model").preload
local leaderboard_c = require("controllers.leaderboard")

local leaderboards_c = {}

leaderboards_c.path = "/leaderboards"
leaderboards_c.methods = {"GET", "POST"}
leaderboards_c.context = {"session"}
leaderboards_c.policies = {
	GET = require("policies.public"),
	POST = {{
		rules = {require("rules.authenticated")},
		combine = require("abac.combine.permit_all_or_deny"),
	}},
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
				preload(entries, {"leaderboard_inputmodes", "top_user"})
				return entries
			end
		}
	)
	local leaderboards = paginator:get_page(page_num)

	for _, leaderboard in ipairs(leaderboards) do
		leaderboard.top_user = Users:safe_copy(leaderboard.top_user)
		leaderboard.inputmodes = Inputmodes:entries_to_list(leaderboard.leaderboard_inputmodes)
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
	leaderboard = Leaderboards:create({
		name = params.leaderboard.name or "Leaderboard",
		description = params.leaderboard.description,
		banner = params.leaderboard.banner,
	})

	Community_leaderboards:create({
		community_id = params.community_id,
		leaderboard_id = leaderboard.id,
		is_owner = true,
	})

	leaderboard_c.update_inputmodes(leaderboard.id, params.leaderboard.inputmodes)

	return 200, {leaderboard = leaderboard}
end

return leaderboards_c
