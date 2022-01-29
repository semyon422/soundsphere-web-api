local Model = require("lapis.db.model").Model
local enum = require("lapis.db.model").enum

local Changes = enum({
	create = 0,
	delete = 1,
	update = 2,
	invite = 3,
	accept = 4,
	kick = 5,
	transfer_ownership = 6,
})

local Community_changes = Model:extend(
	"community_changes",
	{
		relations = {
			{"community", belongs_to = "communities", key = "community_id"},
			{"user", belongs_to = "users", key = "user_id"},
			{"object", polymorphic_belongs_to = {
				-- [id] = {name, model_name},
				[1] = {"user", "users"},
				[2] = {"community", "communities"},
				[3] = {"leaderboard", "leaderboards"},
				[4] = {"difftable", "difftables"},
				[5] = {"notechart", "notecharts"},
				[6] = {"score", "scores"},
				[7] = {"file", "files"},
			}},
		}
	}
)

function Community_changes:add_change(user_id, community_id, change, object)
	return self:create({
		user_id = user_id,
		community_id = community_id,
		created_at = os.time(),
		change = Changes:for_db(change),
		object_id = object.id,
		object_type = Community_changes:object_type_for_object(object),
	})
end

local function to_name(self)
	self.object_type = Community_changes.object_types:to_name(self.object_type)
	self.change = Changes:to_name(self.change)
	return self
end

local function for_db(self)
	self.object_type = Community_changes.object_types:for_db(self.object_type)
	self.change = Changes:for_db(self.change)
	return self
end

function Community_changes.to_name(self, row) return to_name(row) end
function Community_changes.for_db(self, row) return for_db(row) end

local _load = Community_changes.load
function Community_changes:load(row)
	row.created_at = tonumber(row.created_at)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

return Community_changes
