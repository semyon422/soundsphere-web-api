local PolicySet = require("abac.PolicySet")

local policy_set = PolicySet:new()

policy_set.policies = {
	require("policy_sets.leaderboard"),
	require("policy_sets.leaderboard.table"),
	require("policy_sets.leaderboard.tables"),
	require("policy_sets.leaderboards"),
	require("policy_sets.role"),
	require("policy_sets.roles"),
	require("policy_sets.table"),
	require("policy_sets.tables"),
	require("policy_sets.token"),
	require("policy_sets.user"),
	require("policy_sets.user.groups"),
	require("policy_sets.user.password"),
	require("policy_sets.user.roles"),
	require("policy_sets.user.statistics"),
	require("policy_sets.users"),
	require("policy_sets.communities"),
	require("policy_sets.community"),
	require("policy_sets.community.leaderboard"),
	require("policy_sets.community.leaderboards"),
	require("policy_sets.community.user"),
	require("policy_sets.community.users"),
	require("policy_sets.domain"),
	require("policy_sets.domains"),
	require("policy_sets.group"),
	require("policy_sets.group.roles"),
	require("policy_sets.group.user"),
	require("policy_sets.group.users"),
	require("policy_sets.groups"),
	require("policy_sets.container"),
	require("policy_sets.containers"),
	require("policy_sets.format"),
	require("policy_sets.formats"),
	require("policy_sets.input_mode"),
	require("policy_sets.input_modes"),
	require("policy_sets.modifier"),
	require("policy_sets.modifiers"),
	require("policy_sets.notechart"),
	require("policy_sets.notecharts"),
	require("policy_sets.score"),
	require("policy_sets.scores"),
}

policy_set.policy_combine_algorithm = require("abac.combine.only_one_applicable")

policy_set.context_loaders = {
    require("context_loaders.token_user"),
    require("context_loaders.user_roles"),
}

return policy_set
