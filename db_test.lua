local db = require("db")

local admin = {
	name = "admin",
	tag = "0000",
	email = "admin@admin",
	password = "password"
}

local lapisdb = require("lapis.db")
local bcrypt = require("bcrypt")

local Users = require("models.users")
local Communities = require("models.communities")
local Leaderboards = require("models.leaderboards")
local Community_users = require("models.community_users")
local Community_leaderboards = require("models.community_leaderboards")
local Difftables = require("models.difftables")
local Roles = require("enums.roles")
local leaderboard_c = require("controllers.leaderboard")

local db_test = {}

db_test.create = function()
	db.drop()
	db.create()

	local user = Users:create({
		name = admin.name,
		tag = admin.tag,
		email = admin.email,
		password = bcrypt.digest(admin.password, 5),
		latest_activity = 0,
		created_at = 0,
		description = "",
	})

	local community = Communities:create({
		name = "Community",
		alias = "???",
		link = "https://soundsphere.xyz",
		short_description = "Short descr.",
		description = "Long description",
		banner = "",
		is_public = true,
	})

	Community_users:create({
		community_id = community.id,
		user_id = user.id,
		sender_id = user.id,
		role = Roles:for_db("creator"),
		accepted = true,
		created_at = os.time(),
		message = "",
	})

	local difftable = Difftables:create({
		name = "Difficulty table",
		link = "https://soundsphere.xyz",
		description = "Description",
		owner_community_id = community.id,
	})

	local leaderboard = Leaderboards:create({
		name = "Leaderboard",
		description = "Description",
		banner = "",
	})

	Community_leaderboards:create({
		community_id = community.id,
		leaderboard_id = leaderboard.id,
		is_owner = true,
		sender_id = user.id,
		accepted = true,
		created_at = os.time(),
		message = "",
	})

	leaderboard_c.update_inputmodes(leaderboard.id, {"10key"})
	leaderboard_c.update_difftables(leaderboard.id, {difftable})
	leaderboard_c.update_requirements(leaderboard.id, {
		{
			name = "modifier",
			rule = "required",
			key = "Automap",
			value = "4 to 10",
		}
	})
end

return db_test
