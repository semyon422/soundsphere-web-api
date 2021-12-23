local Model = require("lapis.db.model").Model

local Notecharts = Model:extend(
	"notecharts",
	{
		relations = {
			{"container", belongs_to = "containers", key = "container_id"},
		},
		url_params = function(self, req, ...)
			return "notechart", {notechart_id = self.id}, ...
		end,
	}
)

local _load = Notecharts.load
function Notecharts:load(row)
	row.creation_time = tonumber(row.creation_time)
	return _load(self, row)
end

return Notecharts
