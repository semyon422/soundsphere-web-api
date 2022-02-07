local User_inputmodes = require("models.user_inputmodes")
local Inputmodes = require("enums.inputmodes")
local Controller = require("Controller")
local util = require("util")

local user_inputmodes_c = Controller:new()

user_inputmodes_c.path = "/users/:user_id[%d]/inputmodes"
user_inputmodes_c.methods = {"GET", "PATCH"}

user_inputmodes_c.update_inputmodes = function(user_id, inputmodes)
	if not inputmodes then
		return
	end

	local user_inputmodes = User_inputmodes:find_all({user_id}, "user_id")

	local new_inputmodes, old_inputmodes = util.array_update(
		inputmodes,
		user_inputmodes,
		function(li) return Inputmodes:for_db(li.inputmode) end,
		function(li) return li.inputmode end
	)

	local db = User_inputmodes.db
	if #old_inputmodes > 0 then
		db.delete("user_inputmodes", {inputmode = db.list(old_inputmodes)})
	end
	for _, inputmode in ipairs(new_inputmodes) do
		db.insert("user_inputmodes", {
			user_id = user_id,
			inputmode = inputmode,
		})
	end
end

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

user_inputmodes_c.context.PUT = {"request_session", "user", "session_user"}
user_inputmodes_c.policies.PUT = {{"authed", "user_profile"}}
user_inputmodes_c.validations.PATCH = {
	{"user_inputmodes", exists = true, type = "table", param_type = "body"}
}
user_inputmodes_c.PATCH = function(self)
	local params = self.params

	user_inputmodes_c.update_inputmodes(params.user_id, params.user_inputmodes)
	local user_inputmodes = User_inputmodes:find_all({params.user_id}, "user_id")

	util.recursive_to_name(user_inputmodes)

	return {json = {user_inputmodes = user_inputmodes}}
end

return user_inputmodes_c
