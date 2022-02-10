local Users = require("models.users")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("session_user", function(self)
	local user_id = self.session.user_id
	if user_id then
		return Users:find(user_id)
	end
end)
