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
            local id_str = tostring(event.peer)
            print("Client connected with id " .. id_str)
            players[id_str] = {
                x = 0,
                y = 0,
                peer = event.peer,
            }
        end

        if event.type == "disconnect" then
            local id_str = tostring(event.peer)
            print("Client disconnected with id " .. id_str)
            players[id_str] = nil
        end

        if event.type == "receive" then
            local id_str = tostring(event.peer)

            if event.data[1] == "p" then
                local player = players[id_str]
                if player then
                    local x, y = love.data.unpack("<ff", event.data)
                    player.x = x
                    player.y = y
                end
            end
            
            
        end

        event = server:service(0)
    end
    
end