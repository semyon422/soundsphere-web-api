local Sessions = require("models.sessions")
local Controller = require("Controller")
local preload = require("lapis.db.model").preload
local util = require("util")

local user_sessions_c = Controller:new()

user_sessions_c.path = "/users/:user_id[%d]/sessions"
user_sessions_c.methods = {"GET"}

user_sessions_c.context.GET = {"request_session"}
user_sessions_c.policies.GET = {{"authed"}}
user_sessions_c.validations.GET = {
	{"show_ip", type = "boolean", optional = true},
}
user_sessions_c.validations.GET = util.add_belongs_to_validations(Sessions.relations)
user_sessions_c.GET = function(self)
	local params = self.params
	local sessions = Sessions:find_all({params.user_id}, {
		key = "user_id",
		where = {
			active = true
		}
	})

	if params.no_data then
		return {json = {
			total = #sessions,
			filtered = #sessions,
		}}
	end

	local request_session = self.context.request_session
	local request_session_id = request_session and request_session.id

	preload(sessions, util.get_relatives_preload(Sessions, params))
	util.recursive_to_name(sessions)

	local safe_sessions = {}
	for _, session in ipairs(sessions) do
		if request_session_id and request_session_id == session.id then
			session.is_current = true
		end
		if not params.show_ip then
			session.ip = nil
		end
		table.insert(safe_sessions, session)
	end

	return {json = {sessions = safe_sessions}}
end

return user_sessions_c
