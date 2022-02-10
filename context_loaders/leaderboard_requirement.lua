local Leaderboard_requirements = require("models.leaderboard_requirements")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("leaderboard_requirement", function(self)
	local requirement_id = self.params.requirement_id
	if requirement_id then
		return Leaderboard_requirements:find(requirement_id)
	end
end)
