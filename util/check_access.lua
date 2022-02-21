return function(self, controller, method)
	local request_policies = self.policies
	local permited_methods = self.permited_methods
	self.policies = {}
	self.permited_methods = {}
	local result = controller:check_access(self, method)
	self.policies = request_policies
	self.permited_methods = permited_methods
	return result
end
