local Leaderboards = require("models.leaderboards")
local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local Leaderboard_difftables = require("models.leaderboard_difftables")
local Inputmodes = require("enums.inputmodes")
local array_update = require("util.array_update")
local Controller = require("Controller")
local add_belongs_to_validations = require("util.add_belongs_to_validations")
local get_relatives = require("util.get_relatives")

local additions = {
	difftables = require("controllers.leaderboard.difftables"),
	communities = require("controllers.leaderboard.communities"),
	users = require("controllers.leaderboard.users"),
	inputmodes = require("controllers.leaderboard.inputmodes"),
	requirements = require("controllers.leaderboard.requirements"),
}

local leaderboard_c = Controller:new()

leaderboard_c.path = "/leaderboards/:leaderboard_id[%d]"
leaderboard_c.methods = {"GET", "PATCH", "DELETE"}

leaderboard_c.update_requirements = function(leaderboard_id, requirements)
	return additions.requirements.update_requirements(leaderboard_id, requirements)
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

leaderboard_c.context.GET = {"leaderboard"}
leaderboard_c.policies.GET = {{"context_loaded"}}
leaderboard_c.validations.GET = {
	{"difftables", type = "boolean", optional = true},
	{"communities", type = "boolean", optional = true},
	{"users", type = "boolean", optional = true},
	{"inputmodes", type = "boolean", optional = true},
	{"requirements", type = "boolean", optional = true},
}
add_belongs_to_validations(Leaderboards.relations, leaderboard_c.validations.GET)
leaderboard_c.GET = function(request)
	local params = request.params
	local leaderboard = request.context.leaderboard

	local fields = {}
	for param, controller in pairs(additions) do
		local value = params[param]
		if value ~= nil then
			local param_count = param .. "_count"
			params.no_data = value == false
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

	get_relatives(leaderboard, request.params, true)

	return 200, {leaderboard = leaderboard}
end

leaderboard_c.context.PATCH = {"leaderboard", "request_session"}
leaderboard_c.policies.PATCH = {{"authenticated", "context_loaded"}}
leaderboard_c.validations.PATCH = {
	{"leaderboard", type = "table", body = true, validations = {
		{"name", type = "string"},
		{"description", type = "string"},
		{"banner", type = "string"},
	}},
}
leaderboard_c.PATCH = function(request)
	local params = request.params
	local leaderboard = request.context.leaderboard

	leaderboard.name = params.leaderboard.name
	leaderboard.description = params.leaderboard.description
	leaderboard.banner = params.leaderboard.banner
	leaderboard:update("name", "description", "banner")

	leaderboard_c.update_inputmodes(leaderboard.id, params.leaderboard.inputmodes)
	leaderboard_c.update_difftables(leaderboard.id, params.leaderboard.difftables)
	leaderboard_c.update_requirements(leaderboard.id, params.leaderboard.requirements)

	return 200, {leaderboard = leaderboard}
end

return leaderboard_c
