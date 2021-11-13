local Community_inputmodes = require("models.community_inputmodes")
local Inputmodes = require("enums.inputmodes")

local community_inputmode_c = {}

community_inputmode_c.path = "/communities/:community_id/inputmodes/:inputmode"
community_inputmode_c.methods = {"PUT", "DELETE"}
community_inputmode_c.context = {"community"}
community_inputmode_c.policies = {
	PUT = require("policies.public"),
	DELETE = require("policies.public"),
}

community_inputmode_c.PUT = function(request)
	local params = request.params
    local community_inputmode = {
        community_id = params.community_id,
        inputmode = Inputmodes:for_db(params.inputmode),
    }
    if not Community_inputmodes:find(community_inputmode) then
        Community_inputmodes:create(community_inputmode)
    end

	return 200, {}
end

community_inputmode_c.DELETE = function(request)
	local params = request.params
    local community_inputmode = Community_inputmodes:find({
        community_id = params.community_id,
        inputmode = Inputmodes:for_db(params.inputmode),
    })
    if community_inputmode then
        community_inputmode:delete()
    end

	return 200, {}
end

return community_inputmode_c
