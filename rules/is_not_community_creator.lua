local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
    return not request.context.session_user.roles.creator.community
end

rule.effect = "permit"

return rule
