local jwt = require("luajwt")
local secret = require("secret")
local login_c = require("controllers.auth.login")

local update_c = {}

update_c.path = "/auth/update"
update_c.methods = {"POST"}
update_c.context = {"session"}
update_c.policies = {
	POST = {{
		rules = {require("rules.authenticated")},
		combine = require("abac.combine.permit_all_or_deny"),
	}},
}

update_c.POST = function(request)
	local session = request.context.session

	if not session or not session.active then
		return 200, {
			message = "not session or not session.active"
		}
	end

	if session.updated_at - request.session.updated_at ~= 0 then
		session.active = false
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
