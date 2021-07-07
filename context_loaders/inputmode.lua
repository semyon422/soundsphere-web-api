local Inputmodes = require("models.inputmodes")

local context_loader = {}

function context_loader:load_context(context)
	if context.inputmode then return print("context.inputmode") end
	local inputmode_id = context.req.params.inputmode_id
	if inputmode_id then
		context.inputmode = Inputmodes:find(inputmode_id)
	end
end

return context_loader
