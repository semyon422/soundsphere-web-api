local User_relations = require("models.user_relations")
local Users = require("models.users")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local user_relations_c = Controller:new()

user_relations_c.path = "/users/:user_id[%d]/relations"
user_relations_c.methods = {"GET", "POST"}

user_relations_c.context.GET = {"user", "request_session", "session_user", "user_roles"}
user_relations_c.policies.GET = {
	{"authed", "user_profile", {not_params = "who_added_me"}},
	{"authed", "user_profile", {role = "donator"}},
	{"authed", "user_profile", {role = "moderator"}},
	{"authed", "user_profile", {role = "admin"}},
	{"authed", "user_profile", {role = "creator"}},
}
user_relations_c.validations.GET = {
	require("validations.no_data"),
	{"type", exists = true, type = "string", one_of = {"friend", "rival"}, optional = true},
	{"all_types", type = "boolean", optional = true},
	{"who_added_me", type = "boolean", optional = true},
}
util.add_belongs_to_validations(User_relations.relations, user_relations_c.validations.GET)
user_relations_c.GET = function(self)
	local params = self.params

	if params.who_added_me and params.type == "friend" then
		return {status = 403}
	end

	local where = {}
	if not params.who_added_me then
		where.user_id = params.user_id
	else
		where.relative_user_id = params.user_id
	end
	if params.type and not params.all_types then
		where.relationtype = User_relations.types[params.type]
	end

	local user_relations = User_relations:select(
		"where " .. User_relations.db.encode_clause(where)
	)

	if params.no_data then
		return {json = {
			total = #user_relations,
			filtered = #user_relations,
		}}
	end

	preload(user_relations, util.get_relatives_preload(User_relations, params))
	util.recursive_to_name(user_relations)

	return {json = {
		total = #user_relations,
		filtered = #user_relations,
		user_relations = user_relations,
	}}
end

user_relations_c.context.POST = {"request_session", "session_user", "user_relations", "user_roles"}
user_relations_c.display_policies.POST = {{"authed", "user_profile"}}
user_relations_c.policies.POST = {{"authed", "user_profile", "relations_limit"}}
user_relations_c.validations.POST = {
	{"type", exists = true, type = "string", one_of = {"friend", "rival"}},
	{"relative_user_id", exists = true, type = "number"},
}
user_relations_c.POST = function(self)
	local params = self.params

	if params.relative_user_id == params.user_id then
		return {status = 400, json = {message = "Can not add yourself"}}
	end
	if not Users:find(params.relative_user_id) then
		return {status = 400, json = {message = "Relative user not found"}}
	end

	local new_user_relation = {
		relationtype = User_relations.types:for_db(params.type),
		user_id = params.user_id,
		relative_user_id = params.relative_user_id,
	}
	local user_relation = User_relations:find(new_user_relation)
	if not user_relation then
		new_user_relation.created_at = os.time()
		user_relation = User_relations:create(new_user_relation)
	end

	local reverse_user_relation = User_relations:find({
		relationtype = user_relation.relationtype,
		user_id = params.relative_user_id,
		relative_user_id = params.user_id,
	})

	if reverse_user_relation then
		user_relation.mutual = true
		user_relation:update("mutual")
		reverse_user_relation.mutual = true
		reverse_user_relation:update("mutual")
	end

	return {status = 201, redirect_to = self:url_for(user_relation)}
end

return user_relations_c
