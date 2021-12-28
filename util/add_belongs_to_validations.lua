return function(relations, validations)
	local validations = validations or {}
	for _, relation in ipairs(relations) do
		if relation.belongs_to then
			table.insert(validations, {relation[1], type = "boolean", optional = true})
		end
	end
	return validations
end
