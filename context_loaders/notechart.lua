local Notecharts = require("models.notecharts")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("notechart", function(self)
	local notechart_id = self.params.notechart_id
	if notechart_id then
		return Notecharts:find(notechart_id)
	end
end)
