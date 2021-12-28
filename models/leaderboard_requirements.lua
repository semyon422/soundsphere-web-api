local Model = require("lapis.db.model").Model
local Requirements = require("enums.requirements")
local Rules = require("enums.rules")

local Leaderboard_requirements = Model:extend(
	"leaderboard_requirements",
	{
		relations = {
			{"leaderboard", belongs_to = "leaderboards", key = "leaderboard_id"},
		},
		url_params = function(self, req, ...)
			return "leaderboard.requirement", {
				leaderboard_id = req.params.leaderboard_id,
				requirement_id = self.id
			}, ...
		end,
	}
)

local function to_name(self)
	self.name = Requirements:to_name(self.requirement)
	self.rule = Rules:to_name(self.rule)
	self.key = Requirements:get_key_enum(self.requirement):to_name(self.key)
	self.requirement = nil
	return self
end

local function for_db(self)
	self.requirement = Requirements:for_db(self.name)
	self.rule = Rules:for_db(self.rule)
	self.key = Requirements:get_key_enum(self.name):for_db(self.key)
	self.name = nil
	return self
end

function Leaderboard_requirements.to_name(self, row) return to_name(row) end
function Leaderboard_requirements.for_db(self, row) return for_db(row) end

local _load = Leaderboard_requirements.load
function Leaderboard_requirements:load(row)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

return Leaderboard_requirements
