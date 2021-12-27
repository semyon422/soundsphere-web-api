local enum = require("lapis.db.model").enum

local Rules = enum({
	allowed = 0,
	required = 1,
})

Rules.list = {
	"allowed",
	"required",
}

return Rules
