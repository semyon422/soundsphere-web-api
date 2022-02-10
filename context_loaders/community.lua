local Communities = require("models.communities")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("community", function(self)
	local community_id = self.params.community_id
	if community_id then
		return Communities:find(community_id)
	end
end)
