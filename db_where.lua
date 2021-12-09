return function(clause)
	if not clause then
		return ""
	end
	if not clause:lower():find("^where") then
		return "where " .. clause
	end
	return clause
end
