local Difftables = require("models.difftables")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("difftable", function(self)
	local difftable_id = self.params.difftable_id
	if difftable_id then
		return Difftables:find(difftable_id)
	end
end)
