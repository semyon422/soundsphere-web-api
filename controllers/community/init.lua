local Communities = require("models.communities")

local additions = {
	inputmodes = require("controllers.community.inputmodes"),
	leaderboards = require("controllers.community.leaderboards"),
	users = require("controllers.community.users"),
}

local community_c = {}

community_c.path = "/communities/:community_id"
community_c.methods = {"GET", "PATCH", "DELETE"}
community_c.context = {"community"}
community_c.policies = {
	GET = require("policies.public"),
	PATCH = require("policies.public"),
	DELETE = require("policies.public"),
}

community_c.GET = function(request)
	local params = request.params
	local community = Communities:find(params.community_id)

	local fields = {}
	for param, controller in pairs(additions) do
		local value = tonumber(params[param])
		if value then
			local param_count = param .. "_count"
			local _, response = controller.GET(request)
			community[param] = response[param]
			if community[param_count] ~= response.total then
				community[param_count] = response.total
				table.insert(fields, param_count)
			end
		end
	end
	if #fields > 0 then
		print(unpack(fields))
		community:update(unpack(fields))
	end

	return 200, {community = community}
end

community_c.PATCH = function(request)
	local params = request.params
	local community = Communities:find(params.community_id)

	community.name = params.community.name
	community.alias = params.community.alias
	community.short_description = params.community.short_description
	community.description = params.community.description

	community:update("name", "alias", "short_description", "description")

	return 200, {community = community}
end

community_c.DELETE = function(request)
	return 200, {}
end

return community_c
