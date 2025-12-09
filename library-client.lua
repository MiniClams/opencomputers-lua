component = require("component")
io = require("io")
event = require("event")
modem = component.modem

--detect modem or tunnel
local tunnel = false
local my_port = 0

if component.isAvailable("tunnel") then
	tunnel = true
else
	tunnel = false
end

--setup
function network_card_setup()
	print("Requesting port from router...")
	modem.open(1000)
	modem.broadcast(1000, "port_request", "library")
	local _, _, _, _, _, message_type, message = event.pull(10, "modem_message")
	modem.close(1000)
	if message_type == "router_response" then
		my_port = message
		print("Port is: "..message)
	else
		io.write("Set port: ")
		my_port = io.read()
	end
end

function tunnel_setup()
	print("running in tunnel mode")
end

--communication function
function broadcast(message_type, message)
	if tunnel then
		tunnel.send(message_type, message)
	else
		modem.open(tonumber(my_port))
		modem.broadcast(tonumber(my_port), message_type, message)
		modem.close(tonumber(my_port))
	end
end

function recieve()
	if tunnel then	
		return event.pull("modem_message")
	else
		modem.open(tonumber(my_port))
		local a, b, c, d, e, f, g = event.pull("modem_message")
		modem.close(tonumber(my_port))
		return a, b, c, d, e, f, g
	end
end

--execution begins here
if tunnel then
	tunnel_setup()
else
	network_card_setup()
end

while (true) do
	::continue::
	io.write("<LIBRARY-CLIENT>$")
	local request = io.read()
	if string.sub(request, 1, 1) == "?" then --first char ? = special command
		local command = string.sub(request, 2)
		if command == "write" then
			io.write("Data Name: ")
			local name = io.read()
			io.write("Data value: ")
			local value = io.read()
			broadcast("set_data", name..":"..value)
		end
		goto continue
	end
	broadcast("data_request", request)
	local _, _, _, _, _, message_type, message = recieve()
	if message_type == "data_response" then
		print(message)
	end
end
