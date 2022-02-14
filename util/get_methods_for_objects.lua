return function(self, objects, controller, object_name, set_params, get_object)
	if not self.params.methods then
		return
	end
	local context_loaded = self.context.loaded
	local request_policies = self.policies
	local permited_methods = self.permited_methods
	for _, object in ipairs(objects) do
		if get_object then
			object = get_object(object)
		end
		if object then
			local methods = {}
			self.context.loaded = {}
			self.policies = {}
			self.permited_methods = {}
			for _, method in ipairs(controller.methods) do
				self.context[object_name] = object
				if set_params then
					set_params(self.params, object)
				else
					self.params[object_name .. "_id"] = object.id
				end
				controller:load_context(self, method)
				if controller:check_access(self, method, true) then
					table.insert(methods, method)
				end
			end
			object.__methods = methods
			-- object.__loaded = self.context.loaded
		end
	end
	self.context.loaded = context_loaded
	self.policies = request_policies
	self.permited_methods = permited_methods
end
