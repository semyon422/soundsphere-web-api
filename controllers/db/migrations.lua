local migrations = require("lapis.db.migrations")
local Controller = require("Controller")

local migrations_c = Controller:new()

migrations_c.path = "/db/migrations"
migrations_c.methods = {"GET", "POST"}

migrations_c.context.GET = {"request_session"}
migrations_c.policies.GET = {{"authenticated"}}
migrations_c.GET = function(self)
	local names = {}
	for _, migration in ipairs(migrations.LapisMigrations:select()) do
		table.insert(names, migration.name)
	end
	return {json = {
		total = #names,
		filtered = #names,
		migrations = names,
	}}
end

migrations_c.context.POST = {"request_session"}
migrations_c.policies.POST = {{"authenticated"}}
migrations_c.POST = function(self)
	migrations.run_migrations(require("migrations"))
	local total = migrations.LapisMigrations:count()
	return {json = {total = tonumber(total)}}
end

return migrations_c
