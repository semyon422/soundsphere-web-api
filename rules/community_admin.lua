local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(context)
    return context.token_user.roles.admin.domains[tonumber(context.community.domain_id)]
end

rule.effect = "permit"

return rule
