local enum = require("lapis.db.model").enum

local Bypass_actions = enum({
	register = 0,
	login = 1,
	password = 2,
})

Bypass_actions.list = {
	"register",
	"login",
	"password",
}

return Bypass_actions
