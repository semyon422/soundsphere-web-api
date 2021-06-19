local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(context)
    return not context.token_user.roles.creator.community
end

rule.effect = "permit"

return rule
