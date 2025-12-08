local component = require("component")
local event = require("event")

function indexOf(tbl, value)
  for i, v in ipairs(tbl) do
    if v == value then
      return i
    end
  end
  print("ERROR: INDEX FAILURE")
  return nil  -- not found
end

function handle_message(event_type, localAddress, remoteAddress, port, distance, message_type, message)
	print("local: " .. localAddress .. " remote: " .. remoteAddress .. " port: " .. port .. " distance: " .. distance .. " message type: " .. message_type .. " message: " .. message)

	if tonumber(port) == 0 then
		--message was recieved by linked card. send via network card on port linked_card_address index
		local port_to_use = indexOf(linked_card_address, localAddress)
		network_card.broadcast(port_to_use, message_type, message)
	else
		--message was recieved by network card. send to linked cards.
		linked_card_list[port].send(message_type, message)
	end
end

--exectution begins here
linked_card_list = {}
linked_card_address = {}
network_card = nil
local network_cards_found = 0

for address, componentType in component.list() do
	if componentType == "tunnel" then
		print("Found Linked Card: " .. address)
		local linked_card = component.proxy(address)
		table.insert(linked_card_list, linked_card)
		table.insert(linked_card_address, address)
	elseif componentType == "modem" then
		print("Found Network Card: " .. address)
		network_card = component.proxy(address)
		network_cards_found = network_cards_found + 1 --check for too many network cards
		if network_cards_found > 1 then
			print("Warning! Too many network cards! Expected amount is: 1")
			computer.beep(2000, 5)
			computer.crash("incorrect network card number")
		end
	end
end

--only open ports that will have a linked card
local port_number = #linked_card_list
print("Opening ports 1-" .. port_number)

for i = 1, port_number do
	network_card.open(i)
	print("Port " .. i .. " open")
end

local modem_event_id = event.listen("modem_message", handle_message)
print("Registered event: " .. modem_event_id)

function end_program()
	print("closing ports...")
	local number_to_close = #linked_card_list
	for i = 1, number_to_close do
		network_card.close(i)
		print("Port "..i.." closed")
	end
	print("canceling event listeners...")
	event.cancel(modem_event_id)
	print("event listener "..modem_event_id.." canceled")
	print("goodbye")
	running = false
end

running = true

while (running) do
	print("Type 'exit' to exit.")
	local input = io.read()
	if input == "exit" then
		end_program()
	end
end
