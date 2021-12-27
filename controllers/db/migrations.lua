local migrations = require("lapis.db.migrations")
local Controller = require("Controller")

local migrations_c = Controller:new()

migrations_c.path = "/db/migrations"
migrations_c.methods = {"GET", "POST"}

migrations_c.context.GET = {"session"}
migrations_c.policies.GET = {{"authenticated"}}
migrations_c.GET = function(request)
	local names = {}
	for _, migration in ipairs(migrations.LapisMigrations:select()) do
		table.insert(names, migration.name)
	end
	return 200, {
		total = #names,
		filtered = #names,
		migrations = names,
	}
end

migrations_c.context.POST = {"session"}
migrations_c.policies.POST = {{"authenticated"}}
migrations_c.POST = function(request)
	migrations.run_migrations(require("migrations"))
	local total = migrations.LapisMigrations:count()
	return 200, {total = tonumber(count)}
end

return migrations_c
