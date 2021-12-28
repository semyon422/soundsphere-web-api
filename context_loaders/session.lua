local Sessions = require("models.sessions")

return function(self)
	if self.context.session then return true end
	local session_id = self.params.session_id
	if session_id then
		self.context.session = Sessions:find(session_id)
	end
	return self.context.session
end
