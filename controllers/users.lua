local Users = require("models.users")
local bcrypt = require("bcrypt")
local db_search = require("util.db_search")
local db_where = require("util.db_where")

local users_c = {}

users_c.path = "/users"
users_c.methods = {"GET", "POST"}
users_c.context = {}
users_c.policies = {
	GET = require("policies.public"),
	POST = require("policies.public"),
}

users_c.GET = function(request)
	local params = request.params
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

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

local function register(name, email, password)
	if not name then
		return false, "Invalid name"
	elseif not email then
		return false, "Invalid email"
	elseif not password then
		return false, "Invalid password"
	end

	email = email:lower()

	local user = Users:find({email = email})

	if user then
		return false, "This email is already registered"
	end

	user = Users:create({
		name = name,
		tag = ("%4d"):format(math.random(1, 9999)),
		email = email,
		password = bcrypt.digest(password, 5),
		latest_activity = 0,
		creation_time = 0,
		description = "",
	})

	return user
end

users_c.POST = function(request)
	local params = request.params
	local user = params.user
	local err
	user, err = register(user.name, user.email, user.password)

	if user then
		return 200, {user = Users:safe_copy(user)}
	end

	return 200, {message = err}
end

return users_c
