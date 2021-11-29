local schema = require("lapis.db.schema")

local db = {}

-- CREATE DATABASE backend;

local tables = {
	"leaderboard_difftables",
	"leaderboard_users",
	"leaderboard_scores",
	"leaderboard_inputmodes",
	"leaderboards",
	"difftables",
	"difftable_notecharts",
	"users",
	"user_relations",
	"user_roles",
	"communities",
	"community_leaderboards",
	"community_users",
	"community_difftables",
	"community_inputmodes",
	"containers",
	"modifiers",
	"notecharts",
	"scores",
	"sessions",
	"quick_logins",
}

local table_declarations = {}

local _types = schema.types
local types = {
	id = _types.id({null = false, unsigned = true}),
	fk_id = _types.integer({null = false, unsigned = true, default = 0}),
	size = _types.integer({null = false, unsigned = true, default = 0}),
	md5_hash = "char(32) CHARACTER SET latin1 NOT NULL",
	time = _types.bigint({unsigned = true, default = 0}),
	-- time = "TIMESTAMP NOT NULL DEFAULT 0",
	boolean = _types.boolean({default = false}),
	float = _types.float({default = 0}),
	varchar = _types.varchar,
	enum = _types.enum,
	text = _types.text,
	varchar_ip = "VARCHAR(15) NOT NULL",
}

local options = {
	engine = "InnoDB",
	-- charset = "utf8mb4 COLLATE=utf8mb4_0900_ai_ci"
	charset = "utf8mb4 COLLATE=utf8mb4_unicode_ci"
}

-- https://stackoverflow.com/questions/766809/whats-the-difference-between-utf8-general-ci-and-utf8-unicode-ci
-- COLLATE=utf8mb4_0900_ai_ci
-- COLLATE=utf8mb4_unicode_520_ci

table_declarations.leaderboard_difftables = {
	{"id", types.id},
	{"leaderboard_id", types.fk_id},
	{"difftable_id", types.fk_id},
	"UNIQUE KEY `leaderboard_difftables` (`leaderboard_id`,`difftable_id`)"
}

table_declarations.leaderboard_users = {
	{"id", types.id},
	{"leaderboard_id", types.fk_id},
	{"user_id", types.fk_id},
	{"active", types.boolean},
	{"play_count", types.size},
	{"total_performance", types.float},
	{"total_accuracy", types.float},
	"UNIQUE KEY `leaderboard_users` (`leaderboard_id`,`user_id`)"
}

table_declarations.leaderboard_scores = {
	{"id", types.id},
	{"leaderboard_id", types.fk_id},
	{"user_id", types.fk_id},
	{"notechart_id", types.fk_id},
	{"score_id", types.fk_id},
	"UNIQUE KEY `leaderboard_user_notechart` (`leaderboard_id`,`user_id`,`notechart_id`)"
}

table_declarations.leaderboard_inputmodes = {
	{"id", types.id},
	{"leaderboard_id", types.fk_id},
	{"inputmode", types.enum},
	"UNIQUE KEY `leaderboard_inputmodes` (`leaderboard_id`,`inputmode`)"
}

table_declarations.leaderboards = {
	{"id", types.id},
	{"name", types.varchar},
	{"description", types.varchar},
	{"banner", types.varchar},
	{"top_user_id", types.fk_id},
	{"communities_count", types.size},
	{"difftables_count", types.size},
	{"users_count", types.size},
}

table_declarations.difftables = {
	{"id", types.id},
	{"name", types.varchar},
	{"url", types.varchar},
	{"play_count", types.size},
}

table_declarations.difftable_notecharts = {
	{"id", types.id},
	{"difftable_id", types.fk_id},
	{"notechart_id", types.fk_id},
	"UNIQUE KEY `difftable_notecharts` (`difftable_id`,`notechart_id`)"
}

table_declarations.user_roles = {
	{"id", types.id},
	{"user_id", types.fk_id},
	{"role", types.enum},
	{"expires_at", types.time},
	"UNIQUE KEY `subject_object` (`user_id`, `role`)"
}

table_declarations.users = {
	{"id", types.id},
	{"name", types.varchar},
	{"tag", types.varchar},
	{"email", "VARCHAR(100) NOT NULL"},
	{"password", types.varchar},
	{"latest_activity", types.time},
	{"creation_time", types.time},
	{"description", types.varchar},
	"UNIQUE KEY `email` (`email`)"
}

table_declarations.user_relations = {
	{"id", types.id},
	{"relationtype", types.enum},
	{"user_id", types.fk_id},
	{"relative_user_id", types.fk_id},
	{"mutual", types.boolean},
	"UNIQUE KEY `user_relations` (`relationtype`,`user_id`,`relative_user_id`)"
}

table_declarations.communities = {
	{"id", types.id},
	{"name", types.varchar},
	{"alias", types.varchar},
	{"is_public", types.boolean},
	{"link", types.varchar},
	{"short_description", types.varchar},
	{"description", types.varchar},
	{"banner", types.varchar},
	{"users_count", types.size},
	{"leaderboards_count", types.size},
	{"inputmodes_count", types.size},
}

table_declarations.community_leaderboards = {
	{"id", types.id},
	{"community_id", types.fk_id},
	{"leaderboard_id", types.fk_id},
	{"is_owner", types.boolean},
	"UNIQUE KEY `community_leaderboards` (`community_id`,`leaderboard_id`)",
	"KEY `is_owner` (`is_owner`)",
}

table_declarations.community_users = {
	{"id", types.id},
	{"community_id", types.fk_id},
	{"user_id", types.fk_id},
	{"accepted", types.boolean},
	{"role", types.enum},
	{"invitation", types.boolean},
	[[
		UNIQUE KEY `community_users` (`community_id`,`user_id`),
		KEY `invitation` (`invitation`),
		KEY `accepted` (`accepted`)
	]]
}

table_declarations.community_difftables = {
	{"id", types.id},
	{"community_id", types.fk_id},
	{"difftable_id", types.fk_id},
	"UNIQUE KEY `community_difftables` (`community_id`,`difftable_id`)"
}

table_declarations.community_inputmodes = {
	{"id", types.id},
	{"community_id", types.fk_id},
	{"inputmode", types.enum},
	"UNIQUE KEY `community_inputmodes` (`community_id`,`inputmode`)"
}

table_declarations.containers = {
	{"id", types.id},
	{"hash", types.md5_hash},
	{"format", types.enum},
	{"uploaded", types.boolean},
	{"size", types.size},
	{"imported", types.boolean},
	{"creation_time", types.time},
	[[
		UNIQUE KEY `hash` (`hash`),
		KEY `format` (`format`),
		KEY `imported` (`imported`)
	]]
}

table_declarations.modifiers = {
	{"id", types.id},
	{"name", "VARCHAR(100) NOT NULL"},
	"UNIQUE KEY `name` (`name`)"
}

table_declarations.notecharts = {
	{"id", types.id},
	{"container_id", types.fk_id},
	{"index", types.enum},
	{"creation_time", types.time},
	{"play_count", types.size},
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
	{"id", types.id},
	{"user_id", types.fk_id},
	{"notechart_id", types.fk_id},
	{"modifier_id", types.fk_id},
	{"inputmode", types.enum},
	{"replay_hash", types.md5_hash},
	{"is_valid", types.boolean},
	{"calculated", types.boolean},
	{"replay_uploaded", types.boolean},
	{"replay_size", types.size},
	{"creation_time", types.time},
	{"score", types.float},
	{"accuracy", types.float},
	{"max_combo", types.size},
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

table_declarations.sessions = {
	{"id", types.id},
	{"user_id", types.fk_id},
	{"active", types.boolean},
	{"ip", types.varchar_ip},
	{"created_at", types.time},
	{"updated_at", types.time},
	[[
		KEY `created_at` (`created_at`),
		KEY `user_id` (`user_id`),
		KEY `ip` (`ip`)
	]]
}

table_declarations.quick_logins = {
	{"id", types.id},
	{"ip", types.varchar_ip},
	{"key", types.md5_hash},
	{"next_update_time", types.time},
	{"user_id", types.fk_id},
	{"complete", types.boolean},
	[[
		KEY `ip` (`ip`),
		KEY `user_id` (`user_id`)
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
