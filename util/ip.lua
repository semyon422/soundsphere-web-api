local bit = require("bit")
local ffi = require("ffi")

local Ip = {}

function Ip:to_name(n)
	return
		bit.band(bit.rshift(n, 24), 0xFF) .. "." ..
		bit.band(bit.rshift(n, 16), 0xFF) .. "." ..
		bit.band(bit.rshift(n, 8), 0xFF) .. "." ..
		bit.band(n, 0xFF)
end

local int32_p = ffi.new("int32_t[1]")
local uint32_p = ffi.cast("uint32_t*", int32_p)

function Ip:for_db(ip)
	local n = 0
	for d in ip:gmatch("%d+") do
		n = bit.lshift(n, 8) + d
	end
	int32_p[0] = n
	return uint32_p[0]
end

return Ip
