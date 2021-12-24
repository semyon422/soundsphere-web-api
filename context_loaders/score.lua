local Score = require("models.scores")

return function(self)
	if self.context.score then return true end
	local score_id = self.params.score_id
	if score_id then
		self.context.score = Score:find(score_id)
	end
	return self.context.score
end
