return {{
	rules = {require("rules.permit")},
	rule_combine_algorithm = require("abac.combine.permit_all_or_deny"),
}}
