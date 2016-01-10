local station = {}                  -- unit module
local blink = require('blink')      -- use blink lib
local connection_tmr = 5

station.SSID = ""                   -- default ssid
station.PASSWORD = ""               -- default password
station.CALLBACK = function() end   -- default callback

function station.connected()
	tmr.stop(connection_tmr)          -- stop checking connection
	blink.start(1000)                 -- slow blinking when connected
	station.CALLBACK()
end

function station.connect()
	blink.start(100)                  -- fast blinking for startup
	wifi.setmode(wifi.STATION)        -- set station mode
	wifi.sta.config(                  -- set wifi credentials
		station.SSID,
		station.PASSWORD
	)
	wifi.sta.connect()                -- connect to wifi

	tmr.alarm(connection_tmr, 500, 1, function()
		ip, netmask, gateway = wifi.sta.getip() -- check ip

		if ip ~= nil then
			station.connected()           -- connected, yay
		end
	end)
end

function station.start(ssid, password, callback)
	station.SSID = ssid               -- set static ssid
	station.PASSWORD = password       -- set static password
	if callback ~= nil then           -- set callback if passed
		station.CALLBACK = callback
	end
	station.connect()                 -- attempt connection
end

return station                      -- return module
