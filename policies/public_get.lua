return {{
	rules = {require("rules.permit")},
	combine = require("abac.combine.permit_all_or_deny"),
}}
