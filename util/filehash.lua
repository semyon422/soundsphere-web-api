local digest = require("openssl.digest")

local Filehash = {}

function Filehash.sum_for_db(self, s)
	return digest.new("md5"):final(s)
end

function Filehash.sum_to_name(self, s)
	return self:to_name(self:sum_for_db(s))
end

function Filehash.for_db(self, hex)
	if #hex == 16 then
		return hex
	end
    return (hex:gsub("..", function(cc) return string.char(tonumber(cc, 16) or 0) end))
end

function Filehash.to_name(self, data)
	if #data == 32 then
		return data
	end
	return (data:gsub(".", function(c) return ("%02x"):format(c:byte()) end))
end

return Filehash
