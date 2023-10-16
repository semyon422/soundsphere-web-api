local schema = require("lapis.db.schema")
local db = require("db")
local types = db.types

return {
	[1] = function() end,
	[1697465838] = function()
		schema.add_column("scores", "rate", types.float)
		schema.add_column("scores", "const", types.boolean)
	end,
}
