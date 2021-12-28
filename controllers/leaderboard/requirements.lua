local Leaderboard_requirements = require("models.leaderboard_requirements")
local array_update = require("util.array_update")
local Rules = require("enums.rules")
local Requirements = require("enums.requirements")
local Controller = require("Controller")

local leaderboard_requirements_c = Controller:new()

leaderboard_requirements_c.path = "/leaderboards/:leaderboard_id[%d]/requirements"
leaderboard_requirements_c.methods = {"GET", "PATCH", "POST"}

leaderboard_requirements_c.update_requirements = function(leaderboard_id, requirements)
	if not requirements then
		return
	end

	local ids = {}
	local requirements_by_id = {}
	for i, requirement in ipairs(requirements) do
		requirement.leaderboard_id = leaderboard_id
		Leaderboard_requirements:for_db(requirement)
		if not requirement.id then
			requirements[i] = Leaderboard_requirements:create(requirement)
		else
			table.insert(ids, requirement.id)
			requirements_by_id[requirement.id] = requirement
		end
	end

	local db = Leaderboard_requirements.db
	local leaderboard_requirements = #ids > 0 and Leaderboard_requirements:select(
		"where " .. db.encode_clause({
			id = db.list(ids),
			leaderboard_id = leaderboard_id,
		})
	) or {}
	for _, requirement in ipairs(leaderboard_requirements) do
		local requirement_by_id = requirements_by_id[requirement.id]
		local fields = {}
		if requirement.requirement ~= requirement_by_id.requirement then
			requirement.requirement = requirement_by_id.requirement
			table.insert(fields, "requirement")
		end
		if requirement.rule ~= requirement_by_id.rule then
			requirement.rule = requirement_by_id.rule
			table.insert(fields, "rule")
		end
		if requirement.key ~= requirement_by_id.key then
			requirement.key = requirement_by_id.key
			table.insert(fields, "key")
		end
		if requirement.value ~= requirement_by_id.value then
			requirement.value = requirement_by_id.value
			table.insert(fields, "value")
		end
		if #fields > 0 then
			requirement:update(unpack(fields))
		end
	end

	leaderboard_requirements = Leaderboard_requirements:find_all({leaderboard_id}, "leaderboard_id")

	local new_ids, old_ids = array_update(
		requirements,
		leaderboard_requirements,
		function(lm) return lm.id end,
		function(lm) return lm.id end
	)
	if #old_ids > 0 then
		db.delete("leaderboard_requirements", {id = db.list(old_ids)})
	end

	for _, requirement in ipairs(requirements) do
		Leaderboard_requirements:to_name(requirement)
	end
	return requirements
end

leaderboard_requirements_c.policies.GET = {{"permit"}}
leaderboard_requirements_c.validations.GET = {
	require("validations.no_data"),
}
leaderboard_requirements_c.GET = function(request)
	local params = request.params
	local leaderboard_requirements = Leaderboard_requirements:find_all({params.leaderboard_id}, "leaderboard_id")

	if params.no_data then
		return 200, {
			total = #leaderboard_requirements,
			filtered = #leaderboard_requirements,
		}
	end
	
	for _, requirement in ipairs(leaderboard_requirements) do
		Leaderboard_requirements:to_name(requirement)
	end

	return 200, {
		total = #leaderboard_requirements,
		filtered = #leaderboard_requirements,
		requirements = leaderboard_requirements
	}
end

leaderboard_requirements_c.context.PATCH = {"request_session"}
leaderboard_requirements_c.policies.PATCH = {{"authenticated"}}
leaderboard_requirements_c.validations.PATCH = {
	{"requirements", exists = true, param_type = "body", optional = true, type = "table"},
}
leaderboard_requirements_c.PATCH = function(request)
	local params = request.params

	local requirements = leaderboard_requirements_c.update_requirements(params.leaderboard_id, params.requirements)

	return 200, {
		total = #requirements,
		filtered = #requirements,
		requirements = requirements,
	}
end

leaderboard_requirements_c.context.POST = {"request_session"}
leaderboard_requirements_c.policies.POST = {{"authenticated"}}
leaderboard_requirements_c.validations.POST = {
	{"requirement", exists = true, type = "table", param_type = "body", validations = {
		{"name", exists = true, type = "string", one_of = Requirements.list},
		{"rule", exists = true, type = "string", one_of = Rules.list},
		{"key", exists = true, type = "string"},
		{"value", exists = true, type = "string"},
	}}
}
leaderboard_requirements_c.POST = function(request)
	local params = request.params

	local params_requirement = params.requirement

	requirement.leaderboard_id = params.leaderboard_id
	requirement.id = nil
	Leaderboard_requirements:for_db(requirement)
	local requirement = Leaderboard_requirements:create(requirement)

	return 200, {requirement = requirement:to_name()}
end

return leaderboard_requirements_c
