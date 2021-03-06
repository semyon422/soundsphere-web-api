local function get(object, params, to_name)
	local relations = object.__class.relations
	if not relations then
		return
	end

	for _, relation in ipairs(relations) do
		if params[relation[1]] and (relation.belongs_to or relation.polymorphic_belongs_to) then
			local relative = object["get_" .. relation[1]](object)
			if relative then
				if to_name and relative.to_name then
					relative:to_name()
				end
				local new_params = {}
				for key, value in pairs(params) do
					if type(key) == "string" and key:find("^" .. relation[1] .. "_.+$") then
						new_params[key:match("^" .. relation[1] .. "_(.+)$")] = value
					end
				end
				get(relative, new_params, to_name)
			end
		end
	end
end

return get
