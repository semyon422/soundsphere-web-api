local Difftables = require("models.difftables")
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
local lapis_util = require("lapis.util")
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

difftable_c.context.PATCH = {"difftable", "request_session", "session_user", "user_communities"}
difftable_c.policies.PATCH = {
	{"authed", {difftable_role = "admin"}, {not_params = "transfer_ownership"}},
	{"authed", {difftable_role = "creator"}},
}
difftable_c.validations.PATCH = {
	{"difftable", type = "table", param_type = "body", validations = {
		{"name", type = "string"},
		{"link", type = "string"},
		{"description", type = "string"},
		{"symbol", type = "string"},
		{"owner_community_id", type = "number"},
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

difftable_c.add_notechart = function(user_id, difftable_id, format, hash, index, difficulty)
	local created_at = os.time()
	local hash_for_db = Filehash:for_db(hash)
	local format_for_db = Formats:for_db(format)
	difficulty = tonumber(difficulty) or 0

	local file = Files:find({hash = hash_for_db})
	if file then
		local notechart = Notecharts:find({file_id = file.id, index = index})
		if notechart then
			difftable_notechart_c.set_difftable_notechart(
				difftable_id,
				notechart,
				difficulty
			)
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
			user_id = user_id,
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
			index = index,
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
	{"rank_from_bms", type = "boolean", optional = true},
	{"rank_from_file", type = "boolean", optional = true},
	{"file", is_file = true, param_type = "body", optional = true},
}
difftable_c.PUT = function(self)
	local params = self.params
	local difftable = self.context.difftable

	if params.rank_from_bms then
		local header, data = util.get_bms_difftable(difftable.link)
		if not header then
			return {status = 500, json = {message = data}}
		end
		difftable.name = header.name
		difftable.symbol = header.symbol
		difftable:update("name", "symbol")
		for _, notechart in ipairs(data) do
			difftable_c.add_notechart(
				self.session.user_id,
				difftable.id,
				"bms",
				notechart.md5,
				1,
				notechart.level
			)
		end
		return {status = 201, json = {
			header = header,
			count = #data
		}}
	elseif params.rank_from_file and params.file then
		local list = lapis_util.from_json(params.file.content)
		for _, notechart in ipairs(list) do
			difftable_c.add_notechart(
				self.session.user_id,
				difftable.id,
				"undefined",
				notechart.hash,
				notechart.index,
				notechart.difficulty
			)
		end
		return {status = 201, json = {
			count = #list
		}}
	end

	return {status = 204}
end

difftable_c.context.DELETE = {"difftable", "request_session", "session_user", "user_communities"}
difftable_c.policies.DELETE = {
	{"authed", {difftable_role = "admin"}, {delete_delay = "difftable"}},
	{"authed", {difftable_role = "creator"}, {delete_delay = "difftable"}},
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
