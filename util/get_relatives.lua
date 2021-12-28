return function(object, params, to_name)
	local relations = object.__class.relations

	for _, relation in ipairs(relations) do
		if params[relation[1]] then
			local relative = object["get_" .. relation[1]](object)
			if relative and to_name and relative.to_name then
				relative:to_name()
			end
		end
	end
end
