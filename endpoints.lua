local endpoints = {
	{
		name = "token",
		path = "/token"
	},
	{
		name = "users",
		path = "/users"
	},
	{
		name = "user",
		path = "/users/:user_id"
	},
	{
		name = "user_password",
		path = "/users/:user_id/password"
	},
	{
		name = "user_roles",
		path = "/users/:user_id/roles"
	},
	{
		name = "user_groups",
		path = "/users/:user_id/groups"
	},
	{
		name = "groups",
		path = "/groups"
	},
	{
		name = "group",
		path = "/groups/:group_id"
	},
	{
		name = "group_roles",
		path = "/groups/:group_id/roles"
	},
	{
		name = "group_users",
		path = "/groups/:group_id/users"
	},
	{
		name = "group_user",
		path = "/groups/:group_id/users/:user_id"
	},
	{
		name = "roles",
		path = "/roles"
	},
	{
		name = "role",
		path = "/roles/:role_id"
	},
	{
		name = "domains",
		path = "/domains"
	},
	{
		name = "domain",
		path = "/domains/:role_id"
	},
	{
		name = "communities",
		path = "/communities"
	},
	{
		name = "community",
		path = "/communities/:community_id"
	},
	{
		name = "community_users",
		path = "/communities/:community_id/users"
	},
	{
		name = "community_user",
		path = "/communities/:community_id/users/:user_id"
	},
	{
		name = "community_leaderboards",
		path = "/communities/:community_id/leaderboards"
	},
	{
		name = "community_leaderboard",
		path = "/communities/:community_id/leaderboards/:leaderboard_id"
	},
	{
		name = "leaderboards",
		path = "/leaderboards"
	},
	{
		name = "leaderboard",
		path = "/leaderboards/:leaderboard_id"
	},
	{
		name = "leaderboard_tables",
		path = "/leaderboards/:leaderboard_id/tables"
	},
	{
		name = "leaderboard_table",
		path = "/leaderboards/:leaderboard_id/tables/:table_id"
	},
	{
		name = "tables",
		path = "/tables"
	},
	{
		name = "table",
		path = "/tables/:table_id"
	},
}

return endpoints
