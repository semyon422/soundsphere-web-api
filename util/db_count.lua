return function(self, clause, ...)
	local tbl_name = self.db.escape_identifier(self:table_name())
	local query = "COUNT(1) as c from " .. tostring(tbl_name)
	if clause then
		if not clause:lower():find("where") then
			clause = "where " .. clause
		end
		query = query .. " " .. self.db.interpolate_query(clause, ...)
	end
	return unpack(self.db.select(query)).c
end
