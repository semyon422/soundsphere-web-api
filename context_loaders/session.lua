local Sessions = require("models.sessions")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("session", function(self)
	local session_id = self.params.session_id
	if session_id then
		return Sessions:find(session_id)
	end
end)
