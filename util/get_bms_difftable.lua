local http = require("lapis.nginx.http")
local url = require("socket.url")
local util = require("lapis.util")

local function parse_args(s)
	local arg = {}
	s:gsub("([%-%w]+)=([\"'])(.-)%2", function(w, _, a)
		arg[w] = a
	end)
	return arg
end

return function(link)
	local body, status_code = http.simple(assert(link))
	if status_code ~= 200 then
		return false, "table not found"
	end

	local header_path
	for args in body:gmatch("<meta(.-)%/?>") do
		args = parse_args(args)
		if args.name == "bmstable" then
			header_path = args.content
		end
	end
	if not header_path then
		return false, "header url not found"
	end

	local header_link = url.absolute(link, header_path)
	body, status_code = http.simple(header_link)
	if status_code ~= 200 then
		return false, "header not found"
	end

	local header = util.from_json(body)
	local data_path = header.data_url
	if not data_path then
		return false, "data url not found"
	end

	local data_link = url.absolute(link, data_path)
	body, status_code = http.simple(data_link)
	if status_code ~= 200 then
		return false, "data not found"
	end

	local data = util.from_json(body)

	return header, data
end
