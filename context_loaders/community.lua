local Communities = require("models.communities")

return function(self)
	if self.context.community then return end
	local community_id = self.params.community_id
	if community_id then
		self.context.community = Communities:find(community_id)
	end
end
