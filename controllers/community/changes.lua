local Community_changes = require("models.community_changes")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local community_changes_c = Controller:new()

community_changes_c.path = "/communities/:community_id[%d]/changes"
community_changes_c.methods = {"GET"}

community_changes_c.policies.GET = {{"permit"}}
community_changes_c.validations.GET = {
	require("validations.no_data"),
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.get_all"),
}
util.add_belongs_to_validations(Community_changes.relations, community_changes_c.validations.GET)
community_changes_c.GET = function(self)
	local params = self.params

	local per_page = params.per_page or 10
	local page_num = params.page_num or 1
	local paginator = Community_changes:paginated(
		"where community_id = ? order by created_at desc", params.community_id,
		{
			per_page = per_page,
		}
	)
	local community_changes = params.get_all and paginator:get_all() or paginator:get_page(page_num)

	local count = tonumber(Community_changes:count("community_id = ?", params.community_id))
	if params.no_data then
		return {json = {
			total = count,
			filtered = count,
		}}
	end

	preload(community_changes, util.get_relatives_preload(Community_changes, params))
	util.recursive_to_name(community_changes)

	return {json = {
		total = count,
		filtered = count,
		community_changes = community_changes,
	}}
end

return community_changes_c
