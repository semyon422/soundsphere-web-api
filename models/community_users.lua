local Model = require("lapis.db.model").Model
local Roles = require("enums.roles")
local toboolean = require("toboolean")

local Community_users = Model:extend(
	"community_users",
	{
		relations = {
			{"community", belongs_to = "communities", key = "community_id"},
			{"user", belongs_to = "users", key = "user_id"},
			{"sender", belongs_to = "users", key = "sender_id"},
		}
	}
)

local _load = Community_users.load
function Community_users:load(row)
	row.accepted = toboolean(row.accepted)
	row.invitation = toboolean(row.invitation)
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
