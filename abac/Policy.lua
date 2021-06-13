local Rule = require("abac.Rule")

local Policy = {}

function Policy:new()
	return setmetatable({}, {__index = Policy})
end

function Policy:target(context) return true end
function Policy.rule_combine_algorithm(decision, rule_decision) end

Policy.rules = {}
Policy.context_loaders = {}

Policy.obligations = {}
Policy.advices = {}

Policy.get_obligations = Rule.get_obligations
Policy.get_advices = Rule.get_advices

function Policy:evaluate(context)
	local obligations = {}
	local advices = {}
	if not self:target(context) then
		return "not_applicable", obligations, advices
	end
	for _, context_loader in ipairs(self.context_loaders) do
		context_loader:load_context(context)
	end

	local rules = self.rules
	local decision
	for i = 0, #rules - 1 do
		local rule = rules[i + 1]
		local rule_decision = rule:evaluate(context)
		if decision then
			decision = self.rule_combine_algorithm(decision, rule_decision)
		else
			decision = rule_decision
		end
		table.insert(obligations, rule:get_obligations(rule_decision))
		table.insert(advices, rule:get_advices(rule_decision))
	end
	return decision, obligations, advices
end

return Policy
