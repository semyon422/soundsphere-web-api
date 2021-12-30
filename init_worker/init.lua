if ngx.worker.id() ~= 0 then
	return
end

ngx.log(ngx.NOTICE, "Start worker")
