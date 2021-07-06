local communities = require("models.communities")

local community_c = {}

community_c.GET = function(params)
	local community_entry = communities:find(params.community_id)

	if community_entry then
		local inputmodes = {}
		community_entry.inputmodes = inputmodes

		local community_inputmodes = community_entry:get_community_inputmodes()
		for _, community_inputmode in ipairs(community_inputmodes) do
			table.insert(inputmodes, community_inputmode:get_inputmode())
		end
	end

	return 200, {community = community_entry}
end

community_c.PATCH = function(params)
	local community_entry = communities:find(params.community.id)

	community_entry.name = params.community.name
	community_entry.alias = params.community.alias
	community_entry.short_description = params.community.short_description
	community_entry.description = params.community.description

	community_entry:update("name", "alias", "short_description", "description")

	return 200, {community = community_entry}
end

return community_c
