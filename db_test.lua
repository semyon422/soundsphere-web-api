require("package_path")

local db = require("db")
local Difficulty_calculators = require("enums.difficulty_calculators")
local Rating_calculators = require("enums.rating_calculators")
local Combiners = require("enums.combiners")

local admin = {
	name = "admin",
	email = "admin@admin",
	password = "password"
}

local lapisdb = require("lapis.db")
local bcrypt = require("bcrypt")

local Users = require("models.users")
local User_roles = require("models.user_roles")
local Communities = require("models.communities")
local Leaderboards = require("models.leaderboards")
local Community_users = require("models.community_users")
local Community_leaderboards = require("models.community_leaderboards")
local Community_changes = require("models.community_changes")
local Difftables = require("models.difftables")
local Roles = require("enums.roles")
local leaderboard_c = require("controllers.leaderboard")

local db_test = {}

db_test.create = function()
	db.drop()
	db.create()

	local user = Users:create({
		name = admin.name,
		email = admin.email,
		password = bcrypt.digest(admin.password, 10),
		latest_activity = 0,
		latest_score_submitted_at = 0,
		created_at = 0,
		description = "",
		scores_count = 0,
		notecharts_count = 0,
		play_time = 0,
	})
	User_roles:create({
		user_id = user.id,
		role = Roles:for_db("creator"),
		expires_at = 4102444800,
		total_time = 4102444800 - os.time(),
	})

	local community = Communities:create({
		name = "Community",
		alias = "???",
		link = "https://soundsphere.xyz",
		short_description = "Short descr.",
		description = "Long description",
		banner = "",
		is_public = false,
	})

	Community_users:create({
		community_id = community.id,
		user_id = user.id,
		staff_user_id = user.id,
		role = Roles:for_db("creator"),
		accepted = true,
		created_at = os.time(),
		message = "",
	})

	local difftable_osu = Difftables:create({
		name = "osu!mania ranked and loved",
		link = "",
		description = "Description",
		symbol = "",
		owner_community_id = community.id,
	})
	Community_changes:add_change(user.id, community.id, "create", difftable_osu)

	local difftable_quaver = Difftables:create({
		name = "Quaver ranked",
		link = "",
		description = "Description",
		symbol = "",
		owner_community_id = community.id,
	})
	Community_changes:add_change(user.id, community.id, "create", difftable_quaver)

	local leaderboard = Leaderboards:create({
		name = "Global",
		description = "All uploaded notecharts are ranked",
		banner = "",
		owner_community_id = community.id,
		difficulty_calculator = Difficulty_calculators:for_db("enps"),
		rating_calculator = Rating_calculators:for_db("acc_inv_erf"),
		scores_combiner = Combiners:for_db("average"),
		communities_combiner = Combiners:for_db("additive"),
		difficulty_calculator_config = 0,
		rating_calculator_config = 0,
		scores_combiner_count = 20,
		communities_combiner_count = 100,
	})
	Community_changes:add_change(user.id, community.id, "create", leaderboard)

	Community_leaderboards:create({
		community_id = community.id,
		leaderboard_id = leaderboard.id,
		user_id = user.id,
		accepted = true,
		created_at = os.time(),
		message = "",
	})

	local leaderboard = Leaderboards:create({
		name = "osu!mania and Quaver",
		description = "Ranked and loved",
		banner = "",
		owner_community_id = community.id,
		difficulty_calculator = Difficulty_calculators:for_db("enps"),
		rating_calculator = Rating_calculators:for_db("acc_inv_erf"),
		scores_combiner = Combiners:for_db("average"),
		communities_combiner = Combiners:for_db("additive"),
		difficulty_calculator_config = 0,
		rating_calculator_config = 0,
		scores_combiner_count = 20,
		communities_combiner_count = 100,
	})
	Community_changes:add_change(user.id, community.id, "create", leaderboard)

	Community_leaderboards:create({
		community_id = community.id,
		leaderboard_id = leaderboard.id,
		user_id = user.id,
		accepted = true,
		created_at = os.time(),
		message = "",
	})

	leaderboard_c.update_difftables(leaderboard.id, {
		{difftable_id = difftable_osu.id},
		{difftable_id = difftable_quaver.id},
	})


	local inputmodes = {
		"1key",
		"2key",
		"3key",
		"4key",
		"5key",
		"6key",
		"7key",
		"8key",
		"9key",
		"10key",
		"12key",
		"14key",
		"16key",
		"18key",
		"20key",
		"5key1scratch",
		"7key1scratch",
		"10key2scratch",
		"14key2scratch",
		"24key",
		"26key",
		"48key",
		"88key",
	}

	for _, inputmode in ipairs(inputmodes) do
		local leaderboard = Leaderboards:create({
			name = inputmode,
			description = "",
			banner = "",
			owner_community_id = community.id,
			difficulty_calculator = Difficulty_calculators:for_db("enps"),
			rating_calculator = Rating_calculators:for_db("acc_inv_erf"),
			scores_combiner = Combiners:for_db("average"),
			communities_combiner = Combiners:for_db("additive"),
			difficulty_calculator_config = 0,
			rating_calculator_config = 0,
			scores_combiner_count = 20,
			communities_combiner_count = 100,
		})
		Community_changes:add_change(user.id, community.id, "create", leaderboard)

		Community_leaderboards:create({
			community_id = community.id,
			leaderboard_id = leaderboard.id,
			user_id = user.id,
			accepted = true,
			created_at = os.time(),
			message = "",
		})
		leaderboard_c.update_inputmodes(leaderboard.id, {{inputmode = inputmode}})
	end
end

return db_test
