local json = require("json")
local lapisdb = require("lapis.db")
local bcrypt = require("bcrypt")
local base64 = require("base64")

local fetch = require("tests.fetch")

local admin = {
	name = "admin",
	tag = "0000",
	email = "admin@admin",
	password = "password"
}

local function user_add()
	return lapisdb.query(
		"INSERT INTO `users` (`name`, `tag`, `email`, `password`) VALUES (?, ?, ?, ?);",
		admin.name,
		admin.tag,
		admin.email,
		bcrypt.digest(admin.password, 5)
	)
end

local coro

local function users_get()
	local users
	fetch(
		"/api/users",
		{
			method = "GET"
		},
		function(res)
			p(res)
			local jres = json.decode(res.body)
			users = jres.users
			coroutine.resume(coro)
		end
	)
	coroutine.yield()
	return users
end

local function user_get(user_id)
	local user
	fetch(
		"/api/users/" .. user_id,
		{
			method = "GET"
		},
		function(res)
			p(res)
			local jres = json.decode(res.body)
			user = jres.user
			coroutine.resume(coro)
		end
	)
	coroutine.yield()
	return user
end

local function token_get(email, password)
	local token
	p(base64.encode(email .. ":" .. password))
	fetch(
		"/api/token",
		{
			method = "GET",
			headers = {Authorization = "Basic " .. base64.encode(email .. ":" .. password)}
		},
		function(res)
			p(res)
			local jres = json.decode(res.body)
			token = jres.token
			coroutine.resume(coro)
		end
	)
	coroutine.yield()
	return token
end

coro = coroutine.create(function()
	user_add()
	local users = users_get()
	assert(#users == 1)
	local token = token_get(admin.email, admin.password)
	p(user_get(1))
	p(token)
end)

coroutine.resume(coro)
