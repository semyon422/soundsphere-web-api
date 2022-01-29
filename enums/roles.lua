local enum = require("lapis.db.model").enum

local Roles = enum({
	creator = 0,
	admin = 1,
	moderator = 2,
	user = 3,
	donator = 4,
})

Roles.list = {
	"creator",
	"admin",
	"moderator",
	"user",
	"donator",
}

-- from high to low
Roles.staff_role_names = {"creator", "admin", "moderator"}
Roles.staff_roles = {}
for _, role in ipairs(Roles.staff_role_names) do
	table.insert(Roles.staff_roles, Roles:for_db(role))
end

return Roles
