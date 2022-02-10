return function(name, loader)
	return function(self)
		local context = self.context
		local object = context[name]
		if object ~= nil then
			return object
		end
		context[name] = loader(self) or false
		return context[name]
	end
end
