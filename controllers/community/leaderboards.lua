local Community_leaderboards = require("models.community_leaderboards")
local Leaderboards = require("models.leaderboards")
local Controller = require("Controller")
local preload = require("lapis.db.model").preload
local util = require("util")

local community_leaderboards_c = Controller:new()

community_leaderboards_c.path = "/communities/:community_id[%d]/leaderboards"
community_leaderboards_c.methods = {"GET"}

community_leaderboards_c.get_joined = function(self)
	local params = self.params

	local where = {
		community_id = params.community_id,
		accepted = true,
	}

	local clause = Community_leaderboards.db.encode_clause(where)
    local community_leaderboards = Community_leaderboards:select("where " .. clause .. " order by id asc")

	return community_leaderboards
end

community_leaderboards_c.get_owned = function(self)
	local params = self.params

    local community_leaderboards = Community_leaderboards:select(
		"cl " ..
		"inner join leaderboards l on cl.leaderboard_id = l.id and cl.community_id = l.owner_community_id " ..
		"where cl.community_id = ? and cl.accepted = ? " ..
		"order by id asc",
		params.community_id, true,
		{fields = "cl.*"}
	)

	return community_leaderboards
end

community_leaderboards_c.get_incoming = function(self)
	local params = self.params

    local community_leaderboards = Community_leaderboards:select(
		"cl " ..
		"inner join leaderboards l on cl.leaderboard_id = l.id and cl.community_id = l.owner_community_id " ..
		"where cl.community_id != ? and cl.accepted = ? " ..
		"order by id asc",
		params.community_id, false,
		{fields = "cl.*"}
	)

	return community_leaderboards
end

community_leaderboards_c.get_outgoing = function(self)
	local params = self.params

    local community_leaderboards = Community_leaderboards:select(
		"cl " ..
		"inner join leaderboards l on cl.leaderboard_id = l.id and cl.community_id != l.owner_community_id " ..
		"where cl.community_id = ? and cl.accepted = ? " ..
		"order by id asc",
		params.community_id, false,
		{fields = "cl.*"}
	)

	return community_leaderboards
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

	local community_leaderboards
	if params.incoming then
		community_leaderboards = community_leaderboards_c.get_incoming(self)
	elseif params.outgoing then
		community_leaderboards = community_leaderboards_c.get_outgoing(self)
	elseif params.owned then
		community_leaderboards = community_leaderboards_c.get_owned(self)
	else
		community_leaderboards = community_leaderboards_c.get_joined(self)
	end

	if params.no_data then
		return {json = {
			total = #community_leaderboards,
			filtered = #community_leaderboards,
		}}
	end

	preload(community_leaderboards, util.get_relatives_preload(Community_leaderboards, params))
	util.relatives_preload_field(community_leaderboards, "leaderboard", Leaderboards, params)
	util.recursive_to_name(community_leaderboards)

	return {json = {
		total = #community_leaderboards,
		filtered = #community_leaderboards,
		community_leaderboards = community_leaderboards,
	}}
end

return community_leaderboards_c
