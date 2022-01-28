local Users = require("models.users")
local util = require("util")
local Controller = require("Controller")
local preload = require("lapis.db.model").preload

local users_c = Controller:new()

users_c.path = "/users"
users_c.methods = {"GET"}

users_c.policies.GET = {{"permit"}}
users_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.search"),
	{"is_banned", type = "boolean", optional = true},
}
util.add_belongs_to_validations(Users.relations, users_c.validations.GET)
util.add_has_many_validations(Users.relations, users_c.validations.GET)
users_c.GET = function(self)
	local params = self.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local db = Users.db

	local is_banned_clause = db.interpolate_query("is_banned = ?", not not params.is_banned)
	local search_clause = params.search and util.db_search(db, params.search, "name")
	local clause = util.db_and(search_clause, is_banned_clause)

	local paginator = Users:paginated(
		util.db_where(clause) .. " order by id asc",
		{
			per_page = per_page
		}
	)
	local users = paginator:get_page(page_num)
	preload(users, util.get_relatives_preload(Users, params))
	util.recursive_to_name(users)

	return {json = {
		total = tonumber(Users:count()),
		filtered = tonumber(Users:count(clause)),
		users = users,
	}}
end

return users_c
