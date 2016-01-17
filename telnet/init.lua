dofile("autoconnect.lua")
telnet = require("telnet")
gpio.mode(4, 1)
local state = 0
tmr.alarm(0, 100, 1, function()
	gpio.write(4, state)
	state = (state + 1) % 2
	if wifi.sta.getip() ~= nil then
		state = nil
		gpio.write(4, 1)
		telnet.start()
		tmr.stop(0)
	end
end)
