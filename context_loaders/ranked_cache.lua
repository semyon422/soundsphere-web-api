local Ranked_caches = require("models.ranked_caches")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("ranked_cache", function(self)
	local ranked_cache_id = self.params.ranked_cache_id
	if ranked_cache_id then
		return Ranked_caches:find(ranked_cache_id)
	end
end)
