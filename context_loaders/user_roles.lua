local user_roles = require("models.user_roles")
local group_users = require("models.group_users")
local preload = require("lapis.db.model").preload
local domains = require("models.domains")

local context_loader = {}

local etot = {}
local etot_mt = {
	__index = function(t, k)
		local v = rawget(t, k)
		if v then return v end
		if type(k) == "string" then
			return etot
		end
	end
}
setmetatable(etot, etot_mt)

local function load_role(roles, role_entry)
	local domain_id = role_entry.domain_id
	local type_id = role_entry.domain.type_id
	local role_name = role_entry.role.name

	roles[role_name] = roles[role_name] or {}
	local role_info = roles[role_name]

	role_info[domain_id] = true
	local type_name = domains.types:to_name(type_id)
	role_info[type_name] = role_info[type_name] or {}
	local role_info_type = role_info[type_name]
	table.insert(role_info_type, domain_id)

	setmetatable(role_info, etot_mt)
	setmetatable(role_info_type, etot_mt)
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

	setmetatable(roles, etot_mt)

	user.roles = roles
end

function context_loader:load_context(context)
	if context.user and not context.user.roles then
		load_roles(context.user)
	end
	if context.token_user and not context.token_user.roles then
		load_roles(context.token_user)
	end
end

return context_loader
