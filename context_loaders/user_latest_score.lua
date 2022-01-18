local Scores = require("models.scores")

local function load_score(user)
	local scores = Scores:select("where user_id = ? order by created_at desc limit 1", user.id)
	user.latest_score = scores[1]
end

return function(self)
	local context = self.context
	if context.user and not context.user.latest_score then
		load_score(context.user)
	end
	if context.session_user and not context.session_user.latest_score then
		load_score(context.session_user)
	end
	return true
end
