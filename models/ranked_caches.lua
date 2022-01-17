local Model = require("lapis.db.model").Model
local Formats = require("enums.formats")
local Filehash = require("util.filehash")
local toboolean = require("util.toboolean")
local http = require("lapis.nginx.http")
local util = require("lapis.util")
local secret = require("secret")

local Ranked_caches = Model:extend(
	"ranked_caches",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"}
		},
		url_params = function(self, req, ...)
			return "ranked_cache", {ranked_cache_id = self.id}, ...
		end,
	}
)

local function to_name(self)
	self.hash = Filehash:to_name(self.hash)
	self.format = Formats:to_name(self.format)
	return self
end

local function for_db(self)
	self.hash = Filehash:for_db(self.hash)
	self.format = Formats:for_db(self.format)
	return self
end

function Ranked_caches.to_name(self, row) return to_name(row) end
function Ranked_caches.for_db(self, row) return for_db(row) end

local _load = Ranked_caches.load
function Ranked_caches:load(row)
	row.exists = toboolean(row.exists)
	row.ranked = toboolean(row.ranked)
	row.created_at = tonumber(row.created_at)
	row.expires_at = tonumber(row.expires_at)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

--[[
	curl
	-d "chartkey=Xmd5_hash&start=0&length=1&top=true"
	-H "Content-Type: application/x-www-form-urlencoded"
	-X POST https://etternaonline.com/valid_score/chartOverallScores

	https://osu.ppy.sh/api/get_beatmaps?k=api_key&h=md5_hash&m=3&limit=1"

	https://api.quavergame.com/v1/maps/:md5_hash
]]

local function check_etterna(hash)
	local body, status_code, headers = http.simple({
		url = "https://etternaonline.com/valid_score/chartOverallScores",
		method = "POST",
		body = {
			chartkey = "X" .. hash,
			start = 0,
			length = 1,
			top = true,
		}
	})

	if status_code ~= 200 then
		return false
	end

	return true, util.from_json(body).recordsTotal > 0
end

local function check_osu(hash)
	local body, status_code, headers = http.simple(
		"https://osu.ppy.sh/api/get_beatmaps?" ..
		util.encode_query_string({
			k = secret.osu_api_key,
			h = hash,
			m = 3,
			limit = 1,
		})
	)

	if status_code ~= 200 then
		return false
	end

	local beatmaps = util.from_json(body)
	if #beatmaps == 0 then
		return false
	end

	-- 4 = loved, 3 = qualified, 2 = approved, 1 = ranked, 0 = pending, -1 = WIP, -2 = graveyard
	local approved = tonumber(beatmaps[1].approved)
	return true, approved == 4 or approved == 1
end

local function check_quaver(hash)
	local body, status_code, headers = http.simple(
		"https://api.quavergame.com/v1/maps/" .. hash
	)

	if status_code ~= 200 then
		return false
	end

	local ranked_status = util.from_json(body).map.ranked_status
	return true, ranked_status == 2
end

function Ranked_caches:check(hash, format)
	if format == "osu" then
		return check_osu(hash)
	elseif format == "stepmania" then
		return check_etterna(hash)
	elseif format == "quaver" then
		return check_quaver(hash)
	end
end

return Ranked_caches
