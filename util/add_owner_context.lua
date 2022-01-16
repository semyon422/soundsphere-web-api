return function(name, params_or_context, context)
	context = context or {}
	table.insert(context, name)
	table.insert(context, "request_session")
	table.insert(context, "session_user")
	table.insert(context, "user_communities")
	table.insert(context, function(self)
		local params = self.params
		local object = self[params_or_context][name]
		params.community_id = object and object.owner_community_id or 0
		return true
	end)
	return context
end
