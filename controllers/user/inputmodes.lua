local User_inputmodes = require("models.user_inputmodes")
local Controller = require("Controller")
local util = require("util")

local user_inputmodes_c = Controller:new()

user_inputmodes_c.path = "/users/:user_id[%d]/inputmodes"
user_inputmodes_c.methods = {"GET"}

user_inputmodes_c.policies.GET = {{"permit"}}
user_inputmodes_c.validations.GET = {
	require("validations.no_data"),
}
user_inputmodes_c.GET = function(self)
	local params = self.params
    local user_inputmodes = User_inputmodes:find_all({params.user_id}, "user_id")

	if params.no_data then
		return {json = {
			total = #user_inputmodes,
			filtered = #user_inputmodes,
		}}
	end

	util.recursive_to_name(user_inputmodes)

	return {json = {user_inputmodes = user_inputmodes}}
end

return user_inputmodes_c
