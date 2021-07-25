local User_rivals = require("models.user_rivals")
local Inputmodes = require("enums.inputmodes")

local user_rival_c = {}

user_rival_c.PUT = function(params)
    local user_rival = {
        user_id = params.user_id,
        rival_id = params.rival_id,
    }
    if not User_rivals:find(user_rival) then
        User_rivals:create(user_rival)
    end

	return 200, {}
end

user_rival_c.DELETE = function(params)
    local user_rival = User_rivals:find({
        user_id = params.user_id,
        rival_id = params.rival_id,
    })
    if user_rival then
        user_rival:delete()
    end

	return 200, {}
end

return user_rival_c
