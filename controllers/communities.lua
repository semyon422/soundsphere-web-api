local Communities = require("models.communities")
local Community_users = require("models.community_users")
local Roles = require("models.roles")
local preload = require("lapis.db.model").preload

local communities_c = {}

communities_c.path = "/communities"
communities_c.methods = {"GET", "POST"}
communities_c.context = {}
communities_c.policies = {
	GET = require("policies.public"),
	POST = require("policies.public"),
}

communities_c.GET = function(request)
	local params = request.params
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = Communities:paginated(
		"order by id asc",
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
	local community = Communities:create({
		name = params.name or "Community",
		alias = params.alias or "???",
		short_description = params.short_description,
		description = params.description,
	})

	Roles:assign("creator", {
		user_id = params.user_id,
		community_id = community.id
	})
	Community_users:create({
		community_id = community.id,
		user_id = params.user_id,
		accepted = true,
	})

	return 200, {community = community}
end

return communities_c
