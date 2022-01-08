return function(additions, validations)
	validations = validations or {}
	local list = {}
	for addition in pairs(additions) do
		table.insert(list, addition)
	end
	table.sort(list)
	for _, addition in ipairs(list) do
		table.insert(validations, {addition, type = "boolean", optional = true})
		local controller = additions[addition]
		if controller.validations.GET then
			for _, validation in ipairs(controller.validations.GET) do
				table.insert(validations, validation)
			end
		end
	end
	return validations
end
