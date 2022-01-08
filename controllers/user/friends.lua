local User_relations = require("models.user_relations")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local user_friends_c = Controller:new()

user_friends_c.path = "/users/:user_id[%d]/friends"
user_friends_c.methods = {"GET"}

user_friends_c.policies.GET = {{"permit"}}
user_friends_c.validations.GET = util.add_belongs_to_validations(User_relations.relations)
user_friends_c.GET = function(self)
	local params = self.params

	local user_relations = User_relations:find_all(
		{params.user_id},
		"user_id",
		{where = {relationtype = User_relations.types.friend}}
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
		user_relations_friends = user_relations,
	}}
end

return user_friends_c
