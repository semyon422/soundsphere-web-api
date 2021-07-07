local schema = require("lapis.db.schema")
local types = schema.types

local db = {}

local tables = {
	"leaderboard_tables",
	"leaderboard_users",
	"leaderboards",
	"tables",
	"table_notecharts",
	"user_roles",
	"users",
	"communities",
	"community_leaderboards",
	"community_users",
	"community_tables",
	"community_inputmodes",
	"domains",
	"group_roles",
	"group_users",
	"groups",
	"containers",
	"formats",
	"inputmodes",
	"modifiers",
	"notecharts",
	"scores",
	"user_statistics",
}

local table_declarations = {}

local type_id = types.id({null = false, unsigned = true})
local type_fk_id = types.integer({null = false, unsigned = true})
local type_size = types.integer({null = false, unsigned = true, default = 0})
local type_hash = "char(32) CHARACTER SET latin1 NOT NULL"
local type_time = types.bigint({unsigned = true})

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

table_declarations.leaderboard_users = {
	{"id", type_id},
	{"leaderboard_id", type_fk_id},
	{"user_id", type_fk_id},
	"UNIQUE KEY `leaderboard_users` (`leaderboard_id`,`user_id`)"
}

table_declarations.leaderboards = {
	{"id", type_id},
	{"domain_id", type_fk_id},
	{"name", types.varchar},
	{"description", types.varchar},
}

table_declarations.tables = {
	{"id", type_id},
	{"name", types.varchar},
	{"url", types.varchar},
	{"play_count", type_size},
}

table_declarations.table_notecharts = {
	{"id", type_id},
	{"table_id", type_fk_id},
	{"notechart_id", type_fk_id},
	"UNIQUE KEY `table_notecharts` (`table_id`,`notechart_id`)"
}

table_declarations.user_roles = {
	{"id", type_id},
	{"user_id", type_fk_id},
	{"roletype", type_fk_id},
	{"domain_id", type_fk_id},
	"UNIQUE KEY `user_role_domain` (`user_id`,`roletype`,`domain_id`)"
}

table_declarations.users = {
	{"id", type_id},
	{"name", types.varchar},
	{"tag", types.varchar},
	"`email` VARCHAR(100) NOT NULL",
	{"password", types.varchar},
	{"latest_activity", type_time},
	{"creation_time", type_time},
	{"description", types.varchar},
	"UNIQUE KEY `email` (`email`)"
}

table_declarations.communities = {
	{"id", type_id},
	{"domain_id", type_fk_id},
	{"name", types.varchar},
	{"alias", types.varchar},
	{"short_description", types.varchar},
	{"description", types.varchar},
	{"user_count", type_size},
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

table_declarations.community_tables = {
	{"id", type_id},
	{"community_id", type_fk_id},
	{"table_id", type_fk_id},
	"UNIQUE KEY `community_tables` (`community_id`,`table_id`)"
}

table_declarations.community_inputmodes = {
	{"id", type_id},
	{"community_id", type_fk_id},
	{"inputmode_id", type_fk_id},
	"UNIQUE KEY `community_inputmodes` (`community_id`,`inputmode_id`)"
}

table_declarations.domains = {
	{"id", type_id},
	{"domaintype", type_fk_id},
}

table_declarations.group_roles = {
	{"id", type_id},
	{"group_id", type_fk_id},
	{"roletype", type_fk_id},
	{"domain_id", type_fk_id},
	"UNIQUE KEY `group_role_domain` (`group_id`,`roletype`,`domain_id`)"
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

table_declarations.containers = {
	{"id", type_id},
	{"hash", type_hash},
	{"format_id", type_fk_id},
	{"uploaded", types.boolean},
	{"size", type_size},
	{"imported", types.boolean},
	{"creation_time", type_time},
	[[
		UNIQUE KEY `hash` (`hash`),
		KEY `format_id` (`format_id`),
		KEY `imported` (`imported`)
	]]
}

table_declarations.formats = {
	{"id", type_id},
	{"extension", types.varchar({length = 4})},
	{"blocked", types.boolean({default = 0})},
}

table_declarations.inputmodes = {
	{"id", type_id},
	{"name", types.varchar},
}

table_declarations.modifiers = {
	{"id", type_id},
	"`name` VARCHAR(100) NOT NULL",
	"UNIQUE KEY `name` (`name`)"
}

table_declarations.notecharts = {
	{"id", type_id},
	{"container_id", type_fk_id},
	{"index", type_fk_id},
	{"creation_time", type_time},
	{"play_count", type_size},
	{"inputmode_id", type_fk_id},
	{"difficulty", types.float},
	{"song_title", types.text},
	{"song_artist", types.text},
	{"difficulty_name", types.text},
	{"difficulty_creator", types.text},
	[[
		UNIQUE KEY `hashindex` (`container_id`,`index`),
		KEY `inputmode_id` (`inputmode_id`)
	]]
}

table_declarations.scores = {
	{"id", type_id},
	{"user_id", type_fk_id},
	{"notechart_id", type_fk_id},
	{"modifier_id", type_fk_id},
	{"inputmode_id", type_fk_id},
	{"replay_hash", type_hash},
	{"is_valid", types.boolean},
	{"calculated", types.boolean},
	{"replay_uploaded", types.boolean},
	{"replay_size", type_size},
	{"creation_time", type_time},
	{"score", types.float},
	{"accuracy", types.float},
	{"max_combo", type_size},
	{"performance", types.float},
	[[
		UNIQUE KEY `replay_hash` (`replay_hash`),
		KEY `user_id` (`user_id`),
		KEY `notechart_id` (`notechart_id`),
		KEY `modifier_id` (`modifier_id`),
		KEY `inputmode_id` (`inputmode_id`),
		KEY `performance` (`performance`),
		KEY `calculated` (`calculated`)
	]]
}

table_declarations.user_statistics = {
	{"id", type_id},
	{"user_id", type_fk_id},
	{"leaderboard_id", type_fk_id},
	{"active", types.boolean},
	{"play_count", type_size},
	{"total_performance", types.float},
	{"total_accuracy", types.float},
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
