local Communities = require("models.communities")

local context_loader = {}

function context_loader:load_context(request)
	if request.context.community then return print("context.community") end
	local community_id = request.params.community_id
	if community_id then
		request.context.community = Communities:find(community_id)
	end
end

return context_loader
