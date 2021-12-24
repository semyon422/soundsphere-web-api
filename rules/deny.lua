local Rule = require("abac.Rule")

local rule = Rule:new()

rule.effect = "deny"

return rule
