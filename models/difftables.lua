local Model = require("lapis.db.model").Model
local preload = require("lapis.db.model").preload
local Inputmodes = require("enums.inputmodes")

local Difftable = Model:extend(
	"difftables",
	{
		relations = {
			{"community_difftables", has_many = "community_difftables", key = "difftable_id"},
			{"difftable_inputmodes", has_many = "difftable_inputmodes", key = "difftable_id"},
			{"owner_community", belongs_to = "communities", key = "owner_community_id"},
		},
		url_params = function(self, req, ...)
			return "difftable", {difftable_id = self.id}, ...
		end,
	}
)

return Difftable
