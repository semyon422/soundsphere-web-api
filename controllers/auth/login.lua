local preload = require("lapis.db.model").preload
local Users = require("models.users")
local Sessions = require("models.sessions")
local bcrypt = require("bcrypt")
local jwt = require("luajwt")
local secret = require("secret")

local login_c = {}

local failed = "Login failed. Invalid email or password"
local function login(email, password)
	if not email or not password then return false, failed end
	local user = Users:find({email = email:lower()})
	if not user then return false, failed end
	local valid = bcrypt.verify(password, user.password)
	if valid then return user end
	return false, failed
end

login_c.new_token = function(user, ip)
	local time = os.time()
	local session = Sessions:create({
		user_id = user.id,
		active = true,
		ip = ip,
		created_at = time,
		updated_at = time,
	})

	local payload = {
		id = session.id,
		user_id = session.user_id,
		created_at = session.created_at,
		updated_at = session.updated_at,
	}
	local token, err = jwt.encode(payload, secret.token_key, "HS256")

	return token, payload
end

login_c.POST = function(request)
	local context = request.context
	local user, err = login(context.basic.email, context.basic.password)

	if not user then
		return 200, {}
	end

	local token, payload = login_c.new_token(user, context.ip)

	return 200, {
		token = token,
		session = payload,
	}
end

return login_c
