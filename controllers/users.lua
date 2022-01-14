local Users = require("models.users")
local util = require("util")
local Controller = require("Controller")
local register_c = require("controllers.auth.register")
local preload = require("lapis.db.model").preload

local users_c = Controller:new()

users_c.path = "/users"
users_c.methods = {"GET", "POST"}

users_c.policies.GET = {{"permit"}}
users_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.get_all"),
	require("validations.search"),
}
util.add_belongs_to_validations(Users.relations, users_c.validations.GET)
util.add_has_many_validations(Users.relations, users_c.validations.GET)
users_c.GET = function(self)
	local params = self.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local clause = params.search and util.db_search(Users.db, params.search, "name")
	local paginator = Users:paginated(
		util.db_where(clause) .. " order by id asc",
		{
			per_page = per_page
		}
	)
	local users = params.get_all and paginator:get_all() or paginator:get_page(page_num)
	preload(users, util.get_relatives_preload(Users, params))
	util.recursive_to_name(users)

	return {json = {
		total = tonumber(Users:count()),
		filtered = tonumber(Users:count(clause)),
		users = users,
	}}
end

users_c.context.POST = {"request_session"}
users_c.policies.POST = {{"authenticated"}}
users_c.validations.POST = register_c.validations.POST
users_c.POST = register_c.POST

return users_c
