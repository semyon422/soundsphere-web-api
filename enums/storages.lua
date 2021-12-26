local enum = require("lapis.db.model").enum

local Storages = enum({
	undefined = 0,
	notecharts = 1,
	replays = 2,
})

return Storages
