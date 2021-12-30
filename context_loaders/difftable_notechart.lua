local Difftable_notecharts = require("models.difftable_notecharts")

return function(self)
	if self.context.difftable_notechart then return true end
	local difftable_id = self.params.difftable_id
	local notechart_id = self.params.notechart_id
	if difftable_id and notechart_id then
		self.context.difftable_notechart = Difftable_notecharts:find({
			difftable_id = difftable_id,
			notechart_id = notechart_id,
		})
	end
	return self.context.difftable_notechart
end
