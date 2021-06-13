local communities = require("models.communities")

local context_loader = {}

function context_loader:load_context(context)
	if context.community then return print("context.community") end
	local community_id = context.req.params.community_id
	if community_id then
		context.community = communities:find(community_id)
	end
end

return context_loader