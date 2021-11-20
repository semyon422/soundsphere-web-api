local users = {}

function users.params(request)
	local params = request.params
	params.page_num = math.floor(params.start / params.length) + 1
	params.per_page = params.length
	return params
end

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
