local Leaderboard_difftables = require("models.leaderboard_difftables")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local leaderboard_difftables_c = Controller:new()

leaderboard_difftables_c.path = "/leaderboards/:leaderboard_id[%d]/difftables"
leaderboard_difftables_c.methods = {"GET", "PATCH"}

leaderboard_difftables_c.update_difftables = function(leaderboard_id, difftables)
	if not difftables then
		return
	end

	local leaderboard_difftables = Leaderboard_difftables:find_all({leaderboard_id}, "leaderboard_id")

	local new_difftable_ids, old_difftable_ids = util.array_update(
		difftables,
		leaderboard_difftables,
		function(ld) return ld.difftable_id end,
		function(ld) return ld.difftable_id end
	)

	local db = Leaderboard_difftables.db
	if #old_difftable_ids > 0 then
		db.delete("leaderboard_difftables", {difftable_id = db.list(old_difftable_ids)})
	end
	for _, difftable_id in ipairs(new_difftable_ids) do
		db.insert("leaderboard_difftables", {
			leaderboard_id = leaderboard_id,
			difftable_id = difftable_id,
		})
	end
end

leaderboard_difftables_c.policies.GET = {{"permit"}}
leaderboard_difftables_c.validations.GET = {
	require("validations.no_data"),
}
leaderboard_difftables_c.validations.GET = util.add_belongs_to_validations(Leaderboard_difftables.relations)
leaderboard_difftables_c.GET = function(self)
	local params = self.params
    local leaderboard_difftables = Leaderboard_difftables:find_all({params.leaderboard_id}, "leaderboard_id")

	if params.no_data then
		return {json = {
			total = #leaderboard_difftables,
			filtered = #leaderboard_difftables,
		}}
	end

	preload(leaderboard_difftables, util.get_relatives_preload(Leaderboard_difftables, params))
	util.recursive_to_name(leaderboard_difftables)

	return {json = {
		total = #leaderboard_difftables,
		filtered = #leaderboard_difftables,
		leaderboard_difftables = leaderboard_difftables,
	}}
end

leaderboard_difftables_c.context.PATCH = util.get_owner_context("leaderboard", "context")
leaderboard_difftables_c.policies.PATCH = {
	{"authenticated", {community_role = "moderator"}},
	{"authenticated", {community_role = "admin"}},
	{"authenticated", {community_role = "creator"}},
}
leaderboard_difftables_c.validations.PATCH = {
	{"leaderboard_difftables", exists = true, type = "table", param_type = "body"}
}
leaderboard_difftables_c.PATCH = function(self)
	local params = self.params

	leaderboard_difftables_c.update_difftables(params.leaderboard_id, params.leaderboard_difftables)
	local leaderboard_difftables = Leaderboard_difftables:find_all({params.leaderboard_id}, "leaderboard_id")
	util.recursive_to_name(leaderboard_difftables)

	return {json = {
		total = #leaderboard_difftables,
		filtered = #leaderboard_difftables,
		leaderboard_difftables = leaderboard_difftables,
	}}
end

return leaderboard_difftables_c
