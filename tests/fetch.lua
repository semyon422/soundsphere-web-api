local http = require("http")

local host = "127.0.0.1"
local port = 8081

return function(path, options, callback)
	options.host = host
	options.port = port
	options.path = path
	http.request(options, function(res)
		res:on("data", function(chunk)
			callback({
				code = res.statusCode,
				body = chunk
			})
		end)
	end):done()
end
