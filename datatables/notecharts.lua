local notecharts = {}

function notecharts.response(response, request)
	local params = request.params
	return {
		draw = params.draw,
		recordsTotal = response.total,
		recordsFiltered = response.filtered,
		data = response.notecharts,
	}
end

return notecharts
