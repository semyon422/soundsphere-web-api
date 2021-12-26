local json = require("cjson")
local json_params = require("lapis.application").json_params

return function(fn)
	json_params(fn)
	return function(self, ...)
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