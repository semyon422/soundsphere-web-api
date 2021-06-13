local Rule = {}

function Rule:new()
	return setmetatable({}, {__index = Rule})
end

function Rule:target() return true end
function Rule:condition() return true end

Rule.effect = "permit"

Rule.obligations = {}
Rule.advices = {}

function Rule:get_obligations(decision)
	local obligations = {}
	for _, obligation in ipairs(self.obligations) do
		if obligation.effect == decision then
			table.insert(obligations, obligation)
		end
	end
	return obligations
end

function Rule:get_advices(decision)
	local advices = {}
	for _, advice in ipairs(self.advices) do
		if advice.effect == decision then
			table.insert(advices, advice)
		end
	end
	return advices
end

local function evaluate(self, context)
	return self:target(context) and self:condition(context)
end

function Rule:evaluate(context)
	local status, err = pcall(evaluate, self, context)
	if not status then print(err) return "indeterminate" end
	if err then return self.effect end
	return "not_applicable"
end

return Rule
