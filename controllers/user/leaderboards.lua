local Leaderboard_users = require("models.leaderboard_users")
local Leaderboards = require("models.leaderboards")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local user_leaderboards_c = Controller:new()

user_leaderboards_c.path = "/users/:user_id[%d]/leaderboards"
user_leaderboards_c.methods = {"GET"}

user_leaderboards_c.context.GET = {"user", "user_communities"}
user_leaderboards_c.policies.GET = {{"permit"}}
user_leaderboards_c.validations.GET = {
	require("validations.no_data"),
}
util.add_belongs_to_validations(Leaderboard_users.relations, user_leaderboards_c.validations.GET)
util.add_has_many_validations(Leaderboards.relations, user_leaderboards_c.validations.GET)
user_leaderboards_c.GET = function(self)
	local params = self.params

    local leaderboard_users = Leaderboard_users:find_all({params.user_id}, "user_id")

	if params.no_data then
		return {json = {
			total = #leaderboard_users,
			filtered = #leaderboard_users,
		}}
	end

	preload(leaderboard_users, util.get_relatives_preload(Leaderboard_users, params))
	util.relatives_preload_field(leaderboard_users, "leaderboard", Leaderboards, params)
	util.recursive_to_name(leaderboard_users)

	local user = self.context.user
	if leaderboard_users[1] and leaderboard_users[1].leaderboard then
		for _, leaderboard_user in ipairs(leaderboard_users) do
			local community_user = user.communities:select({
				community_id = leaderboard_user.leaderboard.owner_community_id
			})[1]
			if community_user then
				leaderboard_user.role = community_user.role
			end
		end
	end

	return {json = {
		total = #leaderboard_users,
		filtered = #leaderboard_users,
		leaderboard_users = leaderboard_users,
	}}
end

return user_leaderboards_c
