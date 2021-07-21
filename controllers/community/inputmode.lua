local Community_inputmodes = require("models.community_inputmodes")
local Inputmodes = require("enums.inputmodes")

local community_inputmodes_c = {}

community_inputmodes_c.PUT = function(params)
    local community_inputmode = {
        community_id = params.community_id,
        inputmode = Inputmodes:for_db(params.inputmode),
    }
    if not Community_inputmodes:find(community_inputmode) then
        Community_inputmodes:create(community_inputmode)
    end

	return 200, {}
end

community_inputmodes_c.DELETE = function(params)
    local community_inputmode = Community_inputmodes:find({
        community_id = params.community_id,
        inputmode = Inputmodes:for_db(params.inputmode),
    })
    if community_inputmode then
        community_inputmode:delete()
    end

	return 200, {}
end

return community_inputmodes_c
