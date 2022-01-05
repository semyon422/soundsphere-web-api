local Model = require("lapis.db.model").Model
local Modifiers = require("enums.modifiers")

local Modifiersets = Model:extend("modifiersets")

Modifiersets.decode = function(self, encodedConfig)
	local config = {}
	for modifierId, modifierData in encodedConfig:gmatch("(%d+):([^;]+)") do
		local version, value = modifierData:match("^(%d+),(.+)$")
		table.insert(config, {
			name = Modifiers:to_name(tonumber(modifierId)),
			version = tonumber(version),
			value = self:decodeValue(value),
		})
	end
	return config
end

Modifiersets.decodeValue = function(self, s)
	if s:find(",") then
		s = s:match("^(.-),.+$")
	end
	if s == "true" or s == "false" then
		return s == "true"
	elseif tonumber(s) then
		return tonumber(s)
	end
	return s
end

return Modifiersets
