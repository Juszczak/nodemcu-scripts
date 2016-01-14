-- connect to wifi
dofile("autoconnect.lua")
gpio.mode(4, 1)
local state = 0
tmr.alarm(0, 100, 1, function()
	-- blink led when connecting
	gpio.write(4, state % 2)
	state = state + 1
	if wifi.sta.getip() ~= nil then
		state = nil
		gpio.write(4, 1)
		-- start ws when connected
		require("ws").start()
		-- clear timer after connection
		tmr.stop(0)
	end
end)
