local Leaderboard_scores = require("models.leaderboard_scores")
local Leaderboard_difftables = require("models.leaderboard_difftables")
local Leaderboard_users = require("models.leaderboard_users")
local Community_leaderboards = require("models.community_leaderboards")
local Difftable_notecharts = require("models.difftable_notecharts")
local Community_users = require("models.community_users")
local Leaderboards = require("models.leaderboards")
local Modifiersets = require("models.modifiersets")
local Controller = require("Controller")
local util = require("util")
local erfunc = require("erfunc")
local preload = require("lapis.db.model").preload

local score_leaderboards_c = Controller:new()

score_leaderboards_c.path = "/scores/:score_id[%d]/leaderboards"
score_leaderboards_c.methods = {"GET", "PUT"}

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

	local leaderboards = {}
	for _, community_leaderboard in ipairs(community_leaderboards) do
		if score_leaderboards_c.match_requirements(score, community_leaderboard.leaderboard.leaderboard_requirements) then
			table.insert(leaderboards, community_leaderboard.leaderboard)
		end
		community_leaderboard.leaderboard.leaderboard_requirements = nil
	end

	return leaderboards
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
util.add_belongs_to_validations(Leaderboard_scores.relations, score_leaderboards_c.validations.GET)
score_leaderboards_c.GET = function(self)
	local params = self.params

	local score_leaderboards, leaderboards
	if params.available then
		leaderboards = score_leaderboards_c.get_available(self)
	else
		score_leaderboards = score_leaderboards_c.get_joined(self)
	end
	local objects = score_leaderboards or leaderboards

	if params.no_data then
		return {json = {
			total = #objects,
			filtered = #objects,
		}}
	end

	if score_leaderboards then
		preload(score_leaderboards, util.get_relatives_preload(Leaderboard_scores, params))
	elseif leaderboards then
		preload(leaderboards, util.get_relatives_preload(Leaderboards, params))
	end
	util.recursive_to_name(objects)

	return {json = {
		total = #objects,
		filtered = #objects,
		score_leaderboards = score_leaderboards,
		leaderboards = leaderboards,
	}}
end

score_leaderboards_c.get_difficulty = function(score, leaderboard)
	local difficulty_calculator = leaderboard.difficulty_calculator
	local difficulty_calculator_config = leaderboard.difficulty_calculator_config
	if difficulty_calculator == "enps" then
		return score.difficulty
	elseif difficulty_calculator == "difftable" then
		local leaderboard_difftables = Leaderboard_difftables:find_all({leaderboard.id}, "leaderboard_id")
		if #leaderboard_difftables == 0 then
			return 0
		end
		local difftable_ids = {}
		for _, leaderboard_difftable in ipairs(leaderboard_difftables) do
			table.insert(difftable_ids, leaderboard_difftable.difftable_id)
		end
		local difftable_notecharts = Difftable_notecharts:find_all(difftable_ids, {
			key = "difftable_id",
			where = {notechart_id = score.notechart_id},
		})
		if #difftable_notecharts == 0 then
			return 0
		end
		table.sort(difftable_notecharts, function(a, b)
			return a.difftable_id > b.difftable_id
		end)
		return difftable_notecharts[1].difficulty * score.timerate
	end
	return 0
end

score_leaderboards_c.get_rating = function(score, leaderboard)
	local rating_calculator = leaderboard.rating_calculator
	local rating_calculator_config = leaderboard.rating_calculator_config
	local difficulty = score_leaderboards_c.get_difficulty(score, leaderboard)
	if rating_calculator == "acc_inv" then
		return difficulty / score.accuracy
	elseif rating_calculator == "acc_inv_erf" then
		return difficulty * erfunc.erf(0.032 / (score.accuracy * math.sqrt(2)))
	end
	return 0
end

score_leaderboards_c.get_total_rating = function(user_id, leaderboard)
	local count = leaderboard.scores_combiner_count
	local db = Leaderboard_scores.db

	local clause = db.encode_clause({
		user_id = user_id,
		leaderboard_id = leaderboard.id,
	})
	local leaderboard_scores = Leaderboard_scores:select(
		"where " .. clause .. " order by rating desc limit " .. count
	)

	local scores_combiner = leaderboard.scores_combiner

	local total_rating = 0
	for i = 1, count do
		local rating = 0
		local leaderboard_score = leaderboard_scores[i]
		if leaderboard_score then
			rating = leaderboard_score.rating
		end
		if scores_combiner == "average" or scores_combiner == "additive" then
			total_rating = total_rating + rating
		elseif scores_combiner == "logarithmic" then
			total_rating = total_rating + rating * 0.95 ^ (i - 1)
		end
	end
	if scores_combiner == "average" then
		total_rating = total_rating / count
	end

	local total_count = tonumber(Leaderboard_scores:count(clause))
	return total_rating, total_count
end

score_leaderboards_c.update_top_user = function(leaderboard)
	local top_leaderboard_user = Leaderboard_users:find({leaderboard_id = leaderboard.id}, "order by rating desc")
	leaderboard.top_user_id = top_leaderboard_user.user_id
	leaderboard:update("top_user_id")
end

score_leaderboards_c.update_user_leaderboard = function(user_id, leaderboard)
	local total_rating, total_count = score_leaderboards_c.get_total_rating(user_id, leaderboard)
	local new_leaderboard_user = {
		leaderboard_id = leaderboard.id,
		user_id = user_id,
	}
	local leaderboard_user = Leaderboard_users:find(new_leaderboard_user)
	if not leaderboard_user then
		new_leaderboard_user.active = true
		new_leaderboard_user.scores_count = total_count
		new_leaderboard_user.total_rating = total_rating
		Leaderboard_users:create(new_leaderboard_user)
		score_leaderboards_c.update_top_user(leaderboard)
		return
	end
	leaderboard_user.scores_count = total_count
	leaderboard_user.total_rating = total_rating
	leaderboard_user:update("scores_count", "total_rating")

	score_leaderboards_c.update_top_user(leaderboard)
end

score_leaderboards_c.insert_score = function(score, leaderboard)
	local new_leaderboard_score = {
		leaderboard_id = leaderboard.id,
		notechart_id = score.notechart_id,
		user_id = score.user_id,
	}
	local leaderboard_score = Leaderboard_scores:find(new_leaderboard_score)
	if not leaderboard_score then
		new_leaderboard_score.score_id = score.id
		new_leaderboard_score.rating = score_leaderboards_c.get_rating(score, leaderboard)
		Leaderboard_scores:create(new_leaderboard_score)
		score_leaderboards_c.update_user_leaderboard(score.user_id, leaderboard)
		return true
	end
	local rating = score_leaderboards_c.get_rating(score, leaderboard)
	if rating <= leaderboard_score.rating then
		return
	end
	leaderboard_score.score_id = score.id
	leaderboard_score.rating = rating
	leaderboard_score:update("score_id", "rating")
	score_leaderboards_c.update_user_leaderboard(score.user_id, leaderboard)
	return true
end

score_leaderboards_c.context.PUT = {"score"}
score_leaderboards_c.policies.PUT = {{"context_loaded"}}
score_leaderboards_c.PUT = function(self)
	local leaderboards = score_leaderboards_c.get_available(self)
	util.recursive_to_name(leaderboards)

	local count = 0
	for _, leaderboard in ipairs(leaderboards) do
		if score_leaderboards_c.insert_score(self.context.score, leaderboard) then
			count = count + 1
		end
	end

	return {json = {count = count}}
end

return score_leaderboards_c
