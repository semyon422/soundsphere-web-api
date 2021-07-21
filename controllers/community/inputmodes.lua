local Community_inputmodes = require("models.community_inputmodes")
local Inputmodes = require("enums.inputmodes")

local inputmodes_c = {}

inputmodes_c.GET = function(params)
	local community_inputmodes = Community_inputmodes:find_all({params.community_id}, "community_id")

	local inputmodes = {}
	for _, community_inputmode in ipairs(community_inputmodes) do
		table.insert(inputmodes, Inputmodes:to_name(community_inputmode.inputmode))
	end

	local count = Community_inputmodes:count()

	return 200, {
		total = count,
		filtered = count,
		inputmodes = inputmodes
	}
end

return inputmodes_c
