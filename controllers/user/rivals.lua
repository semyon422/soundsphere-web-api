local User_relations = require("models.user_relations")
local Users = require("models.users")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local user_rivals_c = Controller:new()

user_rivals_c.path = "/users/:user_id[%d]/rivals"
user_rivals_c.methods = {"GET"}

user_rivals_c.policies.GET = {{"permit"}}
user_rivals_c.validations.GET = util.add_belongs_to_validations(User_relations.relations)
user_rivals_c.GET = function(self)
	local params = self.params

	local user_relations = User_relations:find_all(
		{params.user_id},
		"user_id",
		{where = {relationtype = User_relations.types.rival}}
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
		user_relations_rivals = user_relations,
	}}
end

return user_rivals_c
