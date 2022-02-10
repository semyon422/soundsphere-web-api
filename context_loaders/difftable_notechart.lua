local Difftable_notecharts = require("models.difftable_notecharts")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("difftable_notechart", function(self)
	local difftable_id = self.params.difftable_id
	local notechart_id = self.params.notechart_id
	if difftable_id and notechart_id then
		return Difftable_notecharts:find({
			difftable_id = difftable_id,
			notechart_id = notechart_id,
		})
	end
end)
