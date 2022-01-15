local Rule = {}

function Rule:new(rule)
	rule = rule or {}
	setmetatable(rule, self)
	self.__index = self
	return rule
end

function Rule:target() return true end
function Rule:condition() return true end

Rule.effect = "permit"

local function evaluate(self, request)
	return self:target(request) and self:condition(request)
end

function Rule:evaluate(request)
	local status, err = pcall(evaluate, self, request)
	if not status then print(err) return "indeterminate" end
	if err then return self.effect end
	return "not_applicable"
end

return Rule
