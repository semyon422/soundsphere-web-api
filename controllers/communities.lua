local Communities = require("models.communities")
local Community_users = require("models.community_users")
local Inputmodes = require("enums.inputmodes")
local Roles = require("enums.roles")
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
	local joined_community_ids = {}
	local joined_community_ids_map = {}
	if request.session.user_id then
		local community_users = Community_users:find_all({request.session.user_id}, {
			key = "user_id",
			fields = "community_id"
		})
		for _, community_user in ipairs(community_users) do
			local id = community_user.community_id
			table.insert(joined_community_ids, id)
			joined_community_ids_map[id] = true
		end
		if tonumber(params.hide_joined) == 1 then
			joined_clause = "where " .. db.encode_clause({
				id = db.list(joined_community_ids)
			}):gsub("IN", "NOT IN")
		end
	end

	local paginator = Communities:paginated(
		joined_clause .. " order by id asc",
		{
			per_page = per_page,
			prepare_results = function(entries)
				preload(entries, "community_inputmodes")
				return entries
			end
		}
	)
	local communities = paginator:get_page(page_num)

	for _, community in ipairs(communities) do
		community.inputmodes = Inputmodes:entries_to_list(community.community_inputmodes)
		community.community_inputmodes = nil
		community.joined = joined_community_ids_map[community.id]
	end

	local count = Communities:count()

	return 200, {
		total = count,
		filtered = count,
		communities = communities,
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

	Community_users:create({
		community_id = community.id,
		user_id = session.user_id,
		sender_id = session.user_id,
		role = Roles:for_db("creator"),
		accepted = true,
		created_at = os.time(),
		message = "",
	})

	return 200, {community = community}
end

return communities_c
