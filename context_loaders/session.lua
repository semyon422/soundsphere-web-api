local Sessions = require("models.sessions")

return function(self)
	if self.context.session then return true end
	local session_id = self.session.id
	if session_id then
		print(session_id)
		self.context.session = Sessions:find(self.session.id)
	end
	return self.context.session
end
