io.stdout:setvbuf("no")

function get_mex(arr)
    local present = {}
    
    for _, val in ipairs(arr) do
        if val >= 0 then
            present[val] = true
        end
    end
    
    local mex = 0
    while present[mex] do
        mex = mex + 1
    end
    
    return mex
end

local enet = require("enet")
local server
local players = {}
local player_addr_to_id = {}

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

            local ids = {}
            for id, _ in pairs(players) do
                table.insert(ids, tonumber(id))
            end
            local mex = get_mex(ids)
            local id_str = tostring(mex)
            print("Client connected with id " .. id_str)
            players[id_str] = {
                x = 0,
                y = 0,
                peer = event.peer,
            }
            player_addr_to_id[tostring(event.peer)] = id_str
        end

        if event.type == "disconnect" then
            local addr = tostring(event.peer)
            local id_str = player_addr_to_id[addr]
            
            print("Client disconnected with id " .. id_str)
            players[id_str] = nil
            player_addr_to_id[addr] = nil

            
        
        end

        if event.type == "receive" then
            local addr = tostring(event.peer)
            local id_str = player_addr_to_id[addr]

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