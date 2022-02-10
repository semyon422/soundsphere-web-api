local Bypass_keys = require("models.bypass_keys")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("bypass_key", function(self)
	local key_id = self.params.key_id
	if key_id then
		return Bypass_keys:find(key_id)
	end
end)
