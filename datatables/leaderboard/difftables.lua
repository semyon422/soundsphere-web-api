local difftables = {}

function difftables.response(response, request)
	local params = request.params
	return {
		draw = params.draw,
		recordsTotal = response.total,
		recordsFiltered = response.filtered,
		data = response.difftables,
	}
end

return difftables
