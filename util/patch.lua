return function(object, params, allowed_fields)
	local fields = {}
	for _, key in pairs(allowed_fields) do
		if params[key] then
			object[key] = params[key]
			table.insert(fields, key)
		end
	end
	object:update(unpack(fields))
end
