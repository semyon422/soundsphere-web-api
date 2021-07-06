local User_roles = require("models.user_roles")
local Group_users = require("models.group_users")
local Domains = require("models.domains")
local Roles = require("models.roles")
local preload = require("lapis.db.model").preload

local context_loader = {}

local etot = {}  -- empty table of tables
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
	local roletype = Roles.types:to_name(role_entry.roletype)
	local domaintype = Domains.types:to_name(role_entry.domain.domaintype)

	roles[roletype] = roles[roletype] or {}
	local role_info = roles[roletype]

	role_info[domain_id] = true
	role_info[domaintype] = role_info[domaintype] or {}
	local role_info_type = role_info[domaintype]
	table.insert(role_info_type, domain_id)

	setmetatable(role_info, etot_mt)
	setmetatable(role_info_type, etot_mt)
end

local function load_roles(user)
	if user.roles then return print("user.roles") end

	local roles = {}

	local user_roles = User_roles:find_all({user.id}, "user_id")
	preload(user_roles, "domain")
	for _, user_role in ipairs(user_roles) do
		load_role(roles, user_role)
	end

	local group_users = Group_users:find_all({user.id}, "user_id")
	preload(group_users, {group = {group_roles = "domain"}})
	for _, group_user in ipairs(group_users) do
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
