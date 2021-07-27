local endpoints = {
	{
		name = "token",
		path = "/token",
		methods = {"GET"},
	},
	{
		name = "users",
		path = "/users",
		methods = {"GET", "POST"},
	},
	{
		name = "user",
		path = "/users/:user_id",
		methods = {"GET", "PATCH", "DELETE"},
		context = {"user", "user_roles"},
	},
	{
		name = "user.roles",
		path = "/users/:user_id/roles",
		methods = {"GET"},
		context = {"user", "user_roles"},
	},
	{
		name = "user.groups",
		path = "/users/:user_id/groups",
		methods = {"GET"},
	},
	{
		name = "user.statistics",
		path = "/users/:user_id/statistics",
		methods = {"GET"},
		context = {"user"},
	},
	{
		name = "user.communities",
		path = "/users/:user_id/communities",
		methods = {"GET"},
	},
	{
		name = "user.leaderboards",
		path = "/users/:user_id/leaderboards",
		methods = {"GET"},
	},
	{
		name = "user.rivals",
		path = "/users/:user_id/rivals",
		methods = {"GET"},
	},
	{
		name = "user.rival",
		path = "/users/:user_id/rivals/:rival_id",
		methods = {"PUT", "DELETE"},
	},
	{
		name = "user.friends",
		path = "/users/:user_id/friends",
		methods = {"GET"},
	},
	{
		name = "user.friend",
		path = "/users/:user_id/friends/:friend_id",
		methods = {"PUT", "DELETE"},
	},
	{
		name = "groups",
		path = "/groups",
		methods = {"GET"},
	},
	{
		name = "group",
		path = "/groups/:group_id",
		methods = {"GET"},
		context = {"group"},
	},
	{
		name = "group.roles",
		path = "/groups/:group_id/roles",
		methods = {"GET"},
		context = {"group"},
	},
	{
		name = "group.users",
		path = "/groups/:group_id/users",
		methods = {"GET"},
	},
	{
		name = "group.user",
		path = "/groups/:group_id/users/:user_id",
		methods = {"PUT", "DELETE"},
		context = {"group", "user", "user_roles"},
	},
	{
		name = "roles",
		path = "/roles",
		methods = {"GET", "POST"},
	},
	{
		name = "role",
		path = "/roles/:role_id",
		methods = {"GET", "DELETE"},
	},
	{
		name = "communities",
		path = "/communities",
		methods = {"GET", "POST"},
	},
	{
		name = "community",
		path = "/communities/:community_id",
		methods = {"GET", "PATCH", "DELETE"},
		context = {"community"},
	},
	{
		name = "community.users",
		path = "/communities/:community_id/users",
		methods = {"GET"},
	},
	{
		name = "community.user",
		path = "/communities/:community_id/users/:user_id",
		methods = {"PUT", "DELETE"},
		context = {"community", "user", "user_roles"},
	},
	{
		name = "community.leaderboards",
		path = "/communities/:community_id/leaderboards",
		methods = {"GET"},
	},
	{
		name = "community.leaderboard",
		path = "/communities/:community_id/leaderboards/:leaderboard_id",
		context = {"community", "leaderboard"},
		methods = {"PUT", "DELETE"},
	},
	{
		name = "community.inputmodes",
		path = "/communities/:community_id/inputmodes",
		methods = {"GET"},
	},
	{
		name = "community.inputmode",
		path = "/communities/:community_id/inputmodes/:inputmode",
		context = {"community"},
		methods = {"PUT", "DELETE"},
	},
	{
		name = "leaderboards",
		path = "/leaderboards",
		methods = {"GET", "POST"},
	},
	{
		name = "leaderboard",
		path = "/leaderboards/:leaderboard_id",
		context = {"leaderboard"},
		methods = {"GET", "PATCH", "DELETE"},
	},
	{
		name = "leaderboard.tables",
		path = "/leaderboards/:leaderboard_id/tables",
		methods = {"GET"},
	},
	{
		name = "leaderboard.table",
		path = "/leaderboards/:leaderboard_id/tables/:table_id",
		context = {"leaderboard", "table"},
		methods = {"PUT", "DELETE"},
	},
	{
		name = "leaderboard.communities",
		path = "/leaderboards/:leaderboard_id/communities",
		methods = {"GET"},
	},
	{
		name = "leaderboard.community",
		path = "/leaderboards/:leaderboard_id/communities/:community_id",
		methods = {"PUT", "DELETE"},
	},
	{
		name = "leaderboard.users",
		path = "/leaderboards/:leaderboard_id/users",
		methods = {"GET"},
	},
	{
		name = "leaderboard.user",
		path = "/leaderboards/:leaderboard_id/users/:user_id",
		methods = {"PUT", "DELETE"},
	},
	{
		name = "tables",
		path = "/tables",
		methods = {"GET", "POST"},
	},
	{
		name = "table",
		path = "/tables/:table_id",
		methods = {"GET", "PATCH", "DELETE"},
		context = {"table"},
	},
	{
		name = "table.communities",
		path = "/tables/:table_id/communities",
		methods = {"GET"},
		context = {"table"},
	},
	{
		name = "table.leaderboards",
		path = "/tables/:table_id/leaderboards",
		methods = {"GET"},
		context = {"table"},
	},
	{
		name = "table.notecharts",
		path = "/tables/:table_id/notecharts",
		methods = {"GET"},
		context = {"table"},
	},
	{
		name = "notecharts",
		path = "/notecharts",
		methods = {"GET", "POST"},
	},
	{
		name = "notechart",
		path = "/notecharts/:notechart_id",
		methods = {"GET"},
	},
	{
		name = "notechart.scores",
		path = "/notecharts/:notechart_id/scores",
		methods = {"GET"},
	},
	{
		name = "scores",
		path = "/scores",
		methods = {"GET", "POST"},
	},
	{
		name = "score",
		path = "/scores/:score_id",
		methods = {"GET", "DELETE"},
	},
}

return endpoints
