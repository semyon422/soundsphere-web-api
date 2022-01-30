local preload = require("lapis.db.model").preload

local select = function(self, where)
	local communities = {}
	where = where or {}
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

local function load_communities(user)
	local communities = {select = select}

	local community_users = user:get_community_users()
	preload(community_users, "community")
	user.community_users = nil
	for _, community_user in ipairs(community_users) do
		community_user.is_public = community_user.community.is_public
		community_user.community = nil
		table.insert(communities, community_user:to_name())
	end

	user.communities = communities
end

return function(self)
	local context = self.context
	if context.user and not context.user.communities then
		load_communities(context.user)
	end
	if context.session_user and not context.session_user.communities then
		load_communities(context.session_user)
	end
	return true
end
