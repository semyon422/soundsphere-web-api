local notecharts = {}

function notecharts.params(params)
	params.page_num = math.floor(params.start / params.length) + 1
	params.per_page = params.length
	return params
end

function notecharts.response(response, params)
	return {
		draw = params.draw,
		recordsTotal = response.total,
		recordsFiltered = response.filtered,
		data = response.notecharts,
	}
end

return notecharts
