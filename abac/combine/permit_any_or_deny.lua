return function(a, b)
    if a == "permit" or b == "permit" then
        return "permit"
    end
    return "deny"
end
