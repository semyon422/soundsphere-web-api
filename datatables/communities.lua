local communities = {}

function communities.params(params)
	params.page_num = math.floor(params.start / params.length) + 1
	params.per_page = params.length
	return params
end

function communities.response(response, params)
	response.communities = {{}}
	for _, community in ipairs(response.communities) do
		community.id = 1
		community.name = "name"
		community.alias = "alias"
		community.inputmodes = "inputmodes"
		community.members = "members"
		community.description = "description"
	end
	return {
		draw = params.draw,
		recordsTotal = response.total,
		recordsFiltered = response.filtered,
		data = response.communities,
	}
end

return communities
