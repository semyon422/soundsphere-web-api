local lapis = require("lapis")
local util = require("lapis.util")
local respond_to = require("lapis.application").respond_to
local json_params = require("lapis.application").json_params
local app = lapis.Application()

local secret = require("secret")

local PolicyEnforcementPoint = require("abac.PolicyEnforcementPoint")

local pep = PolicyEnforcementPoint:new()

local token_auth = require("auth.token")
local basic_auth = require("auth.basic")

local function copy_table(src, dst)
	if not src then
		return
	end
	for k, v in pairs(src) do
		dst[k] = v
	end
end

local function get_context(self, controller)
	copy_table(basic_auth(self.req.headers.Authorization), self.params)
	copy_table(token_auth(self.req.headers.Authorization), self.session)

	self.context = {
		ip = self.req.headers["X-Real-IP"]
	}

	if controller.context then
		for _, name in ipairs(controller.context) do
			local context_loader = require("context_loaders." .. name)
			context_loader:load_context(self)
		end
	end

	return self.context
end

local function json_respond_to(path, respond)
	return app:match(path, json_params(respond_to({
		GET = respond,
		POST = respond,
		PUT = respond,
		PATCH = respond,
		DELETE = respond,
	})))
end

local function get_permited_methods(self, controller)
	local methods = {}
	for _, method in ipairs(controller.methods) do
		local policies = controller.policies[method]
		if pep:check(self, policies) then
			table.insert(methods, method)
		end
	end
	return methods
end

local function includes(list, item)
	for _, included_item in ipairs(list) do
		if item == included_item then
			return true
		end
	end
end

local function route_api(controller)
	json_respond_to("/api" .. controller.path, function(self)
		local context = get_context(self, controller)
		local methods = get_permited_methods(self, controller)
		local method = self.req.method
		local code, response
		if includes(methods, method) and controller[method] then
			code, response = controller[method](self)
		else
			code, response = 500, {}
		end
		response.methods = methods
		return {json = response, status = code}
	end)
	json_respond_to("/ac" .. controller.path, function(self)
		local context = get_context(self, controller)
		return {json = {methods = get_permited_methods(self, controller)}, status = 200}
	end)
end

local function route_api_debug(controller)
	return json_respond_to("/api_debug" .. controller.path, function(self)
		local context = get_context(self, controller)
		local method = self.req.method
		if controller[method] then
			local code, response = controller[method](self)
			return {json = response, status = code}
		else
			return {json = {}, status = 200}
		end
	end)
end

local function route_datatables(controller, name)
	local ok, datatable = pcall(require, "datatables." .. name)
	if not ok then
		return
	end
	return json_respond_to("/dt" .. controller.path, function(self)
		local context = get_context(self, controller)
		if pep:check(self, controller.policies.GET) and controller.GET then
			local params = self.params
			if tonumber(params.length) == -1 then
				params.get_all = true
			else
				params.page_num = math.floor((params.start or 0) / (params.length or 1)) + 1
				params.per_page = params.length
			end
			if type(params.search) == "table" then
				params.search = params.search.value
			end
			if datatable.params then
				datatable.params(self)
			end
			local code, response = controller.GET(self)
			return {json = datatable.response(response, self), status = code}
		else
			return {json = {decision = context.decision}, status = 200}
		end
	end)
end

-- permit, deny, not_applicable, indeterminate

local names, paths = {}, {}
for _, name in ipairs(require("endpoints")) do
	names[name] = names[name] and error(name) or name
	local controller = require("controllers." .. name)
	local path = controller.path
	if path then
		names[path] = names[path] and error(names[path] .. " " .. name .. " " .. path) or name
		route_api(controller)
		route_api_debug(controller)
		route_datatables(controller, name)
	end
end

app:match("/api/create_db", function(self)
	local db = require("db")
	db.drop()
	db.create()

	local admin = {
		name = "admin",
		tag = "0000",
		email = "admin@admin",
		password = "password"
	}

	local lapisdb = require("lapis.db")
	local bcrypt = require("bcrypt")

	local Users = require("models.users")
	local Communities = require("models.communities")
	local Leaderboards = require("models.leaderboards")
	local Community_users = require("models.community_users")
	local Community_leaderboards = require("models.community_leaderboards")
	local Difftables = require("models.difftables")
	local Roles = require("enums.roles")
	local leaderboard_c = require("controllers.leaderboard")

	local user = Users:create({
		name = admin.name,
		tag = admin.tag,
		email = admin.email,
		password = bcrypt.digest(admin.password, 5),
		latest_activity = 0,
		creation_time = 0,
		description = "",
	})

	local community = Communities:create({
		name = "Community",
		alias = "???",
		link = "https://soundsphere.xyz",
		short_description = "Short descr.",
		description = "Long description",
		banner = "",
		is_public = true,
	})

	Community_users:create({
		community_id = community.id,
		user_id = user.id,
		sender_id = user.id,
		role = Roles:for_db("creator"),
		accepted = true,
		created_at = os.time(),
		message = "",
	})

	local difftable = Difftables:create({
		name = "Difficulty table",
		link = "https://soundsphere.xyz",
		description = "Description",
		owner_community_id = community.id,
	})

	local leaderboard = Leaderboards:create({
		name = "Leaderboard",
		description = "Description",
		banner = "",
	})

	Community_leaderboards:create({
		community_id = community.id,
		leaderboard_id = leaderboard.id,
		is_owner = true,
		sender_id = user.id,
		accepted = true,
		created_at = os.time(),
		message = "",
	})

	leaderboard_c.update_inputmodes(leaderboard.id, {"10key"})
	leaderboard_c.update_difftables(leaderboard.id, {difftable})
	leaderboard_c.update_modifiers(leaderboard.id, {{name = "Automap", value = "4 to 10", rule = "required"}})
end)

function app:handle_error(err, trace)
	if secret.custom_error_page then
		return {json = {
			err = err,
			trace = trace,
		}, status = 500}
	else
		return lapis.Application.handle_error(self, err, trace)
	end
end

app:match("/api/test_session", json_params(function(self)
	self.session.user = "semyon422"
	return {json = self.session}
end))

return app
