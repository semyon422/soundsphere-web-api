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
		name = "user.password",
		path = "/users/:user_id/password"
	},
	{
		name = "user.roles",
		path = "/users/:user_id/roles"
	},
	{
		name = "user.groups",
		path = "/users/:user_id/groups"
	},
	{
		name = "user.statistics",
		path = "/users/:user_id/statistics"
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
		name = "group.roles",
		path = "/groups/:group_id/roles"
	},
	{
		name = "group.users",
		path = "/groups/:group_id/users"
	},
	{
		name = "group.user",
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
		name = "communities",
		path = "/communities"
	},
	{
		name = "community",
		path = "/communities/:community_id"
	},
	{
		name = "community.users",
		path = "/communities/:community_id/users"
	},
	{
		name = "community.user",
		path = "/communities/:community_id/users/:user_id"
	},
	{
		name = "community.leaderboards",
		path = "/communities/:community_id/leaderboards"
	},
	{
		name = "community.leaderboard",
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
		name = "leaderboard.tables",
		path = "/leaderboards/:leaderboard_id/tables"
	},
	{
		name = "leaderboard.table",
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
	{
		name = "notecharts",
		path = "/notecharts"
	},
	{
		name = "notechart",
		path = "/notecharts/:notechart_id"
	},
	{
		name = "scores",
		path = "/scores"
	},
	{
		name = "score",
		path = "/scores/:score_id"
	},
}

return endpoints
