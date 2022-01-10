local Model = require("lapis.db.model").Model
local toboolean = require("util.toboolean")
local Inputmodes = require("enums.inputmodes")

local Scores = Model:extend(
	"scores",
	{
		relations = {
			{"leaderboard_scores", has_many = "leaderboard_scores", key = "score_id"},
			{"user", belongs_to = "users", key = "user_id"},
			{"notechart", belongs_to = "notecharts", key = "notechart_id"},
			{"modifierset", belongs_to = "modifiersets", key = "modifierset_id"},
			{"file", belongs_to = "files", key = "file_id"},
		},
		url_params = function(self, req, ...)
			return "score", {score_id = self.id}, ...
		end,
	}
)

local function to_name(self)
	self.inputmode = Inputmodes:to_name(self.inputmode)
	return self
end

local function for_db(self)
	self.inputmode = Inputmodes:for_db(self.inputmode)
	return self
end

function Scores.to_name(self, row) return to_name(row) end
function Scores.for_db(self, row) return for_db(row) end

local _load = Scores.load
function Scores:load(row)
	row.is_valid = toboolean(row.is_valid)
	row.is_complete = toboolean(row.is_complete)
	row.replay_uploaded = toboolean(row.replay_uploaded)
	row.created_at = tonumber(row.created_at)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

return Scores
