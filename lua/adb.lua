local socket = require("socket")

if arg then
    host = arg[1] or host
    port = arg[2] or port
end

host = host or "localhost"
port = port or 5037

while 1 do
    local cmd = ""

    repeat 
        io.write ("adb> ")
        cmd = io.read()
    until (string.len(cmd) > 0)

    if (cmd == "q" or cmd == "quit") then break end

    adb_cmd = string.format("%04X%s", string.len(cmd), cmd)

    c, e = socket.connect(host, port)

    if (e) then
        print (string.format("Can't connect to %s:%d", host, port))
        os.exit(-1)
    end

    io.write ("Send adb cmd:" .. adb_cmd .. "\n");
    c:send(adb_cmd)

    l, e = c:receive()

    if e then
        io.write ("Command or Socket error.")
    else 
        io.write (string.sub(l, 0, 4) .. "\n")
        io.write (string.sub(l, 5) .. "\n")
    end
end

