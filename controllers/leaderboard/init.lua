local Leaderboards = require("models.leaderboards")

local additions = {
	tables = require("controllers.leaderboard.tables"),
	communities = require("controllers.leaderboard.communities"),
	users = require("controllers.leaderboard.users"),
}

local leaderboard_c = {}

leaderboard_c.GET = function(params)
	local leaderboard = Leaderboards:find(params.leaderboard_id)

	local fields = {}
	for param, controller in pairs(additions) do
		local value = tonumber(params[param])
		if value then
			local param_count = param .. "_count"
			local _, response = controller.GET({
				leaderboard_id = params.leaderboard_id,
				per_page = value == 0 and value
			})
			leaderboard[param] = response[param]
			if leaderboard[param_count] ~= response.total then
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

leaderboard_c.PATCH = function(params)
	local leaderboard = Leaderboards:find(params.leaderboard_id)

	leaderboard.name = params.leaderboard.name
	leaderboard.description = params.leaderboard.description

	leaderboard:update("name", "description")

	return 200, {leaderboard = leaderboard}
end

return leaderboard_c
