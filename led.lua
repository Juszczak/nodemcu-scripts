local led = {}                -- init module

local pin = 4                 -- gpio2
local high = gpio.HIGH
local low = gpio.LOW
local state = 0               -- initial state

function led.on()
	state = low                 -- set low state
	gpio.write(pin, state)      -- write state
end

function led.off()
	state = high                -- set high state
	gpio.write(pin, state)      -- write state
end

function led.init()
	gpio.mode(pin, gpio.OUTPUT) -- set pin mode
	led.on()
end

function led.is_on()
	return state == low
end

return led                    -- export module
