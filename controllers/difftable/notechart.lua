local Difftable_notecharts = require("models.difftable_notecharts")
local Difftable_inputmodes = require("models.difftable_inputmodes")
local util = require("util")
local Controller = require("Controller")

local difftable_notechart_c = Controller:new()

difftable_notechart_c.path = "/difftables/:difftable_id[%d]/notecharts/:notechart_id[%d]"
difftable_notechart_c.methods = {"GET", "PUT", "PATCH", "DELETE"}

local set_community_id = function(self)
	self.params.community_id = self.context.difftable.owner_community_id
	return true
end

difftable_notechart_c.context.GET = {"difftable_notechart"}
difftable_notechart_c.policies.GET = {{"context_loaded"}}
difftable_notechart_c.validations.GET = util.add_belongs_to_validations(Difftable_notecharts.relations)
difftable_notechart_c.GET = function(self)
    local difftable_notechart = self.context.difftable_notechart

	util.get_relatives(difftable_notechart, self.params, true)

	return {json = {difftable_notechart = difftable_notechart}}
end

difftable_notechart_c.add_difftable_notechart = function(difftable_id, notechart, difficulty)
	local difftable_notechart = Difftable_notecharts:create({
		difftable_id = difftable_id,
		notechart_id = notechart.id,
		difficulty = difficulty or 0,
	})

	local new_difftable_inputmode = {
		difftable_id = difftable_id,
		inputmode = notechart.inputmode,
	}
	local difftable_inputmode = Difftable_inputmodes:find(new_difftable_inputmode)
	if not difftable_inputmode then
		new_difftable_inputmode.notecharts_count = 1
		Difftable_inputmodes:create(new_difftable_inputmode)
	else
		difftable_inputmode.notecharts_count = difftable_inputmode.notecharts_count + 1
		difftable_inputmode:update("notecharts_count")
	end

	local difftable = difftable_notechart:get_difftable()
	difftable.notecharts_count = difftable.notecharts_count + 1
	difftable:update("notecharts_count")

	return difftable_notechart
end

difftable_notechart_c.context.PUT = {
	"difftable",
	"notechart",
	{"difftable_notechart", missing = true},
	"request_session",
	"session_user",
	"user_communities",
	set_community_id,
}
difftable_notechart_c.policies.PUT = {
	{"authed", {community_role = "moderator"}},
	{"authed", {community_role = "admin"}},
	{"authed", {community_role = "creator"}},
}
difftable_notechart_c.validations.PUT = {
	{"difficulty", type = "number", optional = true},
}
difftable_notechart_c.PUT = function(self)
	local params = self.params
	local difftable_notechart = difftable_notechart_c.add_difftable_notechart(
		params.difftable_id,
		self.context.notechart,
		params.difficulty
	)

	return {json = {difftable_notechart = difftable_notechart}}
end

difftable_notechart_c.context.PATCH = {"difftable", "notechart", "difftable_notechart", "request_session", "session_user", "user_communities", set_community_id}
difftable_notechart_c.policies.PATCH = {
	{"authed", {community_role = "moderator"}},
	{"authed", {community_role = "admin"}},
	{"authed", {community_role = "creator"}},
}
difftable_notechart_c.validations.PATCH = {
	{"difficulty", type = "number", optional = true},
}
difftable_notechart_c.PATCH = function(self)
	local params = self.params

	local difftable_notechart = self.context.difftable_notechart
	difftable_notechart.difficulty = params.difficulty
	difftable_notechart:update("difficulty")

	return {json = {difftable_notechart = difftable_notechart}}
end

difftable_notechart_c.context.DELETE = {"difftable", "notechart", "difftable_notechart", "request_session", "session_user", "user_communities", set_community_id}
difftable_notechart_c.policies.DELETE = {
	{"authed", {community_role = "moderator"}},
	{"authed", {community_role = "admin"}},
	{"authed", {community_role = "creator"}},
}
difftable_notechart_c.DELETE = function(self)
	local params = self.params

    local difftable_notechart = self.context.difftable_notechart
    difftable_notechart:delete()

	local notechart = difftable_notechart:get_notechart()
	local difftable_inputmode = Difftable_inputmodes:find({
		difftable_id = params.difftable_id,
		inputmode = notechart.inputmode,
	})
	difftable_inputmode.notecharts_count = math.max(difftable_inputmode.notecharts_count - 1, 0)
	if difftable_inputmode.notecharts_count > 0 then
		difftable_inputmode:update("notecharts_count")
	else
		difftable_inputmode:delete()
	end

	local difftable = difftable_notechart:get_difftable()
	difftable.notecharts_count = math.max(difftable.notecharts_count - 1, 0)
	difftable:update("notecharts_count")

	return {status = 204}
end

return difftable_notechart_c
