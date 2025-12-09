component = require("component")
event = require("event")
io = require("io")
modem = component.modem

--this router serves two purposes:
--provide internal ports for services (library on port 1001, messaging on 1002, etc)
--map external ports to internal ones request comes in on port 1, map to port 1001, then map the respnose back

--implementation rules: you must have a firewall filtering out anything on your internal domain range before this router. You must include the key phrase "response" somewhere in your message type if it is a response to a previous packet

--setup
local internal_domain = 1000

services = {"library", "messaging"}

library = {"data_request", "set_data", "data_response"}

local extenal_port_range_low = 1
local extenal_port_range_high = 5

--init
--open ports
modem.open(internal_domain)
print("opened port: "..internal_domain)

for i = 1, #services do
	modem.open(internal_domain + i)
	print("opened port: "..(internal_domain + i))
end

for i = external_port_range_low, external_port_range_high do
	modem.open(i)
	print("opened port: "..i)
end

--send sync packet to identify myself on the network
for i = external_port_range_low, external_port_range_high do
	modem.broadcast(i, "router_sync", "ping")
	print("syncing channel: "..i)
end

--convert packet types to lookup table
local library_lookup = {}
for _, v in ipairs(library) do
    library[v] = true
end

function indexOf(tbl, value)
	for i, v in ipairs(tbl) do
		if v == value then
			return i
		end
	end
	print("ERROR: INDEX FAILURE")
	return nil  -- not found
end

external_port_last_used = 0 -- used to map response

while (true) do
	local eventName, localAddr, remoteAddr, port, dist, message_type, message = event.pull("modem_message")
	if message_type == "port_request" then
		local response = indexOf(services, message)
		if response == nil then
			print("Warning: No service ID for: "..message)
		end
		modem.send(remoteaddr, port, "router_response", response)
	elseif message_type == "router_ping" then
		modem.send(remoteaddr, port, "router_response", "ping")
	else
		--here we need to map ports
		if port >= internal_domain then
			--this is an internal message
			if external_port_last_used ~= 0 then
				--this packet COULD be a response! Lets check
				if string.find(message_type, "response") then
					--it IS a response! lets forward it on the port
					modem.broadcast(external_port_last_used, message_type, message)
				else
					--it is NOT a response! that must mean our last packet didn't need/get one
					external_port_last_used = 0
				end
			end
		else
			--this is an external message
			if library_lookup[message_type] then --packet is a library packet
				local library_port = indexOf(services, "library")
				modem.broadcast(library_port, message_type, message)
				external_port_last_used = port;
			end
		end
	end
end
