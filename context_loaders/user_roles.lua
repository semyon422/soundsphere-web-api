local user_roles = require("models.user_roles")
local group_users = require("models.group_users")
local preload = require("lapis.db.model").preload
local domain_types = require("domain_types")

local context_loader = {}

local function load_role_info(roles, entry_role)
	local role_name = entry_role.role.name
	roles[role_name] = roles[role_name] or {}
	local role_info = roles[role_name]
	role_info.domains = role_info.domains or {}
	role_info.domain_types = role_info.domain_types or {}
	return role_info
end

local function load_role(roles, entry_role)
	local domain_id = entry_role.domain_id
	local type_id = entry_role.domain.type_id
	local role_info = load_role_info(roles, entry_role)
	role_info.domains[domain_id] = true
	local type_name = domain_types[type_id]
	role_info.domain_types[type_name] = (role_info.domain_types[type_name] or 0) + 1
end

local function load_roles(user)
	if user.roles then return print("user.roles") end

	local roles = {}

	local sub_user_roles = user_roles:find_all({user.id}, "user_id")
	preload(sub_user_roles, "role", "domain")
	for _, user_role in ipairs(sub_user_roles) do
		load_role(roles, user_role)
	end

	local sub_group_users = group_users:find_all({user.id}, "user_id")
	preload(sub_group_users, {group = {group_roles = {"role", "domain"}}})
	for _, group_user in ipairs(sub_group_users) do
		local group_roles = group_user.group.group_roles
		for _, group_role in ipairs(group_roles) do
			load_role(roles, group_role)
		end
	end

	user.roles = roles
end

function context_loader:load_context(context)
	if context.user then
		load_roles(context.user)
	end
	if context.token_user then
		load_roles(context.token_user)
	end
end

return context_loader