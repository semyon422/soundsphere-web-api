local Community_leaderboards = require("models.community_leaderboards")
local Users = require("models.users")
local Inputmodes = require("enums.inputmodes")
local Controller = require("Controller")
local preload = require("lapis.db.model").preload

local community_leaderboards_c = Controller:new()

community_leaderboards_c.path = "/communities/:community_id[%d]/leaderboards"
community_leaderboards_c.methods = {"GET"}

community_leaderboards_c.get_joined = function(request)
	local params = request.params

	local where = {
		community_id = params.community_id,
		accepted = true,
	}

	local clause = Community_leaderboards.db.encode_clause(where)
    local community_leaderboards = Community_leaderboards:select("where " .. clause .. " order by id asc")
	preload(community_leaderboards, {leaderboard = "leaderboard_inputmodes", "sender"})

	return community_leaderboards
end

community_leaderboards_c.get_owned = function(request)
	local params = request.params

	local where = {
		community_id = params.community_id,
		is_owner = true,
		accepted = true,
	}

	local clause = Community_leaderboards.db.encode_clause(where)
    local community_leaderboards = Community_leaderboards:select("where " .. clause .. " order by id asc")
	preload(community_leaderboards, {leaderboard = "leaderboard_inputmodes", "sender"})

	return community_leaderboards
end

community_leaderboards_c.get_incoming = function(request)
	local params = request.params
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
	preload(community_leaderboards, {"leaderboard", "community", "sender"})

	return community_leaderboards
end

community_leaderboards_c.get_outgoing = function(request)
	local params = request.params

	local where = {
		community_id = params.community_id,
		is_owner = false,
		accepted = false,
	}

	local clause = Community_leaderboards.db.encode_clause(where)
    local community_leaderboards = Community_leaderboards:select("where " .. clause .. " order by id asc")
	preload(community_leaderboards, {"leaderboard", "community", "sender"})

	return community_leaderboards
end

community_leaderboards_c.policies.GET = {{"permit"}}
community_leaderboards_c.validations.GET = {
	require("validations.no_data"),
	{"incoming", type = "boolean", optional = true},
	{"outgoing", type = "boolean", optional = true},
	{"owned", type = "boolean", optional = true},
}
community_leaderboards_c.GET = function(request)
	local params = request.params

	local community_leaderboards
	if params.incoming then
		community_leaderboards = community_leaderboards_c.get_incoming(request)
	elseif params.outgoing then
		community_leaderboards = community_leaderboards_c.get_outgoing(request)
	elseif params.owned then
		community_leaderboards = community_leaderboards_c.get_owned(request)
	else
		community_leaderboards = community_leaderboards_c.get_joined(request)
	end

	if params.no_data then
		return {json = {
			total = #community_leaderboards,
			filtered = #community_leaderboards,
		}}
	end

	for _, community_leaderboard in ipairs(community_leaderboards) do
		local leaderboard = community_leaderboard.leaderboard
		if leaderboard.leaderboard_inputmodes then
			leaderboard.inputmodes = Inputmodes:entries_to_list(leaderboard.leaderboard_inputmodes)
			leaderboard.leaderboard_inputmodes = nil
		end
		if community_leaderboard.sender then
			community_leaderboard.sender = community_leaderboard.sender:to_name()
		end
	end

	local leaderboards = {}
	for _, community_leaderboard in ipairs(community_leaderboards) do
		local leaderboard = community_leaderboard.leaderboard
		leaderboard.community_leaderboard = community_leaderboard
		community_leaderboard.leaderboard = nil
		table.insert(leaderboards, leaderboard)
	end

	return {json = {
		total = #community_leaderboards,
		filtered = #community_leaderboards,
		leaderboards = leaderboards,
	}}
end

return community_leaderboards_c
