local endpoints = {
	{
		name = "token",
		path = "/token",
	},
	{
		name = "users",
		path = "/users",
	},
	{
		name = "user",
		path = "/users/:user_id",
		context = {"user", "user_roles"},
	},
	{
		name = "user.roles",
		path = "/users/:user_id/roles",
		context = {"user", "user_roles"},
	},
	{
		name = "user.groups",
		path = "/users/:user_id/groups",
	},
	{
		name = "user.statistics",
		path = "/users/:user_id/statistics",
		context = {"user"},
	},
	{
		name = "user.communities",
		path = "/users/:user_id/communities",
	},
	{
		name = "user.leaderboards",
		path = "/users/:user_id/leaderboards",
	},
	{
		name = "groups",
		path = "/groups",
	},
	{
		name = "group",
		path = "/groups/:group_id",
		context = {"group"},
	},
	{
		name = "group.roles",
		path = "/groups/:group_id/roles",
		context = {"group"},
	},
	{
		name = "group.users",
		path = "/groups/:group_id/users",
	},
	{
		name = "group.user",
		path = "/groups/:group_id/users/:user_id",
		context = {"group", "user", "user_roles"},
	},
	{
		name = "roles",
		path = "/roles",
	},
	{
		name = "role",
		path = "/roles/:role_id",
	},
	{
		name = "communities",
		path = "/communities",
	},
	{
		name = "community",
		path = "/communities/:community_id",
		context = {"community"},
	},
	{
		name = "community.users",
		path = "/communities/:community_id/users",
	},
	{
		name = "community.user",
		path = "/communities/:community_id/users/:user_id",
		context = {"community", "user", "user_roles"},
	},
	{
		name = "community.leaderboards",
		path = "/communities/:community_id/leaderboards",
	},
	{
		name = "community.leaderboard",
		path = "/communities/:community_id/leaderboards/:leaderboard_id",
		context = {"community", "leaderboard"},
	},
	{
		name = "community.inputmodes",
		path = "/communities/:community_id/inputmodes",
	},
	{
		name = "community.inputmode",
		path = "/communities/:community_id/inputmodes/:inputmode_id",
		context = {"community", "inputmode"},
	},
	{
		name = "leaderboards",
		path = "/leaderboards",
	},
	{
		name = "leaderboard",
		path = "/leaderboards/:leaderboard_id",
		context = {"leaderboard"},
	},
	{
		name = "leaderboard.tables",
		path = "/leaderboards/:leaderboard_id/tables",
	},
	{
		name = "leaderboard.table",
		path = "/leaderboards/:leaderboard_id/tables/:table_id",
		context = {"leaderboard", "table"},
	},
	{
		name = "leaderboard.communities",
		path = "/leaderboards/:leaderboard_id/communities",
	},
	{
		name = "leaderboard.community",
		path = "/leaderboards/:leaderboard_id/communities/:community_id",
	},
	{
		name = "leaderboard.users",
		path = "/leaderboards/:leaderboard_id/users",
	},
	{
		name = "leaderboard.user",
		path = "/leaderboards/:leaderboard_id/users/:user_id",
	},
	{
		name = "tables",
		path = "/tables",
	},
	{
		name = "table",
		path = "/tables/:table_id",
		context = {"table"},
	},
	{
		name = "table.communities",
		path = "/tables/:table_id/communities",
		context = {"table"},
	},
	{
		name = "table.leaderboards",
		path = "/tables/:table_id/leaderboards",
		context = {"table"},
	},
	{
		name = "table.notecharts",
		path = "/tables/:table_id/notecharts",
		context = {"table"},
	},
	{
		name = "notecharts",
		path = "/notecharts",
	},
	{
		name = "notechart",
		path = "/notecharts/:notechart_id",
	},
	{
		name = "notechart.scores",
		path = "/notecharts/:notechart_id/scores",
	},
	{
		name = "scores",
		path = "/scores",
	},
	{
		name = "score",
		path = "/scores/:score_id",
	},
}

return endpoints
