local function db_and(...)
	local t = ...
	if type(t) == "table" then
		return db_and(unpack(t))
	end
	local clauses = {}
	for i = 1, select("#", ...) do
		local clause = select(i, ...)
		if clause then
			table.insert(clauses, ("(%s)"):format(clause))
		end
	end
	if #clauses == 0 then
		return
	end
	return table.concat(clauses, " and ")
end

return db_and
