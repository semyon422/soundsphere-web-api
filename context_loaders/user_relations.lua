local select = function(self, where)
	local relations = {}
	for _, relation in ipairs(self) do
		local match = true
		for k, v in pairs(where) do
			if relation[k] ~= v then
				match = false
			end
		end
		if match then
			table.insert(relations, relation)
		end
	end
	return relations
end

local function load_relations(user)
	local relations = {select = select}

	local user_relations = user:get_user_relations()
	user.user_relations = nil
	for _, user_relation in ipairs(user_relations) do
		table.insert(relations, user_relation:to_name())
	end

	user.relations = relations
end

return function(self)
	local context = self.context
	if context.user and not context.user.relations then
		load_relations(context.user)
	end
	if context.session_user and not context.session_user.relations then
		load_relations(context.session_user)
	end
	return true
end
