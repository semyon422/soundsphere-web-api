local Model = require("lapis.db.model").Model

local Difftable_notecharts = Model:extend(
	"difftable_notecharts",
	{
		relations = {
			{"difftable", belongs_to = "difftables", key = "difftable_id"},
			{"notechart", belongs_to = "notecharts", key = "notechart_id"},
		},
		url_params = function(self, req, ...)
			return "difftable.notechart", {difftable_id = self.difftable_id, notechart_id = self.notechart_id}, ...
		end,
	}
)

return Difftable_notecharts
