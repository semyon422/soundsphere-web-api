return function(additions, validations)
	validations = validations or {}
	local list = {}
	for addition in pairs(additions) do
		table.insert(list, addition)
	end
	table.sort(list)
	for _, addition in ipairs(list) do
		table.insert(validations, {addition, type = "boolean", optional = true})
	end
	return validations
end
