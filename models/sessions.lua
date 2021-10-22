local Model = require("lapis.db.model").Model

local Sessions = Model:extend(
	"sessions",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
		}
	}
)

return Sessions
