local models = require("models")

local function add(relations, validations, prefix)
	prefix = prefix or ""
	validations = validations or {}
	for _, relation in ipairs(relations) do
		if relation.belongs_to then
			table.insert(validations, {prefix .. relation[1], type = "boolean", optional = true})
			local subrelations = models[relation.belongs_to].relations
			if subrelations then
				add(subrelations, validations, relation[1] .. "_")
			end
		end
	end
	return validations
end

return add
