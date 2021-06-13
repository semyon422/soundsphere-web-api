local config = require("lapis.config")
local secret = require("secret")

config(secret.environment, {
	port = secret.port,
	mysql = {
		host = secret.mysql_host,
		user = secret.mysql_user,
		password = secret.mysql_password,
		database = secret.mysql_database
	},
	session_name = secret.session_name,
	secret = secret.session_secret
})

