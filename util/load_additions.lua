local function get_data_name(response)
	local names = {}
	for key, value in pairs(response) do
		if type(value) == "table" then
			table.insert(names, key)
		end
	end
	table.sort(names)
	return names[1]
end

return function(self, object, additions)
	local params = self.params
	local fields = {}
	for param, controller in pairs(additions) do
		local value = params[param]
		if value ~= nil then
			local new_params = {no_data = value == false}
			for _, path_param in ipairs(controller:get_params_list()) do
				new_params[path_param] = params[path_param]
			end
			self.params = new_params
			local response = controller.GET(self).json
			self.params = params
			local data_name = get_data_name(response)
			if data_name then
				object[data_name] = response[data_name]
			end
			local param_count = param .. "_count"
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
