local domains = require("models.domains")

local context_loader = {}

function context_loader:load_context(context)
	if context.domain then return print("context.domain") end
	local domain_id = context.req.params.domain_id
	if domain_id then
		context.domain = domains:find(domain_id)
	end
end

return context_loader