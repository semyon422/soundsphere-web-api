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

user_c.context.PATCH = {"user", "request_session", "session_user", "user_roles"}
user_c.policies.PATCH = {
	{"authed", "user_profile"},
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
user_c.validations.PATCH = {
	{"user", type = "table", param_type = "body", validations = {
		{"name", exists = true, type = "string"},
		{"description", exists = true, type = "string"},
	}},
}
user_c.PATCH = function(self)
	local params = self.params
	local user = self.context.user

	local found_user = Users:find({name = params.user.name})
	if found_user and found_user.id ~= user.id then
		return {status = 400, json = {message = "This name is already taken"}}
	end

	util.patch(user, params.user, {
		"name",
		"description",
	})

	return {json = {user = user:to_name()}}
end

user_c.context.DELETE = {"user", "request_session", "session_user", "user_roles"}
user_c.policies.DELETE = {
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
user_c.DELETE = function(self)
	local user = self.context.user

	local db = Users.db
	db.delete("leaderboard_users", {user_id = user.id})
	db.delete("community_users", {user_id = user.id})
	db.delete("user_relations", {user_id = user.id})
	db.delete("user_relations", {relative_user_id = user.id})
	db.delete("user_roles", {user_id = user.id})

	user:delete()

	return {status = 204}
end

return user_c
