local Leaderboard_modifiers = require("models.leaderboard_modifiers")
local array_update = require("util.array_update")
local Modifiers = require("enums.modifiers")

local leaderboard_modifiers_c = {}

leaderboard_modifiers_c.path = "/leaderboards/:leaderboard_id/modifiers"
leaderboard_modifiers_c.methods = {"GET", "PATCH"}
leaderboard_modifiers_c.context = {}
leaderboard_modifiers_c.policies = {
	GET = require("policies.public"),
	PATCH = require("policies.public"),
}

leaderboard_modifiers_c.update_modifiers = function(leaderboard_id, modifiers)
	if not modifiers then
		return
	end

	for i, modifier in ipairs(modifiers) do
		if not modifier.id then
			modifiers[i] = Leaderboard_modifiers:create({
				leaderboard_id = leaderboard_id,
				modifier = Modifiers:for_db(modifier.name),
				required = modifier.required,
				min = modifier.min,
				max = modifier.max,
			})
		end
	end

	local leaderboard_modifiers = Leaderboard_modifiers:find_all({leaderboard_id}, "leaderboard_id")

	local new_ids, old_ids = array_update(
		modifiers,
		leaderboard_modifiers,
		function(lm) return lm.id end,
		function(lm) return lm.id end
	)

	local db = Leaderboard_modifiers.db
	if #old_ids > 0 then
		db.delete("leaderboard_modifiers", {id = db.list(old_ids)})
	end
end

leaderboard_modifiers_c.GET = function(request)
	local params = request.params
	local leaderboard_modifiers = Leaderboard_modifiers:find_all({params.leaderboard_id}, "leaderboard_id")
	
	local modifiers = {}
	for _, leaderboard_modifier in ipairs(leaderboard_modifiers) do
		local modifier = {
			id = leaderboard_modifier.id,
			name = Modifiers:to_name(leaderboard_modifier.modifier),
			required = leaderboard_modifier.required,
		}
		modifier.min = leaderboard_modifier.min
		modifier.max = leaderboard_modifier.max
		table.insert(modifiers, modifier)
	end

	return 200, {
		total = #modifiers,
		filtered = #modifiers,
		modifiers = modifiers
	}
end

leaderboard_modifiers_c.PATCH = function(request)
	local params = request.params

	leaderboard_modifiers_c.update_modifiers(params.leaderboard_id, params.modifiers)

	return 200, {}
end

return leaderboard_modifiers_c
