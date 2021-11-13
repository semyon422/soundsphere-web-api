local Users = require("models.users")
local bcrypt = require("bcrypt")

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

	local paginator = Users:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local users = paginator:get_page(page_num)

	local new_users = {}
	for _, db_user_entry in ipairs(users) do
		table.insert(
			new_users,
			{
				id = db_user_entry.id,
				name = db_user_entry.name,
				tag = db_user_entry.tag,
				latest_activity = db_user_entry.latest_activity,
			}
		)
	end

	local count = Users:count()

	return 200, {
		total = count,
		filtered = count,
		users = new_users
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
	local digest = bcrypt.digest(password, 5)

	local user = Users:find({email = email})

	if user then
		return false, "This email is already registered"
	end

	user = Users:create({
		name = name,
		tag = ("%4d"):format(math.random(1, 9999)),
		email = email,
		password = digest,
	})

	return user
end

users_c.POST = function(request)
	local params = request.params
	local user, err = register(params.name, params.email, params.password)

	if user then
		return 200, {
			user = {
				id = user.id,
				name = user.name,
				tag = user.tag
			}
		}
	end

	return 400, {error = err}
end

return users_c
