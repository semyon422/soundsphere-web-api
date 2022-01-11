local enum = require("lapis.db.model").enum

local Roles = enum({
	guest = 0,
	user = 1,
	creator = 2,
	admin = 3,
	moderator = 4,
})

Roles.list = {
	"guest",
	"user",
	"creator",
	"admin",
	"moderator",
}

Roles.staff_roles = {}
for _, role in ipairs({"creator", "admin", "moderator"}) do
	table.insert(Roles.staff_roles, Roles:for_db(role))
end

return Roles
