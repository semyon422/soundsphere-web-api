return function(name, params_or_context, roles)
	local context = {name, "request_session", "session_user", "user_communities", function(self)
		local params = self.params
		local object = self[params_or_context][name]
		params.community_id = object and object.owner_community_id or 0
		return true
	end}
	local policies = {}
	for _, role in ipairs(roles) do
		table.insert(policies, {"context_loaded", "authenticated", {community_role = role}})
	end
	return context, policies
end
