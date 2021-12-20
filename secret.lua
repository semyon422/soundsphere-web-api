local secret = {}

secret.environment = "development"
secret.port = 8081

secret.mysql_host = "127.0.0.1"
secret.mysql_user = "username"
secret.mysql_password = "password"
secret.mysql_database = "backend"

secret.token_key = "token_key"

secret.custom_error_page = true

return secret

