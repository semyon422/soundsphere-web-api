local db_where = require("util.db_where")
local db_and = require("util.db_and")

local Joined_query = {}

function Joined_query:new(db)
	local query = {
		select_table = {},
		where_table = {},
		fields_table = {},
		orders_table = {},
		db = db,
	}

	setmetatable(query, self)
	self.__index = self

	return query
end

function Joined_query:select(...)
	table.insert(self.select_table, self.db.interpolate_query(...))
end

function Joined_query:where(...)
	if type(...) == "table" then
		table.insert(self.where_table, self.db.encode_clause(...))
		return
	end
	table.insert(self.where_table, self.db.interpolate_query(...))
end

function Joined_query:fields(...)
	for _, field in ipairs({...}) do
		table.insert(self.fields_table, field)
	end
end

function Joined_query:orders(...)
	for _, order in ipairs({...}) do
		table.insert(self.orders_table, order)
	end
end

function Joined_query:concat()
	local out = {}
	for _, v in ipairs(self.select_table) do
		table.insert(out, v)
	end

	table.insert(out, db_where(db_and(self.where_table)))
	if #self.orders_table > 0 then
		table.insert(out, "order by " .. table.concat(self.orders_table, ", "))
	end

	return table.concat(out, " "), {
		fields = table.concat(self.fields_table, ", "),
	}
end

return Joined_query
