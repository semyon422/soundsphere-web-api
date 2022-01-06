local Community_difftables = require("models.community_difftables")
local Community_leaderboards = require("models.community_leaderboards")
local array_update = require("util.array_update")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local community_difftables_c = Controller:new()

community_difftables_c.path = "/communities/:community_id[%d]/difftables"
community_difftables_c.methods = {"GET"}

community_difftables_c.policies.GET = {{"permit"}}
community_difftables_c.validations.GET = util.add_belongs_to_validations(Community_difftables.relations)
community_difftables_c.GET = function(self)
	local params = self.params

	local community_leaderboards = Community_leaderboards:find_all({params.community_id}, "community_id")
	preload(community_leaderboards, {leaderboard = {leaderboard_difftables = "difftable"}})

	local leaderboard_difftables = {}
	for _, community_leaderboard in ipairs(community_leaderboards) do
		for _, leaderboard_difftable in ipairs(community_leaderboard.leaderboard.leaderboard_difftables) do
			table.insert(leaderboard_difftables, leaderboard_difftable)
		end
	end

	local new_difftable_ids, old_difftable_ids, all_difftable_ids = array_update(
		leaderboard_difftables,
		Community_difftables:find_all({params.community_id}, "community_id"),
		function(li) return li.difftable_id end,
		function(ci) return ci.difftable_id end
	)

	local db = Community_difftables.db
	if #old_difftable_ids > 0 then
		db.delete("community_difftables", {difftable_id = db.list(old_difftable_ids)})
	end
	for _, difftable_id in ipairs(new_difftable_ids) do
		db.insert("community_difftables", {
			community_id = params.community_id,
			difftable_id = difftable_id,
		})
	end

	local community_difftables = Community_difftables:find_all({params.community_id}, "community_id")
	preload(community_difftables, util.get_relatives_preload(Community_difftables, params))
	util.recursive_to_name(community_difftables)

	return {json = {
		total = #community_difftables,
		filtered = #community_difftables,
		community_difftables = community_difftables,
	}}
end

return community_difftables_c
