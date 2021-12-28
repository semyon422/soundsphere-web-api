local Users = require("models.users")
local bcrypt = require("bcrypt")
local db_search = require("util.db_search")
local db_where = require("util.db_where")
local Controller = require("Controller")

local register_c = Controller:new()

register_c.path = "/auth/register"
register_c.methods = {"POST"}

register_c.register = function(name, email, password)
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

	local time = os.time()
	user = Users:create({
		name = name,
		tag = ("%4d"):format(math.random(1, 9999)),
		email = email,
		password = bcrypt.digest(password, 5),
		latest_activity = time,
		created_at = time,
		description = "",
	})

	return user
end

register_c.policies.POST = {{"permit"}}
register_c.validations.POST = {
	{"user", exists = true, type = "table", body = true, validations = {
		{"name", exists = true, type = "string"},
		{"email", exists = true, type = "string"},
		{"password", exists = true, type = "string"},
	}}
}
register_c.POST = function(request)
	local params = request.params
	local user = params.user
	local err
	user, err = register_c.register(user.name, user.email, user.password)

	if not user then
		return 200, {message = err}
	end

	return 200, {user = user:to_name()}
end

return register_c
