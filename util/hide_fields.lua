return function(object, fields)
	for _, field in ipairs(fields) do
		object[field] = nil
	end
	return object
end