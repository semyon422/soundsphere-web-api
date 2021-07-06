local Community_inputmodes = require("models.community_inputmodes")
local preload = require("lapis.db.model").preload

local inputmodes_c = {}

inputmodes_c.GET = function(params)
	local community_inputmodes = Community_inputmodes:find_all({params.community_id}, "community_id")
	preload(community_inputmodes, "inputmode")

	local inputmodes = {}
	for _, community_inputmode in ipairs(community_inputmodes) do
		table.insert(inputmodes, community_inputmode.inputmode)
	end

	local count = Community_inputmodes:count()

	return 200, {
		total = count,
		filtered = count,
		inputmodes = inputmodes
	}
end

return inputmodes_c
