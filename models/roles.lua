local model = require("lapis.db.model")
local Model, enum = model.Model, model.enum

local Roles = Model:extend(
	"roles",
	{
		relations = {
			{"subject", polymorphic_belongs_to = {
				[1] = {"users"},
				[2] = {"groups"},
			}},
			{"object", polymorphic_belongs_to = {
				[1] = {"communities"},
				[2] = {"leaderboards"},
			}},
		}
	}
)

Roles.types = enum({
	creator = 1,
	user = 2,
	admin = 3,
	moderator = 4,
})

local table_names = {
	user = "users",
	group = "groups",
	community = "communities",
	leaderboard = "leaderboards",
}

local entry_names = {
	users = "user",
	groups = "group",
	communities = "community",
	leaderboards = "leaderboard",
}


local function get_role(roletype, obj)
	local role = {object_type = 0, object_id = 0}
	role.roletype = Roles.types:for_db(roletype)
	for key, value in pairs(obj) do
		local table_name = table_names[key:match("^(.+)_id$")]
		if Roles.object_types[table_name] then
			role.object_type = Roles.object_types:for_db(table_name)
			role.object_id = value
		elseif Roles.subject_types[table_name] then
			role.subject_type = Roles.subject_types:for_db(table_name)
			role.subject_id = value
		end
	end
	return role
end

function Roles:assign(roletype, obj)
	local role = get_role(roletype, obj)
	local found_role = self:find(role)
	if not found_role then
		return self:create(role)
	end
	return found_role
end

function Roles:reject(roletype, obj)
	local role = get_role(roletype, obj)
	role = self:find(role)
	if role then
		role:delete()
	end
end

function Roles:extract_list(obj)
	local rows = {}
	for key, value in pairs(obj) do
		local table_name = table_names[key:match("^(.+)_id$")]
		if self.subject_types[table_name] then
			rows = self:select({where = {
				subject_type = self.subject_types:for_db(table_name),
				subject_id = value
			}})
		end
	end
	local roles = {}
	for _, row in ipairs(rows) do
		local role = {
			roletype = Roles.types:to_name(row.roletype),
		}
		if row.object_type ~= 0 then
			local table_name = self.object_types:to_name(row.object_type)
			role.object_type = entry_names[table_name]
			role.object_id = row.object_id
			role.resource = ("/%s/%d"):format(table_name, row.object_id)
		end
		table.insert(roles, role)
	end
	return roles
end

return Roles
