local preload = require("lapis.db.model").preload
local users = require("models.users")
local bcrypt = require("bcrypt")

local users_c = {}

users_c.GET = function(params)
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = users:paginated(
		"order by id asc",
		{
			per_page = per_page,
			prepare_results = function(user_entries)
				-- preload(user_entries, "user_groups")
				return user_entries
			end
		}
	)
	local db_user_entries = paginator:get_page(page_num)

	local user_entries = {}
	for _, db_user_entry in ipairs(db_user_entries) do
		table.insert(
			user_entries,
			{
				id = db_user_entry.id,
				name = db_user_entry.name,
				tag = db_user_entry.tag,
				latest_activity = db_user_entry.latest_activity,
				user_groups = db_user_entry.user_groups,
			}
		)
	end

	local count = users:count()

	return 200, {
		total = count,
		filtered = count,
		users = user_entries
	}
end

local function register(name, email, password)
	if not name then
		return false, "Invalid name"
	elseif not email then
		return false, "Invalid email"
	elseif not password then
		return false, "Invalid password"
	end

	email = email:lower()
	local digest = bcrypt.digest(password, 5)

	local user_entry = users:find({email = email})

	if user_entry then
		return false, "This email is already registered"
	end

	user_entry = users:create({
		name = name,
		tag = ("%4d"):format(math.random(1, 9999)),
		email = email,
		password = digest,
	})

	return user_entry
end

users_c.POST = function(params)
	local db_user_entry, err = register(params.name, params.email, params.password)

	if db_user_entry then
		return 200, {
			user = {
				id = db_user_entry.id,
				name = db_user_entry.name,
				tag = db_user_entry.tag
			}
		}
	end

	return 400, {error = err}
end

return users_c
