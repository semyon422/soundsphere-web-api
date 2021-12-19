local Scores = require("models.scores")
local Controller = require("Controller")

local user_scores_c = Controller:new()

user_scores_c.path = "/users/:user_id/scores"
user_scores_c.methods = {"GET"}
user_scores_c.context = {}
user_scores_c.policies = {
	GET = require("policies.public"),
}

user_scores_c.GET = function(request)
	local params = request.params
	local scores = Scores:find_all({params.user_id}, "user_id")

	return 200, {scores = scores}
end

return user_scores_c
