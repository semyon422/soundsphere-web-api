local util = require("lapis.util")
local http = require("lapis.nginx.http")
local secret = require("secret")

local Recaptcha = {}

Recaptcha.verify = function(self, response, ip)
	local body, status_code, headers = http.simple("https://www.google.com/recaptcha/api/siteverify", {
		secret = secret.recaptcha_secret,
		response = response,
		remoteip = ip
	})

	return util.from_json(body)
end

return Recaptcha

--[[
<% if captcha then %>
	<script src="https://www.google.com/recaptcha/api.js" async defer></script>
	<script>
		grecaptcha.ready(function() {
			grecaptcha.execute('<%= require("secret").recaptcha_public %>', {action:'submit'}).then(function(token) {
				document.getElementById('g-recaptcha-response').value = token;
			});
		});
	</script>
<% end %>

<div class="form-group">
	<div class="g-recaptcha" data-sitekey="<%= require("secret").recaptcha_public %>"></div>
</div>

local response = Recaptcha:verify(params["g-recaptcha-response"], self.req.headers["x-real-ip"])
if not response.success then
	self.message = "Invalid captcha"
	return {render = "response"}
end
]]