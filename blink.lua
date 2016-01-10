local led = require("led")

local blink = {}          -- init module

local freq = 1000         -- default freq
local blink_tmr = 6       -- id for blinking tmr

function blink.toggle()
	if led.is_on() then
		led.off()
	else
		led.on()
	end
end

function blink.start(arg)
	freq = arg
	led.init()
	tmr.alarm(blink_tmr, freq, 1, blink.toggle)
end

function blink.stop()
	tmr.stop(blink_tmr)     -- stop blinking tmr
end

return blink              -- return module
