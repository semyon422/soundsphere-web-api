local model = require("lapis.db.model")
local Model, enum = model.Model, model.enum
local toboolean = require("util.toboolean")

local User_relations = Model:extend(
	"user_relations",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
			{"relative_user", belongs_to = "users", key = "relative_user_id"},
		},
		url_params = function(self, req, ...)
			return "user.relation", {user_relation_id = self.id, user_id = self.user_id}, ...
		end,
	}
)

User_relations.types = enum({
	friend = 1,
	rival = 2,
})

local function to_name(self)
	self.relationtype = User_relations.types:to_name(self.relationtype)
	return self
end

local function for_db(self)
	self.relationtype = User_relations.types:for_db(self.relationtype)
	return self
end

function User_relations.to_name(self, row) return to_name(row) end
function User_relations.for_db(self, row) return for_db(row) end

local _load = User_relations.load
function User_relations:load(row)
	row.mutual = toboolean(row.mutual)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

return User_relations
