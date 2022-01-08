local Community_leaderboards = require("models.community_leaderboards")
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

	local where = {
		community_id = params.community_id,
		is_owner = true,
		accepted = true,
	}

	local clause = Community_leaderboards.db.encode_clause(where)
    local community_leaderboards = Community_leaderboards:select("where " .. clause .. " order by id asc")

	return community_leaderboards
end

community_leaderboards_c.get_incoming = function(self)
	local params = self.params
	local db = Community_leaderboards.db

	local clause = db.encode_clause({
		community_id = params.community_id,
		is_owner = true,
	})
    local community_leaderboards = Community_leaderboards:select(
		"where " .. clause .. " order by id asc",
		{fields = "leaderboard_id"}
	)

	local leaderboard_ids = {}
	for _, community_leaderboard in ipairs(community_leaderboards) do
		table.insert(leaderboard_ids, community_leaderboard.leaderboard_id)
	end

	clause = db.encode_clause({
		leaderboard_id = #leaderboard_ids > 0 and db.list(leaderboard_ids),
		community_id = db.list({params.community_id}),
		accepted = false,
	}):gsub("`community_id` IN", "`community_id` NOT IN")
	community_leaderboards = Community_leaderboards:select("where " .. clause .. " order by id asc")

	return community_leaderboards
end

community_leaderboards_c.get_outgoing = function(self)
	local params = self.params

	local where = {
		community_id = params.community_id,
		is_owner = false,
		accepted = false,
	}

	local clause = Community_leaderboards.db.encode_clause(where)
    local community_leaderboards = Community_leaderboards:select("where " .. clause .. " order by id asc")

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
	util.recursive_to_name(community_leaderboards)

	return {json = {
		total = #community_leaderboards,
		filtered = #community_leaderboards,
		community_leaderboards = community_leaderboards,
	}}
end

return community_leaderboards_c
