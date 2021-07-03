local leaderboards = {}

function leaderboards.params(params)
	params.page_num = math.floor(params.start / params.length) + 1
	params.per_page = params.length
	return params
end

function leaderboards.response(response, params)
	return {
		draw = params.draw,
		recordsTotal = response.total,
		recordsFiltered = response.filtered,
		data = response.leaderboards,
	}
end

return leaderboards
