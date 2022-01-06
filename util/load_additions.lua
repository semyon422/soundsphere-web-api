return function(self, object, params, additions)
	local fields = {}
	for param, controller in pairs(additions) do
		local value = params[param]
		if value ~= nil then
			local param_count = param .. "_count"
			params.no_data = value == false
			local response = controller.GET(self).json
			object[param] = response[param]
			if object[param_count] and object[param_count] ~= response.total then
				object[param_count] = response.total
				table.insert(fields, param_count)
			end
		end
	end
	if #fields > 0 then
		object:update(unpack(fields))
	end
end
