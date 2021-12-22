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

return Roles
