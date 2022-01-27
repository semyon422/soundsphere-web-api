local enum = require("lapis.db.model").enum

local Bypass_actions = enum({
	register = 0,
	login = 1,
})

Bypass_actions.list = {
	"register",
	"login",
}

return Bypass_actions
