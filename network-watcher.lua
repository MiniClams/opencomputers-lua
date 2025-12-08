component = require("component")
event = require("event")
modem = component.modem

print("Enter starting range: ")
local port_low = io.read()
print("Enter ending range: ")
local port_high = io.read()

for i = port_low, port_high do
	modem.open(i)
end

while (true) do
	local event_type, localAddress, remoteAddress, port, distance, message_type, message = event.pull("modem_message")
	print("local address: "..localAddress.." remoteAddress: "..remoteAddress.." port: "..port.." distance: " ..distance.." message type: "..message_type.." message: "..message)
end
