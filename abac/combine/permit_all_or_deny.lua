return function(a, b)
    if a == "permit" and b == "permit" then
        return "permit"
    end
    return "deny"
end
