local Leaderboards = require("models.leaderboards")

local additions = {
	tables = require("controllers.leaderboard.tables"),
	communities = require("controllers.leaderboard.communities"),
	users = require("controllers.leaderboard.users"),
	inputmodes = require("controllers.leaderboard.inputmodes"),
}

local leaderboard_c = {}

leaderboard_c.path = "/leaderboards/:leaderboard_id"
leaderboard_c.methods = {"GET", "PATCH", "DELETE"}
leaderboard_c.context = {"leaderboard"}
leaderboard_c.policies = {
	GET = require("policies.public"),
	PATCH = require("policies.public"),
	DELETE = require("policies.public"),
}

leaderboard_c.GET = function(request)
	local params = request.params
	local leaderboard = Leaderboards:find(params.leaderboard_id)

	local fields = {}
	for param, controller in pairs(additions) do
		local value = tonumber(params[param])
		if value then
			local param_count = param .. "_count"
			params.per_page = value == 0 and value
			local _, response = controller.GET(request)
			leaderboard[param] = response[param]
			if leaderboard[param_count] and leaderboard[param_count] ~= response.total then
				leaderboard[param_count] = response.total
				table.insert(fields, param_count)
			end
		end
	end
	if #fields > 0 then
		leaderboard:update(unpack(fields))
	end

	return 200, {leaderboard = leaderboard}
end

leaderboard_c.PATCH = function(request)
	local params = request.params
	local leaderboard = Leaderboards:find(params.leaderboard_id)

	leaderboard.name = params.leaderboard.name
	leaderboard.description = params.leaderboard.description

	leaderboard:update("name", "description")

	return 200, {leaderboard = leaderboard}
end

return leaderboard_c
