local leaderboards = require("models.leaderboards")
local domains = require("models.domains")
local user_roles = require("models.user_roles")
local community_leaderboards = require("models.community_leaderboards")
local roles = require("models.roles")
local preload = require("lapis.db.model").preload

local leaderboards_c = {}

leaderboards_c.GET = function(params)
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = leaderboards:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local db_leaderboard_entries = paginator:get_page(page_num)

	local count = leaderboards:count()

	return 200, {
		total = count,
		filtered = count,
		leaderboards = db_leaderboard_entries
	}
end

leaderboards_c.POST = function(params)
	local domain_entry = domains:create({type_id = domains.types.leaderboard})
	local leaderboard_entry = {
		domain_id = domain_entry.id,
		name = params.name or "Leaderboard",
		description = params.description,
	}
	leaderboard_entry = leaderboards:create(leaderboard_entry)

	user_roles:create({
		user_id = params.user_id,
		role_id = roles.types.creator,
		domain_id = domain_entry.id
	})
	community_leaderboards:create({
		community_id = params.community_id,
		leaderboard_id = leaderboard_entry.id
	})

	return 200, {
		leaderboard = leaderboard_entry
	}
end

return leaderboards_c
