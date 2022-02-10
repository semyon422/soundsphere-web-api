
local Ranked_cache_difftables = require("models.ranked_cache_difftables")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("ranked_cache_difftable", function(self)
	local ranked_cache_id = self.params.ranked_cache_id
	local difftable_id = self.params.difftable_id
	if ranked_cache_id and difftable_id then
		return Ranked_cache_difftables:find({
			ranked_cache_id = ranked_cache_id,
			difftable_id = difftable_id,
		})
	end
end)
