local User_rivals = require("models.user_rivals")
local preload = require("lapis.db.model").preload

local user_rivals_c = {}

user_rivals_c.GET = function(params)
	local rivals = {}
	local user_rivals = User_rivals:find_all({params.user_id}, "user_id")
	preload(user_rivals, "rival")
	for _, user_rival in ipairs(user_rivals) do
		local rival = user_rival.rival
		table.insert(rivals, {
			id = rival.id,
			name = rival.name,
			tag = rival.tag,
			latest_activity = rival.latest_activity,
		})
	end

	local count = User_rivals:count()

	return 200, {
		total = count,
		filtered = count,
		rivals = rivals
	}
end

return user_rivals_c
