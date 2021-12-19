local Controller = require("Controller")

local user_statistics_c = Controller:new()

user_statistics_c.GET = function(request)
	return 200, {}
end

return user_statistics_c
