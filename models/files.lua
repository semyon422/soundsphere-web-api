local Model = require("lapis.db.model").Model
local toboolean = require("util.toboolean")

local Files = Model:extend(
	"files",
	{
		relations = {
			{"notecharts", has_many = "notecharts", key = "file_id"},
		},
		url_params = function(self, req, ...)
			return "file", {file_id = self.id}, ...
		end,
	}
)

local _load = Files.load
function Files:load(row)
	row.uploaded = toboolean(row.uploaded)
	row.loaded = toboolean(row.loaded)
	row.created_at = tonumber(row.created_at)
	return _load(self, row)
end

return Files
