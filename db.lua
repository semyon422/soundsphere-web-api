local schema = require("lapis.db.schema")
local types = schema.types

local db = {}

local tables = {
	"leaderboard_tables",
	"leaderboard_users",
	"leaderboard_scores",
	"leaderboard_inputmodes",
	"leaderboards",
	"tables",
	"table_notecharts",
	"roles",
	"users",
	"user_rivals",
	"communities",
	"community_leaderboards",
	"community_users",
	"community_tables",
	"community_inputmodes",
	"group_users",
	"groups",
	"containers",
	"modifiers",
	"notecharts",
	"scores",
}

local table_declarations = {}

local type_id = types.id({null = false, unsigned = true})
local type_fk_id = types.integer({null = false, unsigned = true})
local type_size = types.integer({null = false, unsigned = true, default = 0})
local type_hash = "char(32) CHARACTER SET latin1 NOT NULL"
-- local type_time = types.bigint({unsigned = true})
local type_time = "TIMESTAMP NOT NULL DEFAULT 0"

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
	{"active", types.boolean},
	{"play_count", type_size},
	{"total_performance", types.float},
	{"total_accuracy", types.float},
	"UNIQUE KEY `leaderboard_users` (`leaderboard_id`,`user_id`)"
}

table_declarations.leaderboard_scores = {
	{"id", type_id},
	{"leaderboard_id", type_fk_id},
	{"user_id", type_fk_id},
	{"notechart_id", type_fk_id},
	{"score_id", type_fk_id},
	"UNIQUE KEY `leaderboard_user_notechart` (`leaderboard_id`,`user_id`,`notechart_id`)"
}

table_declarations.leaderboard_inputmodes = {
	{"id", type_id},
	{"leaderboard_id", type_fk_id},
	{"inputmode", types.enum},
	"UNIQUE KEY `leaderboard_inputmodes` (`leaderboard_id`,`inputmode`)"
}

table_declarations.leaderboards = {
	{"id", type_id},
	{"name", types.varchar},
	{"description", types.varchar},
	{"communities_count", type_size},
	{"tables_count", type_size},
	{"users_count", type_size},
	{"top_user_id", type_fk_id},
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

table_declarations.roles = {
	{"id", type_id},
	{"roletype", types.enum},
	{"subject_id", type_fk_id},
	{"subject_type", types.enum},
	{"object_id", type_fk_id},
	{"object_type", types.enum},
	{"expires_at", type_time},
	"UNIQUE KEY `subject_object` (`roletype`,`subject_id`,`subject_type`,`object_id`,`object_type`)"
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

table_declarations.user_rivals = {
	{"id", type_id},
	{"user_id", type_fk_id},
	{"rival_id", type_fk_id},
	"UNIQUE KEY `user_rivals` (`user_id`,`rival_id`)"
}

table_declarations.communities = {
	{"id", type_id},
	{"name", types.varchar},
	{"alias", types.varchar},
	{"short_description", types.varchar},
	{"description", types.varchar},
	{"users_count", type_size},
	{"leaderboards_count", type_size},
	{"inputmodes_count", type_size},
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
	{"invitation", types.boolean},
	[[
		UNIQUE KEY `community_users` (`community_id`,`user_id`),
		KEY `accepted` (`accepted`),
		KEY `invitation` (`invitation`)
	]]
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
	{"inputmode", types.enum},
	"UNIQUE KEY `community_inputmodes` (`community_id`,`inputmode`)"
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
	{"format", types.enum},
	{"uploaded", types.boolean},
	{"size", type_size},
	{"imported", types.boolean},
	{"creation_time", type_time},
	[[
		UNIQUE KEY `hash` (`hash`),
		KEY `format` (`format`),
		KEY `imported` (`imported`)
	]]
}

table_declarations.modifiers = {
	{"id", type_id},
	"`name` VARCHAR(100) NOT NULL",
	"UNIQUE KEY `name` (`name`)"
}

table_declarations.notecharts = {
	{"id", type_id},
	{"container_id", type_fk_id},
	{"index", types.enum},
	{"creation_time", type_time},
	{"play_count", type_size},
	{"inputmode", types.enum},
	{"difficulty", types.float},
	{"song_title", types.text},
	{"song_artist", types.text},
	{"difficulty_name", types.text},
	{"difficulty_creator", types.text},
	[[
		UNIQUE KEY `hashindex` (`container_id`,`index`),
		KEY `inputmode` (`inputmode`)
	]]
}

table_declarations.scores = {
	{"id", type_id},
	{"user_id", type_fk_id},
	{"notechart_id", type_fk_id},
	{"modifier_id", type_fk_id},
	{"inputmode", types.enum},
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
		KEY `inputmode` (`inputmode`),
		KEY `performance` (`performance`),
		KEY `calculated` (`calculated`)
	]]
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
