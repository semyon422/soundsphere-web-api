local Users = require("models.users")
local Controller = require("Controller")
local util = require("util")

local additions = {
	communities = require("controllers.user.communities"),
	leaderboards = require("controllers.user.leaderboards"),
	inputmodes = require("controllers.user.inputmodes"),
	roles = require("controllers.user.roles"),
	scores = require("controllers.user.scores"),
	sessions = require("controllers.user.sessions"),
	relations = require("controllers.user.relations"),
}

local user_c = Controller:new()

user_c.path = "/users/:user_id[%d]"
user_c.methods = {"GET", "PATCH", "PUT", "DELETE"}

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
user_c.display_policies.PATCH = {
	{"authed", "user_profile"},
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
user_c.policies.PATCH = {
	{"authed", "user_profile", "user_profile_patch"},
	{"authed", "user_profile", {role = "donator"}},
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

user_c.context.PUT = {"user", "request_session", "session_user", "user_roles"}
user_c.policies.PUT = {
	{"authed", {role = "moderator"}, "change_staff_role"},
	{"authed", {role = "admin"}, "change_staff_role"},
	{"authed", {role = "creator"}, "change_staff_role"},
}
user_c.validations.PUT = {
	{"ban", type = "boolean", optional = true},
	{"unban", type = "boolean", optional = true},
}
user_c.PUT = function(self)
	local params = self.params
	local user = self.context.user

	if params.ban then
		user.is_banned = true
		user:update("is_banned")
	elseif params.unban then
		user.is_banned = false
		user:update("is_banned")
	end

	return {json = {user = user:to_name()}}
end

user_c.context.DELETE = {"user", "request_session", "session_user", "user_roles"}
user_c.policies.DELETE = {
	{"authed", {role = "admin"}, "change_staff_role"},
	{"authed", {role = "creator"}, "change_staff_role"},
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
