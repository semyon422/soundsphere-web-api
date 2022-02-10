local User_inputmodes = require("models.user_inputmodes")
local Inputmodes = require("enums.inputmodes")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("user_inputmode", function(self)
	local user_id = self.params.user_id
	local inputmode = self.params.inputmode
	if user_id and inputmode then
		return User_inputmodes:find({
			user_id = user_id,
			inputmode = Inputmodes:for_db(inputmode),
		})
	end
end)
