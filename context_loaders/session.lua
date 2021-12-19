local Sessions = require("models.sessions")

return function(self)
	if self.context.session then return end
	local session_id = self.session.id
	if session_id then
		self.context.session = Sessions:find(self.session.id)
	end
end
