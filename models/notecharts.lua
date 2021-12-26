local Model = require("lapis.db.model").Model

local Notecharts = Model:extend(
	"notecharts",
	{
		relations = {
			{"file", belongs_to = "files", key = "file_id"},
		},
		url_params = function(self, req, ...)
			return "notechart", {notechart_id = self.id}, ...
		end,
	}
)

local _load = Notecharts.load
function Notecharts:load(row)
	row.created_at = tonumber(row.created_at)
	return _load(self, row)
end

return Notecharts
