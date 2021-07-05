local communities = require("models.communities")
local domains = require("models.domains")
local user_roles = require("models.user_roles")
local community_users = require("models.community_users")
local roles = require("models.roles")
local preload = require("lapis.db.model").preload

local communities_c = {}

communities_c.GET = function(params)
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = communities:paginated(
		"order by id asc",
		{
			per_page = per_page,
			prepare_results = function(entries)
				preload(entries, {community_inputmode = "inputmode"})
				return entries
			end
		}
	)
	local db_community_entries = paginator:get_page(page_num)
	for _, community in ipairs(db_community_entries) do
		local community_inputmode = community.community_inputmode
		local inputmodes = {}
		if community_inputmode then
			for _, entry in ipairs(community_inputmode) do
				table.insert(inputmodes, entry.inputmode.name)
			end
		end
		community.inputmodes = inputmodes
	end

	local count = communities:count()

	return 200, {
		total = count,
		filtered = count,
		communities = db_community_entries
	}
end

communities_c.POST = function(params)
	local domain_entry = domains:create({type_id = domains.types.community})
	local community_entry = {
		domain_id = domain_entry.id,
		name = params.name or "Community",
		alias = params.alias or "???",
		short_description = params.short_description,
		description = params.description,
	}
	community_entry = communities:create(community_entry)

	user_roles:create({
		user_id = params.user_id,
		role_id = roles.types.creator,
		domain_id = domain_entry.id
	})
	community_users:create({
		community_id = community_entry.id,
		user_id = params.user_id,
		accepted = true,
	})

	return 200, {
		community = community_entry
	}
end

return communities_c
