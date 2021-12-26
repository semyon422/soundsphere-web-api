local Users = require("models.users")
local bcrypt = require("bcrypt")
local db_search = require("util.db_search")
local db_where = require("util.db_where")
local Controller = require("Controller")
local register_c = require("controllers.auth.register")

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
users_c.GET = function(request)
	local params = request.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local clause = params.search and db_search(Users.db, params.search, "name")
	local paginator = Users:paginated(
		db_where(clause), "order by id asc",
		{
			per_page = per_page,
			prepare_results = function(users)
				for i, user in ipairs(users) do
					users[i] = Users:safe_copy(user)
				end
				return users
			end
		}
	)
	local users = params.get_all and paginator:get_all() or paginator:get_page(page_num)

	return 200, {
		total = Users:count(),
		filtered = Users:count(clause),
		users = users
	}
end

users_c.context.POST = {"session"}
users_c.policies.POST = {{"authenticated"}}
users_c.validations.POST = register_c.validations.POST
users_c.POST = register_c.POST

return users_c
