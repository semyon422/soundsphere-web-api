local md5 = require("md5")

local Filehash = {}

function Filehash.sum_for_db(self, s)
	return md5.sum(s)
end

function Filehash.sum_to_name(self, s)
	return md5.sumhexa(s)
end

function Filehash.for_db(self, hex)
    return (hex:gsub("..", function(cc) return string.char(tonumber(cc, 16)) end))
end

function Filehash.to_name(self, data)
	return (data:gsub(".", function(c) return ("%02x"):format(c:byte()) end))
end

return Filehash
