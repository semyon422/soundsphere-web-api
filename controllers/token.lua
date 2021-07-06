local preload = require("lapis.db.model").preload
local Users = require("models.users")
local bcrypt = require("bcrypt")
local jwt = require("luajwt")

local key = "example_key"

local token_c = {}

local failed = "Login failed. Invalid email or password"
local login = function(email, password)
	if not email or not password then return false, failed end
	local user = Users:find({email = email:lower()})
	if not user then return false, failed end
	local valid = bcrypt.verify(password, user.password)
	if valid then return user end
	return false, failed
end

token_c.GET = function(params)
	local user, err = login(params.email, params.password)

	local response = {}

	if user then
		local payload = {
			user_id = user.id,
			nbf = os.time(),
		}
		local token, err = jwt.encode(payload, key, "HS256")
		if token then
			response.token = token
		end
	end

	return 200, response
end

return token_c
