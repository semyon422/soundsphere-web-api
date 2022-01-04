local json = require("cjson")

return function(fn)
	return function(self, ...)
		local content_type = self.req.headers["content-type"]
		if content_type then
			if string.find(content_type:lower(), "application/json", nil, true) then
				local body = self.req:read_body_as_string()
				local success, obj_or_err = pcall(function()
					return json.decode(body)
				end)
				if success then
					self.__class.support.add_params(self, obj_or_err, "json")
				end
			end
		end
		local input = self.params.json_params
		local content
		if type(input) == "table" and input.filename ~= "" and input.content ~= "" then
			content = input.content
		elseif type(input) == "string" then
			content = input
		end
		if content then
			local success, obj_or_err = pcall(function()
				return json.decode(content)
			end)
			if success then
				self.__class.support.add_params(self, obj_or_err, "json")
			end
		end
		self.params.json_params = nil
		return fn(self, ...)
	end
end