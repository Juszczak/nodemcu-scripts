local module = {}

local function receive(socket, data)
	node.input(data)
	if socket == nil then
		print("connection terminated")
	end
end

local function disconnection(socket)
	node.output(nil)
end

function module.start()
	server = net.createServer(net.TCP, 600)
	server:listen(23, function(socket)
		local function send(data)
			socket:send(data)
		end
		node.output(send, 0)
		socket:on("receive", receive)
		socket:on("disconnection", disconnection)
	end)
end

function module.stop()
	server.stop()
end

return module
