local models = require("models")

local function get(model, params, preload)
	preload = preload or {}

	if not model then
		return preload
	end
	local relations = model.relations
	if not relations then
		return
	end

	for _, relation in ipairs(relations) do
		local relative = relation[1]
		if params[relative] and relation.belongs_to then
			preload[relative] = {}
			local new_params = {}
			for key, value in pairs(params) do
				if type(key) == "string" and key:find("^" .. relative .. "_.+$") then
					new_params[key:match("^" .. relative .. "_(.+)$")] = value
				end
			end
			get(models[relation.belongs_to], new_params, preload[relative])
		end
	end

	local empty_keys = {}
	for key, value in pairs(preload) do
		if #value == 0 then
			preload[key] = nil
			table.insert(empty_keys, key)
		end
	end
	for _, key in ipairs(empty_keys) do
		table.insert(preload, key)
	end

	return preload
end

return get
