local model = require("lapis.db.model")
local Model, enum = model.Model, model.enum
local toboolean = require("util.toboolean")

local User_relations = Model:extend(
	"user_relations",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
			{"relative_user", belongs_to = "users", key = "relative_user_id"},
		}
	}
)

local _load = User_relations.load
function User_relations:load(row)
	row.mutual = toboolean(row.mutual)
	return _load(self, row)
end

User_relations.types = enum({
	friend = 1,
	rival = 2,
})

function User_relations:relate(relationtype, user_id, relative_user_id)
	local new_relation = {
		relationtype = self.types:for_db(relationtype),
		user_id = user_id,
		relative_user_id = relative_user_id,
	}
	local relation = self:find(new_relation)
	if not relation then
		relation = self:create(new_relation)
	end

	local reverse_relation = self:find({
		relationtype = self.types:for_db(relationtype),
		user_id = relative_user_id,
		relative_user_id = user_id,
	})

	if reverse_relation then
		relation.mutual = true
		relation:update("mutual")
		reverse_relation.mutual = true
		reverse_relation:update("mutual")
	end
end

function User_relations:unrelate(relationtype, user_id, relative_user_id)
	local relation = self:find({
		relationtype = self.types:for_db(relationtype),
		user_id = user_id,
		relative_user_id = relative_user_id,
	})
	if not relation then
		return
	end
	relation:delete()

	local reverse_relation = self:find({
		relationtype = self.types:for_db(relationtype),
		user_id = relative_user_id,
		relative_user_id = user_id,
	})

	if reverse_relation then
		reverse_relation.mutual = false
		reverse_relation:update("mutual")
	end
end

return User_relations
