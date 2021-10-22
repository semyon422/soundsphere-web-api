local Model = require("lapis.db.model").Model

local quick_logins = Model:extend(
	"quick_logins",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"}
		}
	}
)

return quick_logins
