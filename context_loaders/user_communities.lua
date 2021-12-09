local Roles = require("enums.roles")

local context_loader = {}

local select = function(self, where)
	local communities = {}
	for _, community in ipairs(self) do
		local match = true
		for k, v in pairs(where) do
			if community[k] ~= v then
				match = false
			end
		end
		if match then
			table.insert(communities, community)
		end
	end
	return communities
end

local function load_community_user(communities, community_user)
	table.insert(communities, {
		community_id = community_user.community_id,
		role = Roles:to_name(community_user.role),
	)
	communities.select = select
end

local function load_communities(user)
	local communities = {}

	local community_users = user:get_community_users()
	for _, community_user in ipairs(community_users) do
		load_community_user(communities, community_user)
	end

	user.communities = communities
end

function context_loader:load_context(request)
	local context = request.context
	if context.user and not context.user.communities then
		load_communities(context.user)
	end
	if context.session_user and not context.session_user.communities then
		load_communities(context.session_user)
	end
end

return context_loader