local preload = require("lapis.db.model").preload
local users = require("models.users")
local util = require("lapis.util")
local bcrypt = require("bcrypt")
local jwt = require("luajwt")

local key = "example_key"

local token_c = {}

local failed = "Login failed. Invalid email or password"
local login = function(email, password)
	if not email or not password then return false, failed end
	local entry = users:find({email = email:lower()})
	if not entry then return false, failed end
	local valid = bcrypt.verify(password, entry.password)
	if valid then return entry end
	return false, failed
end

token_c.GET = function(req, res, go)
	local basic = req.basic
	if not basic then return end
	local user_entry, err = login(basic.email, basic.password)

	local json_response = {}

	res.code = 200
	res.headers["Content-Type"] = "application/json"

	if user_entry then
		local payload = {
			user_id = user_entry.id,
			nbf = os.time(),
		}
		local token, err = jwt.encode(payload, key, "HS256")
		if token then
			json_response.token = util.to_json({token = token})
		end
	end

	res.body = util.to_json(json_response)
end

return token_c
