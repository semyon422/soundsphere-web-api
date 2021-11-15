local Community_inputmodes = require("models.community_inputmodes")
local Inputmodes = require("enums.inputmodes")

local community_inputmodes_c = {}

community_inputmodes_c.path = "/communities/:community_id/inputmodes"
community_inputmodes_c.methods = {"GET"}
community_inputmodes_c.context = {}
community_inputmodes_c.policies = {
	GET = require("policies.public"),
}

community_inputmodes_c.GET = function(request)
	local params = request.params
	local community_inputmodes = Community_inputmodes:find_all({params.community_id}, "community_id")

	local inputmodes = {}
	for _, community_inputmode in ipairs(community_inputmodes) do
		table.insert(inputmodes, Inputmodes:to_name(community_inputmode.inputmode))
	end

	local count = #community_inputmodes

	return 200, {
		total = count,
		filtered = count,
		inputmodes = inputmodes
	}
end

return community_inputmodes_c
