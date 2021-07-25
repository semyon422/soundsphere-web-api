local Model = require("lapis.db.model").Model

local User_rivals = Model:extend(
	"user_rivals",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
			{"rival", belongs_to = "users", key = "rival_id"},
		}
	}
)

return User_rivals
