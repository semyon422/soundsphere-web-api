local Scores = require("models.scores")
local Controller = require("Controller")

local user_scores_c = Controller:new()

user_scores_c.path = "/users/:user_id[%d]/scores"
user_scores_c.methods = {"GET"}

user_scores_c.policies.GET = {{"permit"}}
user_scores_c.validations.GET = {
	{"is_not_valid", type = "boolean", optional = true},
	{"is_not_complete", type = "boolean", optional = true},
}
user_scores_c.GET = function(self)
	local params = self.params

	local scores = Scores:find_all({params.user_id}, {
		key = "user_id",
		where = {
			is_valid = not params.is_not_valid,
			is_complete = not params.is_not_complete,
		}
	})

	return {json = {scores = scores}}
end

return user_scores_c
