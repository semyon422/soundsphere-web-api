local Sessions = require("models.sessions")

return function(self)
	if self.context.request_session then return true end
	local session_id = self.session.id
	if session_id then
		self.context.request_session = Sessions:find(session_id)
	end
	return self.context.request_session
end
