
local Ranked_cache_difftables = require("models.ranked_cache_difftables")

return function(self)
	if self.context.ranked_cache_difftable then return true end
	local ranked_cache_id = self.params.ranked_cache_id
	local difftable_id = self.params.difftable_id
	if ranked_cache_id and difftable_id then
		self.context.ranked_cache_difftable = Ranked_cache_difftables:find({
			ranked_cache_id = ranked_cache_id,
			difftable_id = difftable_id,
		})
	end
	return self.context.ranked_cache_difftable
end