local Communities = require("models.communities")
local Domains = require("models.domains")
local User_roles = require("models.user_roles")
local Community_users = require("models.community_users")
local Roles = require("models.roles")
local preload = require("lapis.db.model").preload

local communities_c = {}

communities_c.GET = function(params)
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
		local community_inputmodes = community.community_inputmodes
		local inputmodes = {}
		for _, entry in ipairs(community_inputmodes) do
			table.insert(inputmodes, entry.inputmode.name)
		end
		community.inputmodes = inputmodes
	end

	local count = Communities:count()

	return 200, {
		total = count,
		filtered = count,
		communities = communities
	}
end

communities_c.POST = function(params)
	local domain_entry = Domains:create({domaintype = Domains.types.community})
	local community = Communities:create({
		domain_id = domain_entry.id,
		name = params.name or "Community",
		alias = params.alias or "???",
		short_description = params.short_description,
		description = params.description,
	})

	User_roles:create({
		user_id = params.user_id,
		roletype = Roles.types.creator,
		domain_id = domain_entry.id
	})
	Community_users:create({
		community_id = community.id,
		user_id = params.user_id,
		accepted = true,
	})

	return 200, {community = community}
end

return communities_c
