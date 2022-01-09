local Leaderboard_users = require("models.leaderboard_users")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local leaderboard_users_c = Controller:new()

leaderboard_users_c.path = "/leaderboards/:leaderboard_id[%d]/users"
leaderboard_users_c.methods = {"GET"}

leaderboard_users_c.policies.GET = {{"permit"}}
leaderboard_users_c.validations.GET = {
	require("validations.no_data"),
}
leaderboard_users_c.validations.GET = util.add_belongs_to_validations(Leaderboard_users.relations)
leaderboard_users_c.GET = function(self)
	local params = self.params
    local leaderboard_users = Leaderboard_users:find_all({params.leaderboard_id}, "leaderboard_id")

	if params.no_data then
		return {json = {
			total = #leaderboard_users,
			filtered = #leaderboard_users,
		}}
	end

	preload(leaderboard_users, util.get_relatives_preload(Leaderboard_users, params))
	util.recursive_to_name(leaderboard_users)

	return {json = {
		total = #leaderboard_users,
		filtered = #leaderboard_users,
		leaderboard_users = leaderboard_users,
	}}
end

return leaderboard_users_c
