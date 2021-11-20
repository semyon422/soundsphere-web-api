local Group_users = require("models.group_users")
local Roles = require("models.roles")
local preload = require("lapis.db.model").preload

local context_loader = {}

local etot = {}  -- empty table of tables
local etot_mt = {
	__index = function(t, k)
		local v = rawget(t, k)
		if v then return v end
		if type(k) == "string" and not k:find("^.+_count$") then
			return etot
		end
	end
}
setmetatable(etot, etot_mt)

local function load_role(roles, role)
	local roletype = Roles.types:to_name(role.roletype)
	local object_type = Roles.object_types:to_name(role.object_type)

	roles[roletype] = roles[roletype] or {}
	local role_info = roles[roletype]

	role_info[object_type] = role_info[object_type] or {}
	role_info[object_type .. "_count"] = (role_info[object_type .. "_count"] or 0) + 1
	local role_info_type = role_info[object_type]

	role_info_type[role.object_id] = true

	setmetatable(role_info, etot_mt)
	setmetatable(role_info_type, etot_mt)
end

local function load_roles(user)
	local roles = {}

	local user_roles = user:get_roles()
	for _, user_role in ipairs(user_roles) do
		load_role(roles, user_role)
	end

	local group_users = Group_users:find_all({user.id}, "user_id")
	preload(group_users, "group_roles")
	for _, group_user in ipairs(group_users) do
		local group_roles = group_user.group_roles
		for _, group_role in ipairs(group_roles) do
			load_role(roles, group_role)
		end
	end

	setmetatable(roles, etot_mt)

	user.roles = roles
end

function context_loader:load_context(request)
	local context = request.context
	if context.user and not context.user.roles then
		load_roles(context.user)
	end
	if context.session_user and not context.session_user.roles then
		load_roles(context.session_user)
	end
end

return context_loader
