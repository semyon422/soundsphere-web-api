local Leaderboards = require("models.leaderboards")
local Domains = require("models.domains")
local User_roles = require("models.user_roles")
local Community_leaderboards = require("models.community_leaderboards")
local Roles = require("models.roles")

local leaderboards_c = {}

leaderboards_c.GET = function(params)
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = Leaderboards:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local leaderboards = paginator:get_page(page_num)

	local count = Leaderboards:count()

	return 200, {
		total = count,
		filtered = count,
		leaderboards = leaderboards
	}
end

leaderboards_c.POST = function(params)
	local domain = Domains:create({type_id = Domains.types.leaderboard})
	local leaderboard = {
		domain_id = domain.id,
		name = params.name or "Leaderboard",
		description = params.description,
	}
	leaderboard = Leaderboards:create(leaderboard)

	User_roles:create({
		user_id = params.user_id,
		role_id = Roles.types.creator,
		domain_id = domain.id
	})
	Community_leaderboards:create({
		community_id = params.community_id,
		leaderboard_id = leaderboard.id
	})

	return 200, {leaderboard = leaderboard}
end

return leaderboards_c
