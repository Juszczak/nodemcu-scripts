local blink = {}          -- init module

local pin = 4             -- gpio2
local val = gpio.LOW      -- init low val
local freq = 1000         -- default freq
local blink_tmr = 6       -- id for blinking tmr

function blink.toggle()
	if val == gpio.LOW then -- toggle val
		val = gpio.HIGH
	else
		val = gpio.LOW
	end
	gpio.write(pin, val)    -- write val to gpio2
end

function blink.start(arg)
	freq = arg
	gpio.mode(pin, gpio.OUTPUT)
	gpio.write(pin, val)
	tmr.alarm(blink_tmr, freq, 1, blink.toggle)
end

function blink.stop()
	tmr.stop(blink_tmr)     -- stop blinking tmr
end

return blink              -- return module
