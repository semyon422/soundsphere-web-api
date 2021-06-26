local list = {
	"tests.db",
	"tests.user",
}

local tests = {}

function tests.start()
	for _, test in ipairs(list) do
		require(test)
	end
end

return tests
