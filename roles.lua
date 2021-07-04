local roles = {
	[1] = "creator",
	[2] = "admin",
}

for id, name in pairs(roles) do
	roles[name] = id
end

return roles
