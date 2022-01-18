local Model = require("lapis.db.model").Model

local Ranked_cache_difftables = Model:extend(
	"ranked_cache_difftables",
	{
		relations = {
			{"ranked_cache", belongs_to = "ranked_caches", key = "ranked_cache_id"},
			{"difftable", belongs_to = "difftables", key = "difftable_id"},
		},
		url_params = function(self, req, ...)
			return "ranked_cache.difftable", {ranked_cache_id = self.ranked_cache_id, difftable_id = self.difftable_id}, ...
		end,
	}
)

return Ranked_cache_difftables
