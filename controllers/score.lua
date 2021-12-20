local Scores = require("models.scores")
local Controller = require("Controller")

local score_c = Controller:new()

score_c.path = "/scores/:score_id[%d]"
score_c.methods = {"GET", "DELETE"}

score_c.policies.GET = {{"permit"}}
score_c.GET = function(request)
	local params = request.params
	local score = Scores:find(params.score_id)

	return 200, {score = score}
end

score_c.policies.DELETE = {{"permit"}}
score_c.DELETE = function(request)
	return 200, {score = score}
end

return score_c
