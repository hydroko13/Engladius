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
local broadcast_positions_rate = 45
local broadcast_positions_timer = 0

---@diagnostic disable-next-line: duplicate-set-field
function love.load()
    print("Engladius Server Software (ESS) version 0.0.1-dev")
    server = enet.host_create("0.0.0.0:9999")
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

            -- Notify other players of new joiner
            for _, player in pairs(players) do
                
                player.peer:send("j" .. love.data.pack("string", "<I4ff", mex, 0.0, 0.0), 0, "reliable")
            end

            -- Notify new joiner of other players who already existed
            for player_id, player in pairs(players) do
                print(player_id, player.x, player.y)
                event.peer:send("j" .. love.data.pack("string", "<I4ff", player_id, player.x, player.y), 0, "reliable")
            end
                
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


            local id_num = tonumber(id_str)

            if id_num then

                for _, player in pairs(players) do -- Notify other players of leaving
                    player.peer:send("l" .. love.data.pack("string", "<I4", id_num), 0, "reliable")
                end
                
            end

            

            
        
        end

        if event.type == "receive" then
            local addr = tostring(event.peer)
            local id_str = player_addr_to_id[addr]

            if event.data:sub(1, 1) == "p" then
                local player = players[id_str]
                if player then
                    local _, x, y = love.data.unpack("<i1ff", event.data)
                    player.x = x
                    player.y = y
                end
            end
            
            
        end

        event = server:service(0)
    end

    broadcast_positions_timer = broadcast_positions_timer + delta
    if broadcast_positions_timer >= 1 / broadcast_positions_rate then
        for player_id1, player1 in pairs(players) do
            for player_id2, player2 in pairs(players) do
                if player_id1 ~= player_id2 then
                    player1.peer:send("p" .. love.data.pack("string", "<I4ff", player_id2, player2.x, player2.y), 0, "unreliable")
                end
            end
        end
        broadcast_positions_timer = 0
    end

    
end