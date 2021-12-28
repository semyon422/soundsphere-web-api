local jwt = require("luajwt")
local secret = require("secret")
local login_c = require("controllers.auth.login")
local Sessions = require("models.sessions")
local Controller = require("Controller")

local update_c = Controller:new()

update_c.path = "/auth/update"
update_c.methods = {"POST"}

update_c.context.POST = {"request_session"}
update_c.policies.POST = {{"authenticated"}}
update_c.POST = function(request)
	local session = request.context.request_session

	if session.updated_at - request.session.updated_at ~= 0 then
		session.active = false
		session:update("active")
		return 200, {
			message = "session.updated_at ~= request.session.updated_at"
		}
	end

	session.updated_at = os.time()
	session:update("updated_at")

	local payload = Sessions:safe_copy(session)
	payload.active = nil
	payload.ip = nil

	local token, err = jwt.encode(payload, secret.token_key, "HS256")
	login_c.copy_session(payload, request.session)

	return 200, {
		token = token,
		session = payload,
	}
end

return update_c
