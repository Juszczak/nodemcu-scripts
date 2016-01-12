local module = {}

-- https://tools.ietf.org/html/rfc6455
local config = {
	["guid"] = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11",
	["port"] = 80 -- @todo 443 for secure connection
}

local function listen(connection)
end

function module.start()
	module.server = net.createServer(net.TCP)
		:listen(config.port, listen)
end

function module.stop()
	module.server.close()
end

return module
