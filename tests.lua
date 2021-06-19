local http = require("http")
local json = require("json")
local lapisdb = require("lapis.db")
local bcrypt = require("bcrypt")
local base64 = require("base64")

local host = "127.0.0.1"
local port = 8081

local function fetch(path, options, callback)
	options.host = host
	options.port = port
	options.path = path
	http.request(options, function(res)
		res:on("data", function(chunk)
			callback({
				code = res.statusCode,
				body = chunk
			})
		end)
	end):done()
end

local db = require("db")
db.drop()
db.create()

local admin = {
	name = "admin",
	tag = "0000",
	email = "admin@soundsphere.xyz",
	password = "password"
}
lapisdb.query(
	"INSERT INTO `users` (`name`, `tag`, `email`, `password`) VALUES (?, ?, ?, ?);",
	admin.name,
	admin.tag,
	admin.email,
	bcrypt.digest(admin.password, 5)
)

fetch(
	"/api/users",
	{
		method = "GET"
	},
	function(res)
		local jres = json.decode(res.body)
		p(jres)
	end
)

fetch(
	"/api/token",
	{
		method = "GET",
		headers = {Authorization = "Basic " .. base64.encode(admin.email .. ":" .. admin.password)}
	},
	function(res)
		local jres = json.decode(res.body)
		p(jres)
	end
)
