local Scores = require("models.scores")
local Controller = require("Controller")

local score_c = Controller:new()

score_c.path = "/scores/:score_id[%d]"
score_c.methods = {"GET", "DELETE"}

score_c.context.GET = {"score"}
score_c.policies.GET = {{"permit"}}
score_c.GET = function(request)
	return 200, {score = request.context.score}
end

score_c.policies.DELETE = {{"permit"}}
score_c.DELETE = function(request)
	return 200, {score = score}
end

return score_c
