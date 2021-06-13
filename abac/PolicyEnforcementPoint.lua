local PolicyEnforcementPoint = {}

function PolicyEnforcementPoint:new()
	return setmetatable({}, {__index = PolicyEnforcementPoint})
end

function PolicyEnforcementPoint:check(name, req)
	local context = {
		name = name,
		req = req
	}
	local decision, obligations, advices = self.policy_sets:evaluate(context)
	self:process_obligations(obligations)
	self:process_advices(advices)
	context.decision = decision
	return decision == "permit", context
end

function PolicyEnforcementPoint:process_obligations(obligations)
	
end

function PolicyEnforcementPoint:process_advices(advices)
	
end

return PolicyEnforcementPoint
