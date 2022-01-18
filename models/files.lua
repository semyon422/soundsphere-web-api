local Model = require("lapis.db.model").Model
local toboolean = require("util.toboolean")
local Formats = require("enums.formats")
local Storages = require("enums.storages")
local Filehash = require("util.filehash")

local Files = Model:extend(
	"files",
	{
		relations = {
			{"notecharts", has_many = "notecharts", key = "file_id"},
			{"scores", has_many = "scores", key = "file_id"},
		},
		url_params = function(self, req, ...)
			return "file", {file_id = self.id}, ...
		end,
	}
)

local function to_name(self)
	self.hash = Filehash:to_name(self.hash)
	self.format = Formats:to_name(self.format)
	self.storage = Storages:to_name(self.storage)
	return self
end

local function for_db(self)
	self.hash = Filehash:for_db(self.hash)
	self.format = Formats:for_db(self.format)
	self.storage = Storages:for_db(self.storage)
	return self
end

function Files.to_name(self, row) return to_name(row) end
function Files.for_db(self, row) return for_db(row) end

local _load = Files.load
function Files:load(row)
	row.uploaded = toboolean(row.uploaded)
	row.loaded = toboolean(row.loaded)
	row.created_at = tonumber(row.created_at)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

function Files:get_path(file)
	local storage = Storages:to_name(file.storage)
	local hash = Filehash:to_name(file.hash)
	return "storages/" .. storage .. "/" .. hash
end

function Files:exists(file)
	local f = io.open(self:get_path(file), "r")
	if f then
		io.close(f)
		return true
	end
	return false
end

function Files:write_file(file, content)
	local path = self:get_path(file)
	local f = assert(io.open(path, "wb"))
	f:write(content)
	f:close()
end

function Files:read_file(file)
	local path = self:get_path(file)
	local f = assert(io.open(path, "rb"))
	local content = f:read("*a")
	f:close()

	return content
end

return Files
