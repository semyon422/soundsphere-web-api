local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
    return request.context.session_user.roles.admin[tonumber(request.context.community.domain_id)]
end

rule.effect = "permit"

return rule
