modem = component.proxy(component.list("modem")())

--setup
local external_port_range_low = 1
local external_port_range_high = 5

--init
--open ports
for i = external_port_range_low, external_port_range_high do
	modem.open(i)
end

local router_addr = nil
known_clients = {}

while (true) do
	local eventName, localaddr, remote_addr, port, dist, message_type, message = computer.pullSignal()
	if eventName == "modem_message" then
		if message_type == "router_sync" then --so we know what the router is
			router_addr = remote_addr
			computer.beep(2000, 5)
		end
		if remote_addr ~= router_addr then --if it's not the router it's a client
			known_clients[remote_addr] = true
		end
		if router_addr ~= nil and remote_addr ~= router_addr then --external packet -> router
			modem.send(router_addr, port, message_type, message)
		elseif router_addr ~= nil and remote_addr == router_addr and message_type ~= "router_sync" then --router -> external
			for client, _ in pairs(known_clients) do
				modem.send(client, port, message_type, message)
			end
		end
	end
end
