local users = {}

function users.response(response, request)
	local params = request.params
	return {
		draw = params.draw,
		recordsTotal = 1,
		recordsFiltered = 1,
		data = response.users,
	}
end

return users
