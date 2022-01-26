local User_inputmodes = require("models.user_inputmodes")
local Inputmodes = require("enums.inputmodes")

return function(self)
	if self.context.user_inputmode then return true end
	local user_id = self.params.user_id
	local inputmode = self.params.inputmode
	if user_id and inputmode then
		self.context.user_inputmode = User_inputmodes:find({
			user_id = user_id,
			inputmode = Inputmodes:for_db(inputmode),
		})
	end
	return self.context.user_inputmode
end
