local Users = require("models.users")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("user", function(self)
	local user_id = self.params.user_id
	if user_id then
		return Users:find(user_id)
	end
end)
