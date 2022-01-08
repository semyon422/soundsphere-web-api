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
			-- {"inputmodes",
			-- 	fetch = true,
			-- 	preload = function(difftables)
			-- 		local preload_difftable_inputmodes = false
			-- 		if #difftables == 0 then
			-- 			return
			-- 		elseif not difftables[1].difftable_inputmodes then
			-- 			preload(difftables, "difftable_inputmodes")
			-- 			preload_difftable_inputmodes = true
			-- 		end
			-- 		for _, difftable in ipairs(difftables) do
			-- 			if difftable.difftable_inputmodes then
			-- 				difftable.inputmodes = Inputmodes:entries_to_list(difftable.difftable_inputmodes)
			-- 			end
			-- 			if preload_difftable_inputmodes then
			-- 				difftable.difftable_inputmodes = nil
			-- 			end
			-- 		end
			-- 	end,
			-- },
		},
		url_params = function(self, req, ...)
			return "difftable", {difftable_id = self.id}, ...
		end,
	}
)

return Difftable
