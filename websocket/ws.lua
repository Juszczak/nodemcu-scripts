local function decode(chunk)
	if #chunk < 2 then return end
	local second = string.byte(chunk, 2)
	local length = bit.band(second, 0x7f)
	local offset = 2
	if length == 126 then
		if #chunk < 4 then return end
		length = bit.bor(
			bit.lshift(string.byte(chunk, 3), 8),
			string.byte(chunk, 4))
		offset = 4
	elseif length == 127 then
		if #chunk < 10 then return end
		length = bit.bor(
			bit.lshift(string.byte(chunk, 7), 24),
			bit.lshift(string.byte(chunk, 8), 16),
			bit.lshift(string.byte(chunk, 9), 8),
			string.byte(chunk, 10))
		offset = 10
	else offset = 2 end
	local mask = bit.band(second, 0x80) > 0
	if mask then offset = offset + 4 end
	if #chunk < offset + length then return end
	local first = string.byte(chunk, 1)
	local payload = string.sub(
		chunk,
		offset + 1,
		offset + length)
	assert(#payload == length, "Length mismatch")
	if mask then payload
		= crypto.mask(payload, string.sub(chunk, offset - 3, offset))
	end
	local extra = string.sub( chunk, offset + length + 1)
	local opcode = bit.band(first, 0xf)
	return extra, payload, opcode
end
function encode(payload, opcode)
	local opcode = opcode or 2
	assert(type(opcode) == "number", "opcode must be number")
	assert(type(payload) == "string", "payload must be string")
	local length = #payload
	local head = string.char(
		bit.bor(0x80, opcode),
		length < 126
		and length
		or (length < 0x10000)
		and 126
		or 127)
	if length >= 0x10000 then
		head = head .. string.char(
			0, 0, 0, 0,
			bit.band(bit.rshift(length, 24), 0xff),
			bit.band(bit.rshift(length, 16), 0xff),
			bit.band(bit.rshift(length, 8), 0xff),
			bit.band(length, 0xff))
	elseif length >= 126 then
		head = head .. string.char(
			bit.band(bit.rshift(length, 8), 0xff),
			bit.band(lendth, 0xff))
	end
	return head .. payload
end
local function handshaken(socket)
	node.output(function (message)
		return socket.send(message, 1)
	end, 1)

	function socket.onmessage(payload, opcode)
		if opcode == 1 then
			node.input(payload)
		elseif payload == 2 then
		end
	end
end
local module = {}
function module.start()
	net.createServer(net.TCP, 28800):listen(80, function(connection)
		local buffer = false
		local socket = {}
		function socket.send(...)
			connection:send(encode(...))
		end
		connection:on("receive", function(null, chunk)
			null = nil
			if buffer then
				buffer = buffer .. chunk
				while true do
					local extra, payload, opcode = decode(buffer)
					if not extra then return end
					buffer = extra
					socket.onmessage(payload, opcode)
				end
			end
			local first, last, method
				= string.find(chunk, "([A-Z]+) /[^\r]* HTTP/%d%.%d\r\n")
			first = nil
			local key, name, value
			while true do
				first, last, name, value
					= string.find(chunk, "([^ ]+): *([^\r]+)\r\n", last + 1)
				first = nil
				if not last then break end
				if string.lower(name) == "sec-websocket-key" then
					key = value
				end
			end
			if method == "GET" and key then
				connection:send(
					"HTTP/1.1 101 Switching Protocols\r\n" ..
					"Upgrade: websocket\r\n" ..
					"Connection: Upgrade\r\n" ..
					"Sec-WebSocket-Accept: " ..
					crypto.toBase64(crypto.sha1(key ..
					"258EAFA5-E914-47DA-95CA-C5AB0DC85B11")) ..
					"\r\n\r\n")
				buffer = ""
				handshaken(socket)
			else
				connection:send(
					"HTTP/1.1 404 Not Found\r\n" ..
					"Connection: Close\r\n\r\n")
				connection:on("sent", connection.close)
			end
		end)
	end)
end
return module
