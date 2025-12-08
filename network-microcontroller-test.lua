modem = component.proxy(component.list("modem")())
computer = component.proxy(component.list("computer")())

while (true) do
	local i = 16
	
	while (i ~= 0) do
	modem.open(i)
	modem.broadcast(i, "MICROCONTROLLER_TEST_PACKET", "[DATA]")
	modem.close(i)
	i = i - 1
	end
	computer.beep(2000, 0.5)
	computer.pullSignal(20)
end
