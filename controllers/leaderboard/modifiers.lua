local Leaderboard_modifiers = require("models.leaderboard_modifiers")
local array_update = require("util.array_update")
local Modifiers = require("enums.modifiers")
local Rules = require("enums.rules")
local Controller = require("Controller")

local leaderboard_modifiers_c = Controller:new()

leaderboard_modifiers_c.path = "/leaderboards/:leaderboard_id[%d]/modifiers"
leaderboard_modifiers_c.methods = {"GET", "PATCH"}

leaderboard_modifiers_c.update_modifiers = function(leaderboard_id, modifiers)
	if not modifiers then
		return
	end

	local ids = {}
	local modifiers_by_id = {}
	for i, modifier in ipairs(modifiers) do
		if not modifier.id then
			modifiers[i] = Leaderboard_modifiers:create({
				leaderboard_id = leaderboard_id,
				modifier = Modifiers:for_db(modifier.name),
				rule = Rules:for_db(modifier.rule),
				value = modifier.value,
			})
		else
			modifier.modifier = Modifiers:for_db(modifier.name)
			modifier.rule = Rules:for_db(modifier.rule)
			table.insert(ids, modifier.id)
			modifiers_by_id[modifier.id] = modifier
		end
	end

	local db = Leaderboard_modifiers.db
	local leaderboard_modifiers = #ids > 0 and Leaderboard_modifiers:select(
		"where " .. db.encode_clause({id = db.list(ids)})
	) or {}
	for _, modifier in ipairs(leaderboard_modifiers) do
		local modifier_by_id = modifiers_by_id[modifier.id]
		local fields = {}
		if modifier.modifier ~= modifier_by_id.modifier then
			modifier.modifier = modifier_by_id.modifier
			table.insert(fields, "modifier")
		end
		if modifier.rule ~= modifier_by_id.rule then
			modifier.rule = modifier_by_id.rule
			table.insert(fields, "rule")
		end
		if modifier.value ~= modifier_by_id.value then
			modifier.value = modifier_by_id.value
			table.insert(fields, "value")
		end
		if #fields > 0 then
			modifier:update(unpack(fields))
		end
	end

	leaderboard_modifiers = Leaderboard_modifiers:find_all({leaderboard_id}, "leaderboard_id")

	local new_ids, old_ids = array_update(
		modifiers,
		leaderboard_modifiers,
		function(lm) return lm.id end,
		function(lm) return lm.id end
	)
	if #old_ids > 0 then
		db.delete("leaderboard_modifiers", {id = db.list(old_ids)})
	end

	local export_modifiers = {}
	for _, modifier in ipairs(modifiers) do
		table.insert(export_modifiers, {
			id = modifier.id,
			name = Modifiers:to_name(modifier.modifier),
			rule = Rules:to_name(modifier.rule),
			value = modifier.value,
		})
	end
	return export_modifiers
end

leaderboard_modifiers_c.policies.GET = {{"permit"}}
leaderboard_modifiers_c.validations.GET = {
	require("validations.no_data"),
}
leaderboard_modifiers_c.GET = function(request)
	local params = request.params
	local leaderboard_modifiers = Leaderboard_modifiers:find_all({params.leaderboard_id}, "leaderboard_id")

	if params.no_data then
		return 200, {
			total = #leaderboard_modifiers,
			filtered = #leaderboard_modifiers,
		}
	end
	
	local modifiers = {}
	for _, leaderboard_modifier in ipairs(leaderboard_modifiers) do
		table.insert(modifiers, {
			id = leaderboard_modifier.id,
			name = Modifiers:to_name(leaderboard_modifier.modifier),
			rule = Rules:to_name(leaderboard_modifier.rule),
			value = leaderboard_modifier.value,
		})
	end

	return 200, {
		total = #modifiers,
		filtered = #modifiers,
		modifiers = modifiers
	}
end

leaderboard_modifiers_c.policies.PATCH = {{"permit"}}
leaderboard_modifiers_c.validations.PATCH = {
	{"modifiers", exists = true, body = true, optional = true, type = "table"},
}
leaderboard_modifiers_c.PATCH = function(request)
	local params = request.params

	local modifiers = leaderboard_modifiers_c.update_modifiers(params.leaderboard_id, params.modifiers)

	return 200, {
		total = #modifiers,
		filtered = #modifiers,
		modifiers = modifiers,
	}
end

return leaderboard_modifiers_c
