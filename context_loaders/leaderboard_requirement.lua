local Leaderboard_requirements = require("models.leaderboard_requirements")

return function(self)
	if self.context.leaderboard_requirement then return true end
	local requirement_id = self.params.requirement_id
	if requirement_id then
		self.context.leaderboard_requirement = Leaderboard_requirements:find(requirement_id)
	end
	return self.context.leaderboard_requirement
end
