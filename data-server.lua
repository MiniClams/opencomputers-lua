component = require("component")
event = require("event")
filesystem = require("filesystem")
io = require("io")
modem = component.modem

--setup
--check if /home/data exists, if not, create it
if not filesystem.exists("/home/data/") then
	filesystem.makeDirectory("/home/data")
	print("created directory: /home/data")
end

local my_port = 0
io.write("Set port: ")
my_port = io.read()

--getting/setting data values
function getData(key)
	local file = io.open("/home/data/"..key, "r")
	if file then
		local result = file:read("*a")
		file:close()
		return result
	else
		print("error: file not found: "..key)
		return "ERROR"
	end
end

function setData(key, data)
	local file = io.open("/home/data/"..key, "w")
	if file then
		file:write(data)
		file:close()
		return true
	else
		print("error: could not open file: "..key)
		return false
	end
end

--parse network messages
while (true) do
	modem.open(tonumber(my_port))
	local event_name, localaddr, remoteaddr, port, dist, message_type, message = event.pull("modem_message")
	if message_type == "data_request" then
		modem.send(remoteaddr, port, getData(message))
		print("data: "..key.." sent!")
	elseif message_type == "set_data" then
		--set_data packages will have message split by :
		local key, value = string.match(message, "([^:]+):(.+)")
		if not key then
			print("error: string does not contain :")
			return
		end
		setData(key, value)
		print("data: "..key.." written!")
	end
end
