return function(db, search, ...)
	if not search then
		return ""
	end
	local conditions = {...}
	for i = 1, #conditions do
		conditions[i] = db.interpolate_query(
			("%s like ?"):format(db.escape_identifier(conditions[i])),
			("%%%s%%"):format(search)
		)
	end
	return table.concat(conditions, " or ")
end
