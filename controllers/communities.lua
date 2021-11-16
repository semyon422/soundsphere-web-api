local Communities = require("models.communities")
local Community_users = require("models.community_users")
local Roles = require("models.roles")
local preload = require("lapis.db.model").preload

local communities_c = {}

communities_c.path = "/communities"
communities_c.methods = {"GET", "POST"}
communities_c.context = {"session"}
communities_c.policies = {
	GET = require("policies.public"),
	POST = {{
		rules = {require("rules.authenticated")},
		combine = require("abac.combine.permit_all_or_deny"),
	}},
}

communities_c.GET = function(request)
	local params = request.params
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local db = Communities.db
	local joined_clause = ""
	if tonumber(params.hide_joined) == 1 and request.session.user_id then
		local community_users = Community_users:find_all({request.session.user_id}, {
			key = "user_id",
			fields = "community_id"
		})
		local community_ids = {}
		for _, community_user in ipairs(community_users) do
			table.insert(community_ids, community_user.community_id)
		end
		joined_clause = "where " .. db.encode_clause({
			id = db.list(community_ids)
		}):gsub("IN", "NOT IN")
	end

	local paginator = Communities:paginated(
		joined_clause .. " order by id asc",
		{
			per_page = per_page,
			prepare_results = function(entries)
				preload(entries, {community_inputmodes = "inputmode"})
				return entries
			end
		}
	)
	local communities = paginator:get_page(page_num)

	for _, community in ipairs(communities) do
		local inputmodes = {}
		for _, entry in ipairs(community.community_inputmodes) do
			table.insert(inputmodes, entry.inputmode)
		end
		community.inputmodes = inputmodes
		community.community_inputmodes = nil
	end

	local count = Communities:count()

	return 200, {
		total = count,
		filtered = count,
		communities = communities
	}
end

communities_c.POST = function(request)
	local params = request.params
	local session = request.session

	local community = params.community
	community = Communities:create({
		name = community.name or "Community",
		alias = community.alias or "???",
		link = community.link,
		short_description = community.short_description,
		description = community.description,
		banner = community.banner,
		is_public = community.is_public,
	})

	Roles:assign("creator", {
		user_id = session.user_id,
		community_id = community.id
	})
	Community_users:create({
		community_id = community.id,
		user_id = session.user_id,
		accepted = true,
	})

	return 200, {community = community}
end

return communities_c
