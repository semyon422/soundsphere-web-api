local User_relations = require("models.user_relations")
local Users = require("models.users")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")

local user_rivals_c = Controller:new()

user_rivals_c.path = "/users/:user_id[%d]/rivals"
user_rivals_c.methods = {"GET"}

user_rivals_c.policies.GET = {{"permit"}}
user_rivals_c.GET = function(request)
	local params = request.params
	local rivals = {}
	local user_relations = User_relations:find_all(
		{params.user_id},
		"user_id",
		{where = {relationtype = User_relations.types.rival}}
	)
	preload(user_relations, "relative_user")
	for _, user_relation in ipairs(user_relations) do
		local rival = user_relation.relative_user:to_name()
		rival.mutual = user_relation.mutual
		table.insert(rivals, rival)
	end

	local count = User_relations:count()

	return 200, {
		total = count,
		filtered = count,
		rivals = rivals
	}
end

return user_rivals_c
