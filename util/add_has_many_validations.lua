local models = require("models")

local function add_has_many(relations, validations, prefix)
	validations = validations or {}
	for _, relation in ipairs(relations) do
		if (relation.has_many or relation.fetch) and not relation.deny_auto then
			table.insert(validations, {prefix .. relation[1], type = "boolean", optional = true})
		end
	end
	return validations
end

local function add(relations, validations)
	validations = validations or {}
	add_has_many(relations, validations, "")
	for _, relation in ipairs(relations) do
		if relation.belongs_to then
			local subrelations = models[relation.belongs_to].relations
			if subrelations then
				add_has_many(subrelations, validations, relation[1] .. "_")
			end
		end
	end
	return validations
end

return add
