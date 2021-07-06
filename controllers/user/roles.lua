local User_roles = require("models.user_roles")
local preload = require("lapis.db.model").preload

local user_roles_c = {}

user_roles_c.GET = function(params)
    local user_roles = User_roles:find_all({params.user_id}, "user_id")
	preload(user_roles, "domain")

    local roles = {}
	for _, user_role in ipairs(user_roles) do
		table.insert(roles, user_role.role)
	end

	local count = User_roles:count()

	return 200, {
		total = count,
		filtered = count,
		roles = roles
	}
end

return user_roles_c
