local Leaderboards = require("models.leaderboards")
local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local Leaderboard_difftables = require("models.leaderboard_difftables")
local Inputmodes = require("enums.inputmodes")
local array_update = require("util.array_update")
local Controller = require("Controller")

local additions = {
	difftables = require("controllers.leaderboard.difftables"),
	communities = require("controllers.leaderboard.communities"),
	users = require("controllers.leaderboard.users"),
	inputmodes = require("controllers.leaderboard.inputmodes"),
	modifiers = require("controllers.leaderboard.modifiers"),
}

local leaderboard_c = Controller:new()

leaderboard_c.path = "/leaderboards/:leaderboard_id"
leaderboard_c.methods = {"GET", "PATCH", "DELETE"}
leaderboard_c.context = {"leaderboard"}
leaderboard_c.policies = {
	GET = require("policies.public"),
	PATCH = require("policies.public"),
	DELETE = require("policies.public"),
}

leaderboard_c.update_modifiers = function(leaderboard_id, modifiers)
	return additions.modifiers.update_modifiers(leaderboard_id, modifiers)
end

leaderboard_c.update_inputmodes = function(leaderboard_id, inputmodes)
	if not inputmodes then
		return
	end

	local leaderboard_inputmodes = Leaderboard_inputmodes:find_all({leaderboard_id}, "leaderboard_id")

	local new_inputmodes, old_inputmodes = array_update(
		inputmodes,
		leaderboard_inputmodes,
		function(i) return Inputmodes:for_db(i) end,
		function(li) return li.inputmode end
	)

	local db = Leaderboard_inputmodes.db
	if #old_inputmodes > 0 then
		db.delete("leaderboard_inputmodes", {inputmode = db.list(old_inputmodes)})
	end
	for _, inputmode in ipairs(new_inputmodes) do
		db.insert("leaderboard_inputmodes", {
			leaderboard_id = leaderboard_id,
			inputmode = inputmode,
		})
	end
end

leaderboard_c.update_difftables = function(leaderboard_id, difftables)
	if not difftables then
		return
	end

	local leaderboard_difftables = Leaderboard_difftables:find_all({leaderboard_id}, "leaderboard_id")

	local new_difftable_ids, old_difftable_ids = array_update(
		difftables,
		leaderboard_difftables,
		function(d) return d.id end,
		function(ld) return ld.difftable_id end
	)

	local db = Leaderboard_difftables.db
	if #old_difftable_ids > 0 then
		db.delete("leaderboard_difftables", {difftable_id = db.list(old_difftable_ids)})
	end
	for _, difftable_id in ipairs(new_difftable_ids) do
		db.insert("leaderboard_difftables", {
			leaderboard_id = leaderboard_id,
			difftable_id = difftable_id,
		})
	end
end

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
	leaderboard.banner = params.leaderboard.banner
	leaderboard:update("name", "description", "banner")

	leaderboard_c.update_inputmodes(leaderboard.id, params.leaderboard.inputmodes)
	leaderboard_c.update_difftables(leaderboard.id, params.leaderboard.difftables)
	leaderboard_c.update_modifiers(leaderboard.id, params.leaderboard.modifiers)

	return 200, {leaderboard = leaderboard}
end

return leaderboard_c
