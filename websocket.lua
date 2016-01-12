local module = {}

-- https://tools.ietf.org/html/rfc6455
local config = {
	["guid"] = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11",
	["port"] = 80 -- @todo 443 for secure connection
}

local utils = {
	["buffer"] = "",
	["connected"] = false,
	["connection"] = false,
	["key"] = false,
	["socket"] = {}
}

local request = {}

local function get_method(chunk)
	local first, last, method
		= string.find(
			chunk,
			"([A-Z]+) /[^\r]* HTTP/%d%.%d\r\n"
		)
	request["method"] = method
	return method, last
end

local function parse_request(chunk, trashold)
	requiest = {}
	local name, value, first
	while true do
		if not trashold then
			break
		end
		first, last, name, value
			= string.find(
				chunk, "([^ ]+): *([^\r]+)\r\n",
				trashold + 1)
		trashold = last
		if name and value then
			request[string.lower(name)] = value
		else
			break
		end
	end
	return request
end

function utils.acceptKey()
	local tb64 = crypto.toBase64
	local sha1 = crypto.sha1
	return tb64(sha1(
		utils.key .. config.guid
	))
end

local function receive(whatisit, chunk)
	if utils.connected then
	end
	local method, last = get_method(chunk)
	request = parse_request(chunk, last)
	utils.key = request["sec-websocket-key"]
	key = utils.acceptKey()
	if request.method == "GET" and key then
		utils.connection:send(
			"HTTP/1.1 101 Switching Protocols\r\n" ..
			"Upgrade: websocket\r\n" ..
			"Connection: Upgrade\r\n" ..
			"Sec-WebSocket-Accept: "
			.. key .. "\r\n\r\n")
	end
end

local function listen(connection)
	utils.connection = connection
	connection:on("receive", receive)
end

function module.start()
	module.server = net.createServer(net.TCP)
		:listen(config.port, listen)
end

function module.stop()
	module.server.close()
end

module.config = config

return module
