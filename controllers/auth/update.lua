local jwt = require("luajwt")
local secret = require("secret")
local login_c = require("controllers.auth.login")

local update_c = {}

update_c.POST = function(request)
	local session = request.context.session

	if not session or session.active == 0 then
		return 200, {
			message = "not session or session.active == 0"
		}
	end

	if session.updated_at - request.session.updated_at ~= 0 then
		session.active = 0
		session:update("active")
		return 200, {
			message = "session.updated_at ~= request.session.updated_at"
		}
	end

	session.updated_at = os.time()
	session:update("updated_at")

	local payload = login_c.copy_session(session)
	local token, err = jwt.encode(payload, secret.token_key, "HS256")

	return 200, {
		token = token,
		session = payload,
	}
end

return update_c
