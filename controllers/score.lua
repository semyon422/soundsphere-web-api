local Scores = require("models.scores")
local Controller = require("Controller")

local score_c = Controller:new()

score_c.path = "/scores/:score_id"
score_c.methods = {"GET", "DELETE"}
score_c.context = {}
score_c.policies = {
	GET = require("policies.public"),
	DELETE = require("policies.public"),
}

score_c.GET = function(request)
	local params = request.params
	local score = Scores:find(params.score_id)

	return 200, {score = score}
end

score_c.DELETE = function(request)
	return 200, {score = score}
end

return score_c
