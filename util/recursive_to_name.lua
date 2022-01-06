local function to_name(t)
	if type(t) ~= "table" then
		return
	end
	if t.to_name then
		t:to_name()
	end
	for _, v in pairs(t) do
		to_name(v)
	end
end

return to_name
