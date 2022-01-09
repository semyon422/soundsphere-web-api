return function(relations, validations)
	validations = validations or {}
	for _, relation in ipairs(relations) do
		if (relation.has_many or relation.fetch) and not relation.deny_auto then
			table.insert(validations, {relation[1], type = "boolean", optional = true})
		end
	end
	return validations
end
