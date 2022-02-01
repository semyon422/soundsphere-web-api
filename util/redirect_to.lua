return function(self, redirect_url)
	if redirect_url:match("^/") then
		redirect_url = self:build_url(redirect_url)
	end
	self.res:add_header("Location", redirect_url)
	self.res.status = self.res.status or 302
end
