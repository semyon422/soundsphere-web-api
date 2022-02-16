return function()

local date = require("date")
local Filehash = require("util.filehash")
local Storages = require("enums.storages")
local Formats = require("enums.formats")
local Inputmodes = require("enums.inputmodes")
local Roles = require("enums.roles")

-- https://gist.github.com/edubart/b08266fd44395c0d99a3bf464547b3f3/revisions
local old_db = require("mdb")("mysql_old")

local Users = require("models.users")
local Files = require("models.files")
local Notecharts = require("models.notecharts")
local Scores = require("models.scores")
local Community_users = require("models.community_users")

local notechart_c = require("controllers.notechart")

local function to_unit_time(s)
	return date.diff(date(s), date("Jan 01 1970 00:00:00")):spanseconds()
end

local user_ids_map = {}
local user_name_cache = {}
local users_old = old_db.select("* from users left join user_infos on users.id = user_infos.id")
for _, user in ipairs(users_old) do
	if user.name ~= "username" or user.score_count > 0 then
		local new_user = Users:find({email = user.email})
		if not new_user then
			local user_name = user.name
			while user_name_cache[user_name] do
				user_name = user.name .. math.random(1000, 9999)
			end
			user_name_cache[user_name] = true
			local created_at = to_unit_time(user.creation_timestamp)
			new_user = Users:create({
				name = user_name,
				email = user.email,
				password = user.password,
				latest_activity = to_unit_time(user.latest_activity),
				latest_score_submitted_at = to_unit_time(user.latest_score_submitted_at),
				created_at = created_at,
				is_banned = false,
				description = "",
				scores_count = 0,  -- user.score_count,
				notecharts_count = 0,  -- user.notechart_played_count,
				notes_count = 0,
				notecharts_upload_size = 0,  -- user.container_uploaded_count,
				replays_upload_size = 0,  -- user.container_uploaded_size,
				play_time = 0,
			})
			Community_users:create({
				community_id = 1,
				user_id = new_user.id,
				staff_user_id = new_user.id,
				role = Roles:for_db("user"),
				accepted = true,
				created_at = created_at,
				message = "",
			})
		end
		print("user", user.id, new_user.id)
		user_ids_map[user.id] = new_user.id
	end
end

local old_formats = {
	[1] = "ojn",
	[2] = "bme",
	[3] = "osu",
	[4] = "bml",
	[5] = "bms",
	[6] = "ksh",
	[7] = "qua",
	[8] = "pms",
	-- [9] = "mid",
	-- [10] = "sm",
}

local old_inputmodes = {
	[1] = "4key",
	[2] = "10key",
	[3] = "7key",
	[4] = "9key",
	[5] = "10key2scratch",
	[6] = "6key",
	-- [7] = "4bt2fx2laserleft2laserright",
	[8] = "7key1scratch",
	[9] = "14key2scratch",
	[10] = "5key1scratch",
	[11] = "18key",
	-- [13] = "10key1scratch",
	[14] = "14key",
	[15] = "8key",
	[16] = "5key",
	[17] = "12key",
	[18] = "16key",
	-- [19] = "7.021key",
	-- [20] = "7key1pedal1scratch",
	-- [21] = "5key1pedal1scratch",
	-- [22] = "7key2scratch",
	-- [23] = "",
	-- [24] = "6key1scratch",
	[25] = "3key",
	[26] = "1key",
	[27] = "24key",
	-- [28] = "21key",
	-- [29] = "27key",
}

local scores_old = old_db.select([[
	scores.*,
	notecharts.creation_time as nct, notecharts.index, notecharts.input_mode_id as nimi,
	containers.hash, containers.format_id, containers.size as csize
	from scores
	left join notecharts on scores.notechart_id = notecharts.id
	left join containers on notecharts.container_id = containers.id
]])
for _, score in ipairs(scores_old) do
	local inputmode = old_inputmodes[score.input_mode_id]
	local notechart_inputmode = old_inputmodes[score.nimi]
	local ext = old_formats[score.format_id]
	local new_user_id = user_ids_map[score.user_id]

	local allow = true
	if ext == "osu" then
		if #score.hash == 32 then
			local f = io.open("storages/notecharts/" .. score.hash, "r")
			if not f then
				allow = false
			else
				for line in f:lines() do
					if line:find("Mode:%s*3") then
						allow = true
						break
					elseif line:find("Metadata") then
						allow = false
						break
					end
				end
				f:close()
			end
		end
	end

	if
		allow and
		inputmode and
		notechart_inputmode and
		ext and
		new_user_id and
		score.is_valid == 1 and
		score.calculated == 1 and
		score.replay_uploaded == 1 and
		score.replay_size > 0 and
		score.score <= 35000 and
		score.accuracy <= 35000 and
		score.score ~= 0 and
		score.accuracy ~= 0
	then
		local user = Users:find(new_user_id)
		local hash_for_db = Filehash:for_db(score.hash)
		local replay_hash_for_db = Filehash:for_db(score.replay_hash)

		local notechart_file = Files:find({
			hash = hash_for_db
		})
		if not notechart_file then
			notechart_file = Files:create({
				hash = hash_for_db,
				name = "notechart." .. ext,
				format = Formats:for_db(Formats.extensions[ext]),
				storage = Storages:for_db("notecharts"),
				uploaded = true,
				size = score.csize,
				loaded = false,
				created_at = score.nct,
			})
			user.notecharts_upload_size = user.notecharts_upload_size + notechart_file.size
		end

		local notechart = Notecharts:find({
			file_id = notechart_file.id,
			index = score.index,
		})
		if not notechart then
			if ext ~= "ojn" then
				notechart = Notecharts:create({
					file_id = notechart_file.id,
					index = score.index,
					created_at = score.nct,
					scores_count = 0,
					inputmode = Inputmodes:for_db(notechart_inputmode),
					difficulty = 0,
					song_title = "",
					song_artist = "",
					difficulty_name = "",
					difficulty_creator = "",
				})
			else
				for i = 1, 3 do
					local new_notechart = Notecharts:create({
						file_id = notechart_file.id,
						index = i,
						created_at = score.nct,
						scores_count = 0,
						inputmode = Inputmodes:for_db(notechart_inputmode),
						difficulty = 0,
						song_title = "",
						song_artist = "",
						difficulty_name = "",
						difficulty_creator = "",
					})
					if i == score.index then
						notechart = new_notechart
					end
				end
			end
		end

		notechart.scores_count = notechart.scores_count + 1
		notechart:update("scores_count")

		local replay_file = Files:find({
			hash = replay_hash_for_db
		})
		if not replay_file then
			replay_file = Files:create({
				hash = replay_hash_for_db,
				name = "replay",
				format = Formats:for_db("undefined"),
				storage = Storages:for_db("replays"),
				uploaded = true,
				size = score.replay_size,
				loaded = false,
				created_at = score.creation_time,
			})
			user.replays_upload_size = user.replays_upload_size + replay_file.size
			local new_score = Scores:create({
				user_id = new_user_id,
				notechart_id = notechart.id,
				modifierset_id = 0,
				file_id = replay_file.id,
				inputmode = Inputmodes:for_db(inputmode),
				is_complete = false,
				is_valid = false,
				is_ranked = false,
				is_top = false,
				created_at = score.creation_time,
				score = 0,
				accuracy = 0,
				max_combo = 0,
				misses_count = 0,
				difficulty = 0,
				rating = 0,
			})
			user:update("notecharts_upload_size", "replays_upload_size")
			print(new_score.id)
		end

	end
end

end
