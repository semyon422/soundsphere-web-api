local Score = require("models.scores")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("score", function(self)
	local score_id = self.params.score_id
	if score_id then
		return Score:find(score_id)
	end
end)
