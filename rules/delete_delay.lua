local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local delete_delay = assert(self.delete_delay)
	return request.context[delete_delay].created_at + 3600 * 24 < os.time()
end

rule.effect = "permit"

return rule
