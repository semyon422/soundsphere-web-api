local Bypass_keys = require("models.bypass_keys")

return function(self)
	if self.context.bypass_key then return true end
	local key_id = self.params.key_id
	if key_id then
		self.context.bypass_key = Bypass_keys:find(key_id)
	end
	return self.context.bypass_key
end
