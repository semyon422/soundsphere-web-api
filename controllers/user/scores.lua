local Scores = require("models.scores")
local Controller = require("Controller")
local util = require("util")
local preload = require("lapis.db.model").preload

local user_scores_c = Controller:new()

user_scores_c.path = "/users/:user_id[%d]/scores"
user_scores_c.methods = {"GET"}

user_scores_c.policies.GET = {{"permit"}}
user_scores_c.validations.GET = {
	{"is_not_valid", type = "boolean", optional = true},
	{"is_not_complete", type = "boolean", optional = true},
}
user_scores_c.validations.GET = util.add_belongs_to_validations(Scores.relations)
user_scores_c.GET = function(self)
	local params = self.params

	local scores = Scores:find_all({params.user_id}, {
		key = "user_id",
		where = {
			is_valid = not params.is_not_valid,
			is_complete = not params.is_not_complete,
		}
	})

	if params.no_data then
		return {json = {
			total = #scores,
			filtered = #scores,
		}}
	end

	preload(scores, util.get_relatives_preload(Scores, params))
	util.recursive_to_name(scores)

	return {json = {scores = scores}}
end

return user_scores_c
