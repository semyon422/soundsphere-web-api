local Ranked_caches = require("models.ranked_caches")

return function(self)
	if self.context.ranked_cache then return true end
	local ranked_cache_id = self.params.ranked_cache_id
	if ranked_cache_id then
		self.context.ranked_cache = Ranked_caches:find(ranked_cache_id)
	end
	return self.context.ranked_cache
end
