return function(a, b)
    if a == "indeterminate" or b == "indeterminate" then
        return "indeterminate"
    end
    if a == "deny" or b == "deny" then
        return "deny"
    end
    if a == "permit" or b == "permit" then
        return "permit"
    end
    return "not_applicable"
end
