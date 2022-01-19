local config = require("lapis.config")

-- lapis
config({"development", "production"}, {
	port = 8090,
	secret = "",
	hmac_digest = "sha256",
	session_name = "lapis_session",
	code_cache = "off",
	mysql = {
		host = "127.0.0.1",
		user = "username",
		password = "password",
		database = "backend",
	},
})

config({"development", "production"}, {
	custom_error_page = true,
	recaptcha = {
		site_key = "",
		secret_key = "",
	},
	osu_api_key = "",
})

config("production", {
	code_cache = "on",
})
