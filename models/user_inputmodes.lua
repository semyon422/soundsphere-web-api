local Model = require("lapis.db.model").Model
local Inputmodes = require("enums.inputmodes")

local User_inputmodes = Model:extend(
	"user_inputmodes",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
		},
		url_params = function(self, req, ...)
			return "user.inputmode", {inputmode = self.inputmode, user_id = self.user_id}, ...
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

function User_inputmodes.to_name(self, row) return to_name(row) end
function User_inputmodes.for_db(self, row) return for_db(row) end

local _load = User_inputmodes.load
function User_inputmodes:load(row)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

return User_inputmodes
