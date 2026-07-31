io.stdout:setvbuf("no")

local enet = require("enet")
local server
local players = {}

---@diagnostic disable-next-line: duplicate-set-field
function love.load()
    print("Engladius Server Software (ESS) version 0.0.1-dev")
    server = enet.host_create("*:9999")
    if server == nil then
        print("Server failed to create")
        love.event.quit()
    end
   
end


---@diagnostic disable-next-line: duplicate-set-field
function love.update(delta)
    if not server then return end -- if the server wasnt created yet then return from this function

    local event = server:service(0)
    while event do
        if event.type == "connect" then
            print("Client connected")
            table.insert(players, event.peer)
        end

        if event.type == "disconnect" then
            print("Client disconnected")
        end

        if event.type == "receive" then
            print("Received data from client")
            print(event.data)
        end

        event = server:service(0)
    end
    
end