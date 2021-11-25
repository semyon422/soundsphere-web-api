local Model = require("lapis.db.model").Model
local Inputmodes = require("enums.inputmodes")

local Community_inputmodes = Model:extend(
	"community_inputmodes",
	{
		relations = {
			{"community", belongs_to = "communities", key = "community_id"},
		}
	}
)

Community_inputmodes.get_inputmodes = function(self, community_inputmodes)
	local inputmodes = {}
	for _, community_inputmode in ipairs(community_inputmodes) do
		table.insert(inputmodes, Inputmodes:to_name(community_inputmode.inputmode))
	end
	return inputmodes
end

return Community_inputmodes
