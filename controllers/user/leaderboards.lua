local Leaderboard_users = require("models.leaderboard_users")
local Leaderboards = require("models.leaderboards")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local user_leaderboards_c = Controller:new()

user_leaderboards_c.path = "/users/:user_id[%d]/leaderboards"
user_leaderboards_c.methods = {"GET"}

user_leaderboards_c.policies.GET = {{"permit"}}
user_leaderboards_c.validations.GET = {}
util.add_belongs_to_validations(Leaderboard_users.relations, user_leaderboards_c.validations.GET)
util.add_has_many_validations(Leaderboards.relations, user_leaderboards_c.validations.GET)
user_leaderboards_c.GET = function(self)
	local params = self.params

    local user_leaderboards = Leaderboard_users:find_all({params.user_id}, "user_id")

	if params.no_data then
		return {json = {
			total = #user_leaderboards,
			filtered = #user_leaderboards,
		}}
	end

	preload(user_leaderboards, util.get_relatives_preload(Leaderboard_users, params))
	util.relatives_preload_field(user_leaderboards, "leaderboard", Leaderboards, params)
	util.recursive_to_name(user_leaderboards)

	return {json = {
		total = #user_leaderboards,
		filtered = #user_leaderboards,
		user_leaderboards = user_leaderboards,
	}}
end

return user_leaderboards_c
