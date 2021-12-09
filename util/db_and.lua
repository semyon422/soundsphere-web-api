return function(...)
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