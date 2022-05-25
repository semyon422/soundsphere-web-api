local config = require("lapis.config")

-- lapis
config({"development", "production"}, {
	port = 8080,
	secret = "please-change-me",
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

config("production", {
	code_cache = "on",
})

-- app
config({"development", "production"}, {
	custom_error_page = true,
	recaptcha = {
		is_enabled = true,
		site_key = "",
		secret_key = "",
	},
	osu_api_key = "",
	is_ranked_check_enabled = true,
	is_register_enabled = true,
	is_login_enabled = true,
	is_login_captcha_enabled = true,
	is_score_submit_enabled = true,
	ip_register_delay = 3600 * 24 * 30,
	game_server_port = 8082,
	multiplayer_http_port = 9001,
})
