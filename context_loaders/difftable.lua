local Difftables = require("models.difftables")

local context_loader = {}

function context_loader:load_context(request)
	if request.context.difftable then return print("context.difftable") end
	local difftable_id = request.params.difftable_id
	if difftable_id then
		request.context.difftable = Difftables:find(difftable_id)
	end
end

return context_loader
