local Leaderboard_scores = require("models.leaderboard_scores")
local Leaderboard_difftables = require("models.leaderboard_difftables")
local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local Leaderboard_users = require("models.leaderboard_users")
local Community_leaderboards = require("models.community_leaderboards")
local Difftable_notecharts = require("models.difftable_notecharts")
local Community_users = require("models.community_users")
local Leaderboards = require("models.leaderboards")
local Modifiersets = require("models.modifiersets")
local Inputmodes = require("enums.inputmodes")
local Controller = require("Controller")
local util = require("util")
local Joined_query = require("util.joined_query")
local erfunc = require("erfunc")
local preload = require("lapis.db.model").preload

local score_leaderboards_c = Controller:new()

score_leaderboards_c.path = "/scores/:score_id[%d]/leaderboards"
score_leaderboards_c.methods = {"GET", "PUT"}

score_leaderboards_c.get_available = function(score)
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
		if score_leaderboards_c.match_requirements(score, community_leaderboard.leaderboard) then
			table.insert(leaderboards, community_leaderboard.leaderboard)
		end
		community_leaderboard.leaderboard.leaderboard_requirements = nil
		community_leaderboard.leaderboard.leaderboard_inputmodes = nil
		community_leaderboard.leaderboard.leaderboard_difftables = nil
	end

	return leaderboards
end

score_leaderboards_c.match_requirements = function(score, leaderboard)
	local leaderboard_inputmodes = leaderboard:get_leaderboard_inputmodes()
	if #leaderboard_inputmodes > 0 then
		local matching = false
		for _, leaderboard_inputmode in ipairs(leaderboard_inputmodes) do
			if score.inputmode == leaderboard_inputmode.inputmode then
				matching = true
			end
		end
		if not matching then
			return false
		end
	end

	local leaderboard_difftables = leaderboard:get_leaderboard_difftables()
	if #leaderboard_difftables > 0 then
		local difftable_notecharts = score_leaderboards_c.get_difftable_notecharts(score, leaderboard)
		if #difftable_notecharts == 0 then
			return false
		end
	end

	local modifierset = score:get_modifierset()
	local modifiers = Modifiersets:decode(modifierset.encoded)

	local requirements = leaderboard.leaderboard_requirements
	if #requirements == 0 then
		return true
	end

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
score_leaderboards_c.policies.GET = {{"permit"}}
score_leaderboards_c.validations.GET = {
	require("validations.no_data"),
	{"available", type = "boolean", optional = true},
}
util.add_belongs_to_validations(Leaderboard_scores.relations, score_leaderboards_c.validations.GET)
score_leaderboards_c.GET = function(self)
	local params = self.params

	local leaderboard_scores, leaderboards
	if params.available then
		leaderboards = score_leaderboards_c.get_available(self.context.score)
	else
		leaderboard_scores = self.context.score:get_leaderboard_scores()
		self.context.score.leaderboard_scores = nil
	end
	local objects = leaderboard_scores or leaderboards

	if params.no_data then
		return {json = {
			total = #objects,
			filtered = #objects,
		}}
	end

	if leaderboard_scores then
		preload(leaderboard_scores, util.get_relatives_preload(Leaderboard_scores, params))
	elseif leaderboards then
		preload(leaderboards, util.get_relatives_preload(Leaderboards, params))
	end
	util.recursive_to_name(objects)

	return {json = {
		total = #objects,
		filtered = #objects,
		leaderboard_scores = leaderboard_scores,
		leaderboards = leaderboards,
	}}
end

score_leaderboards_c.get_difftable_notecharts = function(score, leaderboard)
	local leaderboard_difftables = leaderboard:get_leaderboard_difftables()
	if #leaderboard_difftables == 0 then
		return {}
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
		return {}
	end
	table.sort(difftable_notecharts, function(a, b)
		return a.difftable_id > b.difftable_id
	end)
	return difftable_notecharts
end

score_leaderboards_c.get_difficulty = function(score, leaderboard)
	local difficulty_calculator = leaderboard.difficulty_calculator
	local difficulty_calculator_config = leaderboard.difficulty_calculator_config
	if difficulty_calculator == "enps" then
		return score.difficulty
	elseif difficulty_calculator == "difftable" then
		local difftable_notecharts = score_leaderboards_c.get_difftable_notecharts(score, leaderboard)
		if #difftable_notecharts == 0 then
			return 0
		end
		return difftable_notecharts[1].difficulty * score.modifierset.timerate
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

	local combiner = leaderboard.scores_combiner

	local total_rating = 0
	for i = 1, count do
		local rating = 0
		local leaderboard_score = leaderboard_scores[i]
		if leaderboard_score then
			rating = leaderboard_score.rating
		end
		if combiner == "average" or combiner == "additive" then
			total_rating = total_rating + rating
		elseif combiner == "logarithmic" then
			total_rating = total_rating + rating * 0.95 ^ (i - 1)
		end
	end
	if combiner == "average" then
		total_rating = total_rating / count
	end

	local total_count = tonumber(Leaderboard_scores:count(clause))
	return total_rating, total_count
end

score_leaderboards_c.get_community_total_rating = function(leaderboard_users, leaderboard)
	local count = leaderboard.communities_combiner_count
	local combiner = leaderboard.communities_combiner

	local total_rating = 0
	for i = 1, count do
		local rating = 0
		local leaderboard_user = leaderboard_users[i]
		if leaderboard_user then
			rating = leaderboard_user.total_rating
		end
		if combiner == "average" or combiner == "additive" then
			total_rating = total_rating + rating
		elseif combiner == "logarithmic" then
			total_rating = total_rating + rating * 0.95 ^ (i - 1)
		end
	end
	if combiner == "average" then
		total_rating = total_rating / count
	end

	return total_rating
end

score_leaderboards_c.update_top_user = function(leaderboard)
	local top_leaderboard_user = Leaderboard_users:select(
		"where leaderboard_id = ? order by total_rating desc limit 1", leaderboard.id
	)[1]
	leaderboard.top_user_id = top_leaderboard_user.user_id
	leaderboard:update("top_user_id")
end

score_leaderboards_c.update_community_leaderboards = function(user_id, leaderboard)
	local community_users = Community_users:find_all({user_id}, "user_id")
	local community_ids_map = {}
	local community_ids = {}
	for _, community_user in ipairs(community_users) do
		community_ids_map[community_user.community_id] = true
	end

	local community_leaderboards_map = {}
	local community_leaderboards = leaderboard:get_community_leaderboards()
	for _, community_leaderboard in ipairs(community_leaderboards) do
		local community_id = community_leaderboard.community_id
		if community_ids_map[community_id] then
			table.insert(community_ids, community_id)
			community_leaderboards_map[community_id] = community_leaderboard
		end
	end

	--[[
		select total_rating from leaderboard_users lu
		inner join community_users cu on lu.user_id = cu.user_id
		where cu.community_id = 1 and lu.leaderboard_id = 1 order by total_rating desc limit 100
	]]
	local count = leaderboard.communities_combiner_count
	for _, community_id in ipairs(community_ids) do
		local leaderboard_users = Leaderboard_users:select(
			"lu " ..
			"inner join community_users cu on lu.user_id = cu.user_id " ..
			"where cu.community_id = ? and lu.leaderboard_id = ? " ..
			"order by total_rating desc limit ?",
			community_id, leaderboard.id, count,
			{fields = "total_rating"}
		)
		local total_rating = score_leaderboards_c.get_community_total_rating(leaderboard_users, leaderboard)
		local rank = util.db_count(
			Community_leaderboards,
			"leaderboard_id = ? and accepted = ? and community_id != ? and total_rating > ? order by total_rating desc",
			leaderboard.id, true, community_id, total_rating
		) + 1
		local community_leaderboard = community_leaderboards_map[community_id]
		community_leaderboard.total_rating = total_rating
		community_leaderboard.rank = rank
		community_leaderboard:update("total_rating", "rank")
	end
end

score_leaderboards_c.update_user_leaderboard = function(user_id, leaderboard)
	local total_rating, total_count = score_leaderboards_c.get_total_rating(user_id, leaderboard)
	local new_leaderboard_user = {
		leaderboard_id = leaderboard.id,
		user_id = user_id,
	}

	local jq = Joined_query:new(Leaderboard_scores.db)
	jq:select("ls")
	jq:select("inner join scores s on ls.score_id = s.id")
	jq:where("ls.leaderboard_id = ?", leaderboard.id)
	jq:where("ls.user_id = ?", user_id)
	jq:orders("s.created_at desc limit 1")
	jq:fields("s.created_at")

	local latest_score_submitted_at = os.time()
	local latest_leaderboard_score = Leaderboard_scores:select(jq:concat())[1]
	if latest_leaderboard_score then
		latest_score_submitted_at = latest_leaderboard_score.created_at
	end

	local rank = util.db_count(
		Leaderboard_users,
		"leaderboard_id = ? and active = ? and user_id != ? and total_rating > ? order by total_rating desc",
		leaderboard.id, true, user_id, total_rating
	) + 1

	local leaderboard_user = Leaderboard_users:find(new_leaderboard_user)
	if not leaderboard_user then
		new_leaderboard_user.active = true
		new_leaderboard_user.scores_count = total_count
		new_leaderboard_user.total_rating = total_rating
		new_leaderboard_user.latest_score_submitted_at = latest_score_submitted_at
		new_leaderboard_user.rank = rank
		Leaderboard_users:create(new_leaderboard_user)
		score_leaderboards_c.update_top_user(leaderboard)
		score_leaderboards_c.update_community_leaderboards(user_id, leaderboard)
		return
	end
	leaderboard_user.scores_count = total_count
	leaderboard_user.total_rating = total_rating
	leaderboard_user.rank = rank
	leaderboard_user.latest_score_submitted_at = latest_score_submitted_at
	leaderboard_user:update("scores_count", "total_rating", "rank", "latest_score_submitted_at")

	score_leaderboards_c.update_top_user(leaderboard)
	score_leaderboards_c.update_community_leaderboards(user_id, leaderboard)
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

score_leaderboards_c.update_leaderboards = function(score)
	local leaderboards = score_leaderboards_c.get_available(score)
	util.recursive_to_name(leaderboards)


	local leaderboard_scores = Leaderboard_scores:find_all({score.id}, "score_id")
	for _, leaderboard_score in ipairs(leaderboard_scores) do
		leaderboard_score:delete()
	end

	score:get_modifierset()
	local count = 0
	for _, leaderboard in ipairs(leaderboards) do
		if score_leaderboards_c.insert_score(score, leaderboard) then
			count = count + 1
		end
	end

	score.is_ranked = true
	score:update("is_ranked")

	return count
end

score_leaderboards_c.context.PUT = {"score", "request_session", "session_user", "user_roles"}
score_leaderboards_c.policies.PUT = {
	{"authed", {not_params = "force"}, "score_owner"},
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
score_leaderboards_c.validations.PUT = {
	{"force", type = "boolean", optional = true},
}
score_leaderboards_c.PUT = function(self)
	local params = self.params
	local score = self.context.score

	if score.is_ranked and not params.force then
		return {status = 204}
	end

	if not score.is_valid then
		return {status = 400, json = {message = "Invalid score"}}
	end

	local count = score_leaderboards_c.update_leaderboards(score)

	return {json = {count = count}}
end

return score_leaderboards_c
