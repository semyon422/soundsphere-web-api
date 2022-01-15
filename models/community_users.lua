local Model = require("lapis.db.model").Model
local Roles = require("enums.roles")
local toboolean = require("util.toboolean")

local Community_users = Model:extend(
	"community_users",
	{
		relations = {
			{"community", belongs_to = "communities", key = "community_id"},
			{"user", belongs_to = "users", key = "user_id"},
			{"staff_user", belongs_to = "users", key = "staff_user_id"},
		},
		url_params = function(self, req, ...)
			return "community.user", {community_id = self.community_id, user_id = self.user_id}, ...
		end,
	}
)

local function to_name(self)
	self.role = Roles:to_name(self.role)
	return self
end

local function for_db(self)
	self.role = Roles:for_db(self.role)
	return self
end

function Community_users.to_name(self, row) return to_name(row) end
function Community_users.for_db(self, row) return for_db(row) end

local _load = Community_users.load
function Community_users:load(row)
	row.accepted = toboolean(row.accepted)
	row.invitation = toboolean(row.invitation)
	row.created_at = tonumber(row.created_at)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

function Community_users:set_role(community_user, role, update)
	if not community_user or not community_user.user_id or not community_user.community_id then
		return
	end
	if update and not community_user.update then
		community_user = Community_users:find({
			user_id = community_user.user_id,
			community_id = community_user.community_id,
		})
	end
	role = Roles:for_db(role)
	if not community_user or community_user.role == role then
		return
	end
	community_user.role = role
	if update then
		community_user:update("role")
	end
end

return Community_users
