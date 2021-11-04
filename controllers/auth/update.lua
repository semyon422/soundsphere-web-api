local Sessions = require("models.sessions")
local jwt = require("luajwt")
local secret = require("secret")

local update_c = {}

update_c.POST = function(request)
	local token = request.params.token
	local decoded, err = jwt.decode(token, secret.token_key, true)

	if not decoded then
		return 200, {
			message = "not decoded"
		}
	end

	local session = Sessions:find(decoded.id)

	if not session or session.active == 0 then
		return 200, {
			message = "not session or session.active == 0"
		}
	end

	if tonumber(session.updated_at) ~= tonumber(decoded.updated_at) then
		session.active = 0
		session:update("active")
		return 200, {
			message = "session.updated_at ~= decoded.updated_at"
		}
	end

	session.updated_at = os.time()
	session:update("updated_at")

	local payload = {
		id = session.id,
		user_id = session.user_id,
		created_at = tonumber(session.created_at),
		updated_at = tonumber(session.updated_at),
	}
	local token, err = jwt.encode(payload, secret.token_key, "HS256")

	return 200, {
		token = token,
		session = payload,
	}
end

return update_c
