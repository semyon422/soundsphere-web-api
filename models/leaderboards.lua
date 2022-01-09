local Model = require("lapis.db.model").Model
local Difficulty_calculators = require("enums.difficulty_calculators")
local Rating_calculators = require("enums.rating_calculators")
local Combiners = require("enums.combiners")

local Leaderboards = Model:extend(
	"leaderboards",
	{
		relations = {
			{"leaderboard_difftables", has_many = "leaderboard_difftables", key = "leaderboard_id"},
			{"leaderboard_inputmodes", has_many = "leaderboard_inputmodes", key = "leaderboard_id"},
			{"leaderboard_requirements", has_many = "leaderboard_requirements", key = "leaderboard_id"},
			{"community_leaderboards", has_many = "community_leaderboards", key = "leaderboard_id"},
			{"top_user", belongs_to = "users", key = "top_user_id"},
		},
		url_params = function(self, req, ...)
			return "leaderboard", {leaderboard_id = self.id}, ...
		end,
	}
)

local function to_name(self)
	self.difficulty_calculator = Difficulty_calculators:to_name(self.difficulty_calculator)
	self.rating_calculator = Rating_calculators:to_name(self.rating_calculator)
	self.scores_combiner = Combiners:to_name(self.scores_combiner)
	self.communities_combiner = Combiners:to_name(self.communities_combiner)
	return self
end

local function for_db(self)
	self.difficulty_calculator = Difficulty_calculators:for_db(self.difficulty_calculator)
	self.rating_calculator = Rating_calculators:for_db(self.rating_calculator)
	self.scores_combiner = Combiners:for_db(self.scores_combiner)
	self.communities_combiner = Combiners:for_db(self.communities_combiner)
	return self
end

function Leaderboards.to_name(self, row) return to_name(row) end
function Leaderboards.for_db(self, row) return for_db(row) end

local _load = Leaderboards.load
function Leaderboards:load(row)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

return Leaderboards
