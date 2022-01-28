local enum = require("lapis.db.model").enum

local Roles = enum({
	user = 0,
	verified_user = 1,
	creator = 2,
	admin = 3,
	moderator = 4,
	donator = 5,
})

Roles.list = {
	"user",
	"verified_user",
	"creator",
	"admin",
	"moderator",
	"donator",
}

-- from high to low
Roles.staff_role_names = {"creator", "admin", "moderator"}
Roles.staff_roles = {}
for _, role in ipairs(Roles.staff_role_names) do
	table.insert(Roles.staff_roles, Roles:for_db(role))
end

return Roles
