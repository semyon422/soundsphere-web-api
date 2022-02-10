local Sessions = require("models.sessions")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("request_session", function(self)
	local session_id = self.session.id
	if session_id then
		return Sessions:find(session_id)
	end
end)
