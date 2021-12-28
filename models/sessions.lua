local Model = require("lapis.db.model").Model
local toboolean = require("util.toboolean")

local Sessions = Model:extend(
	"sessions",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
		},
		url_params = function(self, req, ...)
			return "user.session", {session_id = self.id, user_id = req.params.user_id}, ...
		end,
	}
)

local _load = Sessions.load
function Sessions:load(row)
	row.active = toboolean(row.active)
	row.created_at = tonumber(row.created_at)
	row.updated_at = tonumber(row.updated_at)
	return _load(self, row)
end

local not_safe_fields = {
	-- ip = true,
}

Sessions.safe_copy = function(self, session)
	if not session then return end
	local safe_session = {}
	for k, v in pairs(session) do
		if type(k) == "string" and not not_safe_fields[k] then
			safe_session[k] = v
		end
	end
	return setmetatable(safe_session, getmetatable(session))
end

return Sessions
