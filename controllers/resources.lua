local Controller = require("Controller")
local autoload = require("lapis.util").autoload
local controllers = autoload("controllers")

local resources_c = Controller:new()

resources_c.path = ""
resources_c.methods = {"GET"}

resources_c.policies.GET = {{"permit"}}
resources_c.GET = function(request)
	local params = request.params

	local resources = {}
	for _, name in ipairs(require("endpoints")) do
		local controller = controllers[name]
		local children = {}
		for _, child in ipairs(controller.children) do
			table.insert(children, child.name)
		end
		table.insert(resources, {
			name = name,
			path = controller.path,
			methods = controller.methods,
			params = controller.params,
			level = controller.level,
			parent = controller.parent and controller.parent.name,
			children = children,
		})
	end
	table.sort(resources, function(a, b)
		return a.name < b.name
	end)

	local children = {}
	for _, resource in ipairs(resources) do
		if resource.level == 1 then
			table.insert(children, resource.name)
		end
	end

	return 200, {
		resources = resources,
		children = children
	}
end

return resources_c
