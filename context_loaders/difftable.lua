local Difftables = require("models.difftables")

return function(self)
	if self.context.difftable then return true end
	local difftable_id = self.params.difftable_id
	if difftable_id then
		self.context.difftable = Difftables:find(difftable_id)
	end
	return self.context.difftable
end
