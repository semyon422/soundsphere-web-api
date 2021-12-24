local Notecharts = require("models.notecharts")

return function(self)
	if self.context.notechart then return true end
	local notechart_id = self.params.notechart_id
	if notechart_id then
		self.context.notechart = Notecharts:find(notechart_id)
	end
	return self.context.notechart
end
