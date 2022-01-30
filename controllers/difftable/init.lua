local Difftables = require("models.difftables")
local Difftable_notecharts = require("models.difftable_notecharts")
local Files = require("models.files")
local Community_changes = require("models.community_changes")
local Notecharts = require("models.notecharts")
local Communities = require("models.communities")
local Ranked_caches = require("models.ranked_caches")
local Ranked_cache_difftables = require("models.ranked_cache_difftables")
local Controller = require("Controller")
local Formats = require("enums.formats")
local Filehash = require("util.filehash")
local util = require("util")
local difftable_notechart_c = require("controllers.difftable.notechart")

local additions = {
	communities = require("controllers.difftable.communities"),
	leaderboards = require("controllers.difftable.leaderboards"),
	notecharts = require("controllers.difftable.notecharts"),
	inputmodes = require("controllers.difftable.inputmodes"),
}

local difftable_c = Controller:new()

difftable_c.path = "/difftables/:difftable_id[%d]"
difftable_c.methods = {"GET", "PATCH", "PUT", "DELETE"}

local set_community_id = function(self)
	self.params.community_id = self.context.difftable.owner_community_id
	return true
end

difftable_c.context.GET = {"difftable"}
difftable_c.policies.GET = {{"permit"}}
difftable_c.validations.GET = {}
util.add_additions_validations(additions, difftable_c.validations.GET)
util.add_belongs_to_validations(Difftables.relations, difftable_c.validations.GET)
difftable_c.GET = function(self)
	local params = self.params
	local difftable = self.context.difftable

	util.get_relatives(difftable, self.params, true)
	util.load_additions(self, difftable, additions)

	return {json = {difftable = difftable}}
end

difftable_c.context.PATCH = {"difftable", "request_session", "session_user", "user_communities", set_community_id}
difftable_c.policies.PATCH = {
	{"authed", {community_role = "admin"}, {not_params = "transfer_ownership"}},
	{"authed", {community_role = "creator"}},
}
difftable_c.validations.PATCH = {
	{"difftable", exists = true, type = "table", param_type = "body", validations = {
		{"name", exists = true, type = "string"},
		{"link", exists = true, type = "string"},
		{"description", exists = true, type = "string"},
		{"symbol", exists = true, type = "string"},
		{"owner_community_id", exists = true, type = "number"},
	}},
	{"transfer_ownership", type = "boolean", optional = true},
}
difftable_c.PATCH = function(self)
	local params = self.params
	local difftable = self.context.difftable

	local found_difftable = Difftables:find({name = params.difftable.name})
	if found_difftable and found_difftable.id ~= difftable.id then
		return {status = 400, json = {message = "This name is already taken"}}
	end

	local community = Communities:find(params.difftable.owner_community_id)
	if not community then
		return {status = 400, json = {message = "not community"}}
	end

	if params.transfer_ownership then
		local owner_community_id = difftable.owner_community_id
		difftable.owner_community_id = params.leaderboard.owner_community_id
		difftable:update("owner_community_id")
		Community_changes:add_change(
			self.context.session_user.id,
			owner_community_id,
			"transfer_ownership",
			difftable
		)
		return
	end

	util.patch(difftable, params.difftable, {
		"name",
		"link",
		"description",
		"symbol",
	})

	return {json = {difftable = difftable}}
end

difftable_c.add_bms_notechart = function(self, difftable_id, bms_notechart)
	local created_at = os.time()
	local hash_for_db = Filehash:for_db(bms_notechart.md5)
	local format_for_db = Formats:for_db("bms")
	local difficulty = tonumber(bms_notechart.level) or 0

	local file = Files:find({hash = hash_for_db})
	if file then
		local notechart = Notecharts:find({file_id = file.id, index = 1})
		if notechart then
			local difftable_notechart = Difftable_notecharts:find({
				difftable_id = difftable_id,
				notechart_id = notechart.id,
			})
			if not difftable_notechart then
				difftable_notechart = difftable_notechart_c.add_difftable_notechart(
					difftable_id,
					notechart,
					tonumber(bms_notechart.level)
				)
			elseif difftable_notechart.difficulty ~= difficulty then
				difftable_notechart.difficulty = difficulty
				difftable_notechart:update("difficulty")
			end
		end
		return
	end

	local ranked_cache = Ranked_caches:find({hash = hash_for_db, format = format_for_db})
	if not ranked_cache then
		ranked_cache = Ranked_caches:create({
			hash = hash_for_db,
			format = format_for_db,
			exists = true,
			ranked = true,
			created_at = created_at,
			expires_at = 0,
			user_id = self.session.user_id,
		})
	end
	local ranked_cache_difftable = Ranked_cache_difftables:find({
		ranked_cache_id = ranked_cache.id,
		difftable_id = difftable_id,
	})
	if not ranked_cache_difftable then
		ranked_cache_difftable = Ranked_cache_difftables:create({
			ranked_cache_id = ranked_cache.id,
			difftable_id = difftable_id,
			index = 1,
			difficulty = difficulty,
		})
	end
end

difftable_c.context.PUT = {"difftable", "request_session", "session_user", "user_roles"}
difftable_c.policies.PUT = {
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
difftable_c.validations.PUT = {
	{"rank_from_bms", type = "boolean"},
}
difftable_c.PUT = function(self)
	local params = self.params
	local difftable = self.context.difftable

	if params.rank_from_bms then
		local header, data = util.get_bms_difftable(difftable.link)
		difftable.name = header.name
		difftable.symbol = header.symbol
		difftable:update("name", "symbol")
		for _, notechart in ipairs(data) do
			difftable_c.add_bms_notechart(self, difftable.id, notechart)
		end
		return {status = 201, json = {
			header = header,
			count = #data
		}}
	end

	return {status = 204}
end

difftable_c.context.DELETE = {"difftable", "request_session", "session_user", "user_communities", set_community_id}
difftable_c.policies.DELETE = {
	{"authed", {community_role = "admin"}},
	{"authed", {community_role = "creator"}},
}
difftable_c.DELETE = function(self)
	local difftable = self.context.difftable

	local db = Difftables.db
	db.delete("difftable_notecharts", {difftable_id = difftable.id})
	db.delete("difftable_inputmodes", {difftable_id = difftable.id})
	db.delete("community_difftables", {difftable_id = difftable.id})
	db.delete("ranked_cache_difftables", {difftable_id = difftable.id})

	difftable:delete()

	return {status = 204}
end

return difftable_c
