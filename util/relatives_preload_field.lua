local preload = require("lapis.db.model").preload
local get_relatives_preload = require("util.get_relatives_preload")

return function(objects, subobject_name, Model, params)
	if objects[1] and objects[1][subobject_name] then
		local subobjects = {}
		for _, object in ipairs(objects) do
			table.insert(subobjects, object[subobject_name])
		end
		preload(subobjects, get_relatives_preload(Model, params))
	end
end