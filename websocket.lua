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
	["key"] = false
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

local function decode_frame(chunk)
	if #chunk < 2 then
		return
	end
	local second = string.byte(chunk, 2)
	local length = bit.band(second, 0x7f)
	local offset = 2
	if length == 126 then
		if #chunk < 4 then
			return
		end
		length = bit.bor(
			bit.lshift(string.byte(chunk, 3), 8),
			string.byte(chunk, 4))
		offset = 4
	elseif length == 127 then
		if #chunk < 10 then
			return
		end
		length = bit.bor(
			-- ignore lengths longer then 32 bit
			bit.lshift(string.byte(chunk, 7), 24),
			bit.lshift(string.byte(chunk, 8), 16),
			bit.lshift(string.byte(chunk, 9), 8),
			string.byte(chunk, 10)
		)
		offset = 10
	else
		offset = 2
	end
	local mask = bit.band(second, 0x80) > 0
	if mask then
		offset = offset + 4
	end
	if #chunk < offset + length then
		return
	end
	local first = string.byte(chunk, 1)
	local payload = string.sub(
		chunk,
		offset + 1,
		offset + length)
	assert(#payload == length, "Length mismatch")
	if mask then
		payload = crypto.mask(
			payload,
			string.sub(
				chunk,
				offset - 3,
				offset
			)
		)
	end
	local extra = string.sub(
		chunk,
		offset + length + 1
	)
	local opcode = bit.band(first, 0xf)
	return extra, payload, opcode
end

function encode_frame(payload, opcode)
	local opcode = opcode or 2
	assert(
		type(opcode) == "number",
		"opcode must be number"
	)
	assert(
		type(payload) == "string",
		"payload must be string"
	)
	local length = #payload
	local head = string.char(
		bit.bor(0x80, opcode),
		length < 126
		and length
		or (length < 0x10000)
		and 126
		or 127
	)
	if length >= 0x10000 then
		head = head .. string.char(
			0, 0, 0, 0,  -- 32 bit length is plenty,
			-- assume zero for rest
			bit.band(bit.rshift(length, 24), 0xff),
			bit.band(bit.rshift(length, 16), 0xff),
			bit.band(bit.rshift(length, 8), 0xff),
			bit.band(length, 0xff)
		)
	elseif length >= 126 then
		head = head .. string.char(
			bit.band(bit.rshift(length, 8), 0xff),
			bit.band(lendth, 0xff)
		)
	end
	return head .. payload
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

local function accept_connection(key)
	utils.connection:send(
		"HTTP/1.1 101 Switching Protocols\r\n" ..
		"Upgrade: websocket\r\n" ..
		"Connection: Upgrade\r\n" ..
		"Sec-WebSocket-Accept: " .. key .. "\r\n\r\n")
end

local function reject_connection()
	utils.connection:send(
		"HTTP/1.1 404 Not Found\r\n" ..
		"Connection: Close\r\n\r\n")
	utils.connection:on("sent", utils.connection.close)
end

function module.send(message)
	node.output(function()
		utils.connection:send(encode(message, 1))
	end, 1)
end

function module.connected()
	print("--- connected ---")
end

function module.onmessage(payload, opcode)
	print("--- opcode ---")
	print(opcode)
	if opcode == 1 then
		print("--- payload ---")
		print(payload)
		if payload == "ls" then
			local list = file.list()
			local lines = {}
			for k, v in pairs(list) do
				lines[#lines + 1] = k .. "\0" .. v
			end
			socket.send(table.concat(lines, "\0"), 2)
		end
	elseif payload == 2 then
	end
end

local function receive(whatisit, chunk)
	print(whatisit)
	print(chunk)
	if utils.connected then
		utils.buffer = utils.buffer .. chunk
		while true do
			local extra, payload, opcode = decode_frame(utils.buffer)
			if not extra then
				return
			end
			utils.buffer = extra
			module.onmessage(payload, opcode)
		end
		print(utils.buffer)
	end
	local method, last = get_method(chunk)
	request = parse_request(chunk, last)
	utils.key = request["sec-websocket-key"]
	key = utils.acceptKey()
	print(key)
	if request.method == "GET" and key then
		accept_connection(key)
		utils.buffer = ""
		utils.connected = true
		module.connected()
	else
		reject_connection()
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
