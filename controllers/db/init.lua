local Controller = require("Controller")

local db_c = Controller:new()

db_c.path = "/db"
db_c.methods = {"GET"}

db_c.policies.GET = {{"permit"}}
db_c.GET = function(request)
	return {}
end

return db_c
