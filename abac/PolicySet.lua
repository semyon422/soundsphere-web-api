local Rule = require("abac.Rule")

local PolicySet = {}

function PolicySet:new()
	return setmetatable({}, {__index = PolicySet})
end

function PolicySet:target(context) return true end
function PolicySet.policy_combine_algorithm(decision, policy_decision) end

PolicySet.policies = {}
PolicySet.context_loaders = {}

PolicySet.obligations = {}
PolicySet.advices = {}

PolicySet.get_obligations = Rule.get_obligations
PolicySet.get_advices = Rule.get_advices

local function insert_items(t, items)
	for i = 1, #items do
		t[#t + 1] = items[i]
	end
end

function PolicySet:evaluate(context)
	local obligations = {}
	local advices = {}
	if not self:target(context) then
		return "not_applicable", obligations, advices
	end
	for _, context_loader in ipairs(self.context_loaders) do
		context_loader:load_context(context)
	end

	local policies = self.policies
	local decision
	for i = 0, #policies - 1 do
		local policy = policies[i + 1]
		local policy_decision, policy_obligations, policy_advices = policy:evaluate(context)
		if decision then
			decision = self.policy_combine_algorithm(decision, policy_decision)
		else
			decision = policy_decision
		end
		table.insert(obligations, policy:get_obligations(policy_decision))
		table.insert(advices, policy:get_advices(policy_decision))
		insert_items(obligations, policy_obligations)
		insert_items(advices, policy_advices)
	end
	return decision, obligations, advices
end

return PolicySet
