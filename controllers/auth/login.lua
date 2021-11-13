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

login_c.copy_session = function(src, dst)
	dst = dst or {}
	dst.id = tonumber(src.id)
	dst.user_id = tonumber(src.user_id)
	dst.created_at = tonumber(src.created_at)
	dst.updated_at = tonumber(src.updated_at)
	return dst
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

	local payload = login_c.copy_session(session)
	local token, err = jwt.encode(payload, secret.token_key, "HS256")

	return token, payload
end

login_c.POST = function(request)
	local params = request.params

	local user, err = login(params.email, params.password)

	if not user then
		return 200, {}
	end

	local token, payload = login_c.new_token(user, request.context.ip)

	login_c.copy_session(payload, request.session)

	return 200, {
		token = token,
		session = payload,
	}
end

return login_c
