local Users = require("models.users")
local Controller = require("Controller")
local util = require("util")

local additions = {
	communities = require("controllers.user.communities"),
	leaderboards = require("controllers.user.leaderboards"),
	roles = require("controllers.user.roles"),
	scores = require("controllers.user.scores"),
	sessions = require("controllers.user.sessions"),
	friends = require("controllers.user.friends"),
	rivals = require("controllers.user.rivals"),
}

local user_c = Controller:new()

user_c.path = "/users/:user_id[%d]"
user_c.methods = {"GET", "PATCH", "DELETE"}

user_c.context.GET = {"user"}
user_c.policies.GET = {{"context_loaded"}}
user_c.validations.GET = {}
util.add_additions_validations(additions, user_c.validations.GET)
util.add_belongs_to_validations(Users.relations, user_c.validations.GET)
user_c.GET = function(self)
	local user = self.context.user

	util.load_additions(self, user, additions)
	util.get_relatives(user, self.params, true)

	return {json = {user = user:to_name()}}
end

user_c.context.PATCH = {"user", "request_session"}
user_c.policies.PATCH = {{"authenticated"}}
user_c.validations.PATCH = {
	{"user", type = "table", param_type = "body", validations = {
		{"name", type = "string"},
		{"description", type = "string"},
	}},
}
user_c.PATCH = function(self)
	local params = self.params
	local user = self.context.user

	util.patch(user, params.user, {
		"name",
		"description",
	})

	return {json = {user = user:to_name()}}
end

user_c.context.DELETE = {"user", "request_session"}
user_c.policies.DELETE = {{"authenticated"}}
user_c.DELETE = function(self)
	return {status = 204}
end

return user_c
