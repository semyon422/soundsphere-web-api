local enum = require("lapis.db.model").enum

local Formats = enum({
	undefined = 0,
	osu = 1,
	quaver = 2,
	bms = 3,
	ksm = 4,
	o2jam = 5,
	midi = 6,
	stepmania = 7,
	sph = 255,
})

Formats.extensions = {
	osu = "osu",
	qua = "quaver",
	bms = "bms",
	bme = "bms",
	bml = "bms",
	pms = "bms",
	ksh = "ksm",
	ojn = "o2jam",
	sph = "sph",
	mid = "midi",
	sm = "stepmania",
}

Formats.get_format = function(self, filename)
	return Formats.extensions[filename:match("^.+%.(.-)$")] or "undefined"
end

Formats.get_format_for_db = function(self, filename)
	return self:for_db(self:get_format(filename))
end

return Formats
