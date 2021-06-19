local schema = require("lapis.db.schema")
local types = schema.types

local db = {}

local tables = {
	"leaderboard_tables",
	"leaderboards",
	"roles",
	"tables",
	"user_roles",
	"users",
	"communities",
	"community_leaderboards",
	"community_users",
	"domains",
	"group_roles",
	"group_users",
	"groups",
}

local table_declarations = {}

local type_id = types.id({null = false, unsigned = true})
local type_fk_id = types.integer({null = false, unsigned = true})
local options = {
	engine = "InnoDB",
	charset = "utf8mb4 COLLATE=utf8mb4_unicode_ci"
}

-- https://stackoverflow.com/questions/766809/whats-the-difference-between-utf8-general-ci-and-utf8-unicode-ci
-- COLLATE=utf8mb4_0900_ai_ci
-- COLLATE=utf8mb4_unicode_520_ci

table_declarations.leaderboard_tables = {
	{"id", type_id},
	{"leaderboard_id", type_fk_id},
	{"table_id", type_fk_id},
	"UNIQUE KEY `leaderboard_tables` (`leaderboard_id`,`table_id`)"
}

table_declarations.leaderboards = {
	{"id", type_id},
	{"domain_id", type_fk_id},
	{"name", types.varchar},
}

table_declarations.roles = {
	{"id", type_id},
	{"name", types.varchar},
}

table_declarations.tables = {
	{"id", type_id},
	{"name", types.varchar},
}

table_declarations.user_roles = {
	{"id", type_id},
	{"user_id", type_fk_id},
	{"role_id", type_fk_id},
	{"domain_id", type_fk_id},
	"UNIQUE KEY `user_role_domain` (`user_id`,`role_id`,`domain_id`)"
}

table_declarations.users = {
	{"id", type_id},
	{"name", types.varchar},
	{"tag", types.varchar},
	"`email` VARCHAR(100) NOT NULL",
	{"password", types.varchar},
	"`latest_activity` timestamp NULL DEFAULT NULL",
	"`creation_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP",
	"UNIQUE KEY `email` (`email`)"
}

table_declarations.communities = {
	{"id", type_id},
	{"domain_id", type_fk_id},
	{"name", types.varchar},
}

table_declarations.community_leaderboards = {
	{"id", type_id},
	{"community_id", type_fk_id},
	{"leaderboard_id", type_fk_id},
	"UNIQUE KEY `community_leaderboards` (`community_id`,`leaderboard_id`)"
}

table_declarations.community_users = {
	{"id", type_id},
	{"community_id", type_fk_id},
	{"user_id", type_fk_id},
	{"accepted", types.boolean},
	"UNIQUE KEY `community_users` (`community_id`,`user_id`), INDEX `accepted` (`accepted`)"
}

table_declarations.domains = {
	{"id", type_id},
	{"type_id", type_fk_id},
}

table_declarations.group_roles = {
	{"id", type_id},
	{"group_id", type_fk_id},
	{"role_id", type_fk_id},
	{"domain_id", type_fk_id},
	"UNIQUE KEY `group_role_domain` (`group_id`,`role_id`,`domain_id`)"
}

table_declarations.group_users = {
	{"id", type_id},
	{"group_id", type_fk_id},
	{"user_id", type_fk_id},
	"UNIQUE KEY `group_users` (`group_id`,`user_id`)"
}

table_declarations.groups = {
	{"id", type_id},
	{"name", types.varchar},
}

function db.drop()
	for _, table in ipairs(tables) do
		schema.drop_table(table)
	end
end

function db.create()
	for _, table in ipairs(tables) do
		schema.create_table(table, table_declarations[table], options)
	end
end

return db
