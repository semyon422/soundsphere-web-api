local config = require("lapis.config").get()

if config.code_cache == "off" then
	local f = function() end
	return {
		init = f,
		lapis = f,
		location = f,
		log = f,
	}
end

local prometheus = require("prometheus").init("prometheus_metrics")

local metrics = {}

function metrics.init()
	metrics.requests = prometheus:counter(
		"nginx_http_requests_total",
		"Number of HTTP requests",
		{"host", "status"}
	)
	metrics.latency = prometheus:histogram(
		"nginx_http_request_duration_seconds",
		"HTTP request latency",
		{"host"}
	)
	metrics.connections = prometheus:gauge(
		"nginx_http_connections",
		"Number of HTTP connections",
		{"state"}
	)

	-- ngx.ctx.performance
	metrics.lapis_view_time = prometheus:histogram(
		"lapis_performance_view_time",
		"Time in seconds spent rendering view"
	)
	metrics.lapis_layout_time = prometheus:histogram(
		"lapis_performance_layout_time",
		"Time in seconds spent rendering layout"
	)
	metrics.lapis_db_time = prometheus:histogram(
		"lapis_performance_db_time",
		"Time in seconds spent executing queries"
	)
	metrics.lapis_db_count = prometheus:counter(
		"lapis_performance_db_count",
		"The number of queries executed"
	)
	metrics.lapis_http_time = prometheus:histogram(
		"lapis_performance_http_time",
		"Time in seconds spent executing HTTP requests"
	)
	metrics.lapis_http_count = prometheus:counter(
		"lapis_performance_http_count",
		"The number of HTTP requests sent"
	)

	-- app
	metrics.scores = prometheus:histogram(
		"lapis_web_api_scores_total",
		"Score submission rate",
		{"is_trusted"}
	)
end

function metrics.lapis()
	local performance = ngx.ctx.performance
	if not performance then
		return
	end
	metrics.lapis_view_time:observe(tonumber(performance.view_time))
	metrics.lapis_layout_time:observe(tonumber(performance.layout_time))
	metrics.lapis_db_time:observe(tonumber(performance.db_time))
	metrics.lapis_db_count:inc(tonumber(performance.db_count))
	metrics.lapis_http_time:observe(tonumber(performance.http_time))
	metrics.lapis_http_count:inc(tonumber(performance.http_count))
end

function metrics.location()
	metrics.connections:set(ngx.var.connections_reading, {"reading"})
	metrics.connections:set(ngx.var.connections_waiting, {"waiting"})
	metrics.connections:set(ngx.var.connections_writing, {"writing"})
	prometheus:collect()
end

function metrics.log()
	metrics.requests:inc(1, {ngx.var.server_name, ngx.var.status})
	metrics.latency:observe(tonumber(ngx.var.request_time), {ngx.var.server_name})
end

return metrics
