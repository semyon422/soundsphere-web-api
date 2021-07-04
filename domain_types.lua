local domain_types = {
	[1] = "root",
    [2] = "community",
    [3] = "leaderboard"
}

for id, name in pairs(domain_types) do
	domain_types[name] = id
end

return domain_types
