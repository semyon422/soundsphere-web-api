local leaderboards = {}

function leaderboards.params(request)
	local params = request.params
	params.page_num = math.floor(params.start / params.length) + 1
	params.per_page = params.length
	return params
end

function leaderboards.response(response, request)
	local params = request.params
	return {
		draw = params.draw,
		recordsTotal = response.total,
		recordsFiltered = response.filtered,
		data = response.leaderboards,
	}
end

return leaderboards
