local model = require("lapis.db.model")
local Model, enum = model.Model, model.enum

local Domains = Model:extend(
	"domains",
	{
		relations = {
			{"user_roles", has_many = "user_roles", key = "domain_id"},
			{"group_roles", has_many = "group_roles", key = "domain_id"},
		}
	}
)

Domains.types = enum({
	root = 1,
	community = 2,
	leaderboard = 3,
})

return Domains
