local Community_leaderboards = require("models.community_leaderboards")
local Leaderboards = require("models.leaderboards")
local Controller = require("Controller")
local preload = require("lapis.db.model").preload
local util = require("util")
local Joined_query = require("util.joined_query")

local community_leaderboards_c = Controller:new()

community_leaderboards_c.path = "/communities/:community_id[%d]/leaderboards"
community_leaderboards_c.methods = {"GET"}

community_leaderboards_c.get_leaderboards = function(self)
	local params = self.params
	local community_id = params.community_id

	local db = Community_leaderboards.db

	local jq = Joined_query:new(db)
	jq:select("cl")
	if params.owned then
		jq:select("inner join leaderboards l on cl.leaderboard_id = l.id and cl.community_id = l.owner_community_id")
		jq:where("cl.accepted = ?", true)
		jq:where("cl.community_id = ?", community_id)
	elseif params.outgoing or params.incoming then
		jq:select("inner join leaderboards l on cl.leaderboard_id = l.id")
		jq:where("cl.accepted = ?", false)
		if params.outgoing and params.incoming then
			jq:where(
				"(cl.community_id = ? and l.owner_community_id != ?) or (cl.community_id != ? and l.owner_community_id = ?)",
				community_id, community_id, community_id, community_id
			)
		elseif params.outgoing and not params.incoming then
			jq:where("cl.community_id = ?", community_id)
			jq:where("l.owner_community_id != ?", community_id)
		elseif not params.outgoing and params.incoming then
			jq:where("cl.community_id != ?", community_id)
			jq:where("l.owner_community_id = ?", community_id)
		end
	else
		jq:where("cl.community_id = ?", community_id)
		jq:where("cl.accepted = ?", true)
	end
	jq:fields("cl.*")
	jq:orders("cl.id desc")

	local query, options = jq:concat()
    local community_leaderboards = Community_leaderboards:select(query, options)
	return community_leaderboards, query
end

community_leaderboards_c.policies.GET = {{"permit"}}
community_leaderboards_c.validations.GET = {
	require("validations.no_data"),
	{"incoming", type = "boolean", optional = true},
	{"outgoing", type = "boolean", optional = true},
	{"owned", type = "boolean", optional = true},
}
util.add_belongs_to_validations(Community_leaderboards.relations, community_leaderboards_c.validations.GET)
util.add_has_many_validations(Leaderboards.relations, community_leaderboards_c.validations.GET)
community_leaderboards_c.GET = function(self)
	local params = self.params

	local community_leaderboards = community_leaderboards_c.get_leaderboards(self)

	if params.no_data then
		return {json = {
			total = #community_leaderboards,
			filtered = #community_leaderboards,
		}}
	end

	preload(community_leaderboards, util.get_relatives_preload(Community_leaderboards, params))
	util.relatives_preload_field(community_leaderboards, "leaderboard", Leaderboards, params)
	util.recursive_to_name(community_leaderboards)

	util.get_methods_for_objects(
		self,
		community_leaderboards,
		require("controllers.leaderboard"),
		"leaderboard",
		nil,
		function(community_leaderboard)
			return community_leaderboard.leaderboard
		end
	)

	return {json = {
		total = #community_leaderboards,
		filtered = #community_leaderboards,
		community_leaderboards = community_leaderboards,
	}}
end

return community_leaderboards_c
