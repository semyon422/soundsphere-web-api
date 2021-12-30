local Scores = require("models.scores")
local Controller = require("Controller")

local user_scores_c = Controller:new()

user_scores_c.path = "/users/:user_id[%d]/scores"
user_scores_c.methods = {"GET"}

user_scores_c.policies.GET = {{"permit"}}
user_scores_c.GET = function(request)
	local params = request.params
	local scores = Scores:find_all({params.user_id}, "user_id")

	return {json = {scores = scores}}
end

return user_scores_c
