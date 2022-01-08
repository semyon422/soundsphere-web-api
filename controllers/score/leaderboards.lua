local Leaderboard_scores = require("models.leaderboard_scores")
local Community_leaderboards = require("models.community_leaderboards")
local Community_users = require("models.community_users")
local Modifiersets = require("models.modifiersets")
local Controller = require("Controller")
local util = require("util")
local preload = require("lapis.db.model").preload

local score_leaderboards_c = Controller:new()

score_leaderboards_c.path = "/scores/:score_id[%d]/leaderboards"
score_leaderboards_c.methods = {"GET"}

score_leaderboards_c.get_joined = function(self)
	local params = self.params

    local score_leaderboards = Leaderboard_scores:find_all({params.score_id}, "score_id")

	return score_leaderboards
end

score_leaderboards_c.get_available = function(self)
	local score = self.context.score
    local community_users = Community_users:find_all({score.user_id}, {
		key = "user_id",
		where = {accepted = true},
		fields = "community_id",
	})
	local community_ids = {}
	for _, community_user in ipairs(community_users) do
		table.insert(community_ids, community_user.community_id)
	end
	local community_leaderboards = Community_leaderboards:find_all(community_ids, "community_id")
	preload(community_leaderboards, {leaderboard = "leaderboard_requirements"})

	local available_community_leaderboard = {}
	for _, community_leaderboard in ipairs(community_leaderboards) do
		if score_leaderboards_c.match_requirements(score, community_leaderboard.leaderboard.leaderboard_requirements) then
			table.insert(available_community_leaderboard, community_leaderboard)
		end
	end

	return available_community_leaderboard
end

score_leaderboards_c.match_requirements = function(score, requirements)
	local modifierset = score:get_modifierset()
	local modifiers = Modifiersets:decode(modifierset.encoded)

	for _, requirement in ipairs(requirements) do
		requirement:to_name()
		if requirement.rule == "required" then
			if requirement.name == "modifier" then
				local matching = false
				for _, modifier in ipairs(modifiers) do
					if modifier.name == requirement.key then
						if score_leaderboards_c.match_requirement(modifier.value, requirement.value) then
							matching = true
						end
					end
				end
				if not matching then
					return false
				end
			elseif requirement.name == "score" then
				if not score_leaderboards_c.match_requirement(score[requirement.key], requirement.value) then
					return false
				end
			end
		end
	end
	for _, modifier in ipairs(modifiers) do
		local matching = false
		for _, requirement in ipairs(requirements) do
			if requirement.name == "modifier" and (requirement.rule == "allowed" or requirement.rule == "required") then
				if modifier.name == requirement.key and score_leaderboards_c.match_requirement(modifier.value, requirement.value) then
					matching = true
				end
			end
		end
		if not matching then
			return false
		end
	end
	return true
end

score_leaderboards_c.match_requirement = function(value, req)
	if not value then
		return false
	end
	if req:find(",") then
		for subreq in (req .. ","):gmatch("%s*([^,]-)%s*,") do
			if score_leaderboards_c.match_requirement(value, subreq) then
				return true
			end
		end
	elseif req:find("^.+to.+$") and tonumber(value) then
		local min, max = req:match("^(.+)to(.+)$")
		min, max, value = tonumber(min), tonumber(max), tonumber(value)
		return value >= min and value <= max
	end
	return tostring(req) == tostring(value)
end

score_leaderboards_c.context.GET = {"score"}
score_leaderboards_c.policies.GET = {{"context_loaded"}}
score_leaderboards_c.validations.GET = {
	require("validations.no_data"),
	{"available", type = "boolean", optional = true},
}
score_leaderboards_c.validations.GET = util.add_belongs_to_validations(Leaderboard_scores.relations)
score_leaderboards_c.GET = function(self)
	local params = self.params

	local score_leaderboards
	if params.available then
		score_leaderboards = score_leaderboards_c.get_available(self)
	else
		score_leaderboards = score_leaderboards_c.get_joined(self)
	end

	if params.no_data then
		return {json = {
			total = #score_leaderboards,
			filtered = #score_leaderboards,
		}}
	end

	preload(score_leaderboards, util.get_relatives_preload(Leaderboard_scores, params))
	util.recursive_to_name(score_leaderboards)

	return {json = {
		total = #score_leaderboards,
		filtered = #score_leaderboards,
		score_leaderboards = score_leaderboards,
	}}
end

return score_leaderboards_c
