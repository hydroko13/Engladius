local vers = "0.0.1-dev"



local button = require("gui.Button")
local enet = require("enet")
local bit = require("bit")
local server_peer
local client
local connected = false

local player
local camera = { x = 0, y = 0 }

local WIDTH, HEIGHT = 640, 360
local tick = 0
local tick_timer = 0.0
local tick_rate = 45.0
local server_players = {}

local TICK_DT = 1.0 / 45.0

local pending_inputs = {}

function math.round(x)
    return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

---@diagnostic disable-next-line: duplicate-set-field
function love.load()
    client = enet.host_create()

    love.graphics.setDefaultFilter("nearest", "nearest")

    gameCanvas = love.graphics.newCanvas(WIDTH, HEIGHT)

    love.window.setTitle("Engladius")
    love.window.setMode(1280, 720, { fullscreen = false, fullscreentype = "desktop", resizable = true })
    love.window.maximize()

    local iconImg = love.image.newImageData("assets/engladius_icon.png")

    love.window.setVSync(1)

    love.mouse.setVisible(false)

    love.window.setIcon(iconImg)


    engladiusFont = love.graphics.newFont("assets/alagard.ttf", 24)
    titleFont = love.graphics.newFont("assets/alagard.ttf", 64)

    cursorImg = love.graphics.newImage("assets/cursor.png")

    playButton = button.newButton(WIDTH / 2, HEIGHT / 2 + 20, "Play")


    gameState = "mainMenu"

    playerImage = love.graphics.newImage("assets/player.png")

    grassImage = love.graphics.newImage("assets/grass_tile.png")
end

function lerp(a, b, t)
    return a + (b - a) * t
end

function gameDraw(gameMouseX, gameMouseY)
    if gameState == "mainMenu" then
        love.graphics.setFont(titleFont)
        love.graphics.setColor(1, 1, 1, 1)



        love.graphics.print("Engladius", WIDTH / 2 - titleFont:getWidth("Engladius") / 2, 50)

        love.graphics.setFont(engladiusFont)

        love.graphics.print("vers " .. vers, 8, HEIGHT - 26)

        playButton:drawButton(engladiusFont, gameMouseX, gameMouseY)
    elseif gameState == "connecting" then
        love.graphics.setFont(engladiusFont)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Connecting...", WIDTH / 2 - engladiusFont:getWidth("Connecting...") / 2, HEIGHT / 2 - 100)
    elseif gameState == "inGame" then
        local camoffsetx = -camera.x
        local camoffsety = -camera.y

        love.graphics.push()



        love.graphics.translate(WIDTH / 2, HEIGHT / 2)



        love.graphics.translate(camoffsetx, camoffsety)

        for i = -120, 120, 1 do
            for j = -120, 120, 1 do
                love.graphics.draw(grassImage, math.round(i * grassImage:getWidth()),
                    math.round(j * grassImage:getHeight()))
            end
        end

        for player_id, server_player in pairs(server_players) do
            love.graphics.draw(playerImage, math.round(server_player.x - playerImage:getWidth() / 2),
                math.round(server_player.y - playerImage:getHeight() / 2))
        end

        if player then
            love.graphics.draw(playerImage, math.round(player.render_x - playerImage:getWidth() / 2),
                math.round(player.render_y - playerImage:getHeight() / 2))
        end
        


        love.graphics.pop()
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function love.draw()
    local winWidth, winHeight = love.graphics.getDimensions()
    local scale = math.min(winWidth / WIDTH, winHeight / HEIGHT)

    local leftMargin = (winWidth - scale * WIDTH) / 2
    local topMargin = (winHeight - scale * HEIGHT) / 2


    -- calculate scale before drawing anything so i can calculate game mouse pos

    local mx, my = love.mouse.getPosition()

    local gameMouseX, gameMouseY = (mx - leftMargin) / scale, (my - topMargin) / scale

    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear(0, 0.2, 0.2, 1)





    gameDraw(gameMouseX, gameMouseY)


    love.graphics.draw(cursorImg, gameMouseX - 16, gameMouseY - 16, 0, 2, 2)

    love.graphics.setCanvas()

    love.graphics.setColor(1, 1, 1, 1)

    -- now we use scale value
    love.graphics.draw(gameCanvas, winWidth / 2 - (scale * WIDTH / 2), winHeight / 2 - (scale * HEIGHT / 2), 0, scale,
        scale)
end

function ontick()
    if player then
        -- use bitpacking to store the 4 input state booleans into a single byte
        local packed = bit.bor(
            bit.bor(bit.bor((player.input_state.down and 1 or 0), bit.lshift(player.input_state.up and 1 or 0, 1)),
                bit.lshift(player.input_state.right and 1 or 0, 2), bit.lshift(player.input_state.left and 1 or 0, 3))
        )
        local inputstate_packet_string = love.data.pack("string", "<I4I1", tick, packed)
        server_peer:send("p" .. inputstate_packet_string, 0, "unreliable")
        pending_inputs[tick] = {up = player.input_state.up, down = player.input_state.down, left = player.input_state.left, right = player.input_state.right, dt = player.input_state.dt}
    end
end

function joined()
    player = {
        x = 0,
        y = 0,
        render_x = 0,
        render_y = 0,
        input_state = {
            left = false,
            right = false,
            up = false,
            down = false,
            dt = 0.0
        }
    }
end

---@diagnostic disable-next-line: duplicate-set-field
function love.update(delta)
    

    if not client then return end
    if not server_peer then return end

    if player then

        player.render_x = lerp(player.render_x, player.x, delta * 34)
        player.render_y = lerp(player.render_y, player.y, delta * 34)
        
    end

    local event = client:service(0)
    while event do
        if event.type == "connect" then
            gameState = "inGame"
            connected = true
            joined()
        end
        if event.type == "disconnect" then
            love.event.quit()
        end
        if event.type == "receive" then
            if event.data:sub(1, 1) == "j" then -- New Player joined
                local _, player_id, x, y = love.data.unpack("<i1I4ff", event.data)
                print(player_id, x, y)
                server_players[player_id] = { x = x, y = y, target_x = x, target_y = y }
            elseif event.data:sub(1, 1) == "l" then -- Player left
                local _, player_id = love.data.unpack("<i1I4", event.data)
                server_players[player_id] = nil
            elseif event.data:sub(1, 1) == "p" then
                local _, player_id, x, y = love.data.unpack("<i1I4ff", event.data)

                server_players[player_id].target_x = x
                server_players[player_id].target_y = y
            elseif event.data:sub(1, 1) == "I" then
                local _, seq, x, y = love.data.unpack("<i1I4ff", event.data)

                player.x = x
                player.y = y
                

                local seq_nums = {}
    
                for seq_num, input_state in pairs(pending_inputs) do
                    seq_nums[#seq_nums + 1] = seq_num
                end
    
                table.sort(seq_nums)

                for _, tick in ipairs(seq_nums) do
                    local input = pending_inputs[tick]
                    if tick <= seq then
                        pending_inputs[tick] = nil
                    else
                        player.input_state.up = input.up
                        player.input_state.down = input.down
                        player.input_state.left = input.left
                        player.input_state.right = input.right
                        if player.input_state.up then
                            player.y = player.y - TICK_DT * 130
                        end
                        if player.input_state.down then
                            player.y = player.y + TICK_DT * 130
                        end
                        if player.input_state.left then
                            player.x = player.x - TICK_DT * 130
                        end
                        if player.input_state.right then
                            player.x = player.x + TICK_DT * 130
                        end
                    end
                    
                end

                
                


                
            end
        end


        event = client:service(0)
    end


    if gameState == "inGame" then


        if player then
            camera.x = camera.x + (player.x - camera.x) * delta * 2.5
            camera.y = camera.y + (player.y - camera.y) * delta * 2.5



            player.input_state.up = love.keyboard.isDown("w")
            player.input_state.down = love.keyboard.isDown("s")
            player.input_state.left = love.keyboard.isDown("a")
            player.input_state.right = love.keyboard.isDown("d")
            player.input_state.dt = delta

            if player.input_state.up then
                player.y = player.y - TICK_DT * 130
            end
            if player.input_state.down then
                player.y = player.y + TICK_DT * 130
            end
            if player.input_state.left then
                player.x = player.x - TICK_DT * 130
            end
            if player.input_state.right then
                player.x = player.x + TICK_DT * 130
            end
        end

        for player_id, server_player in pairs(server_players) do
            server_player.x = lerp(server_player.x, server_player.target_x, delta * 45)
            server_player.y = lerp(server_player.y, server_player.target_y, delta * 45)
        end

        tick_timer = tick_timer + delta
        if tick_timer >= 1.0 / tick_rate then
            tick = tick + 1
            tick_timer = 0.0
            ontick()
        end
    end


end

---@diagnostic disable-next-line: duplicate-set-field
function love.quit()
    if not server_peer then return false end



    server_peer:disconnect()

    client:service(800)
    return false
end

---@diagnostic disable-next-line: duplicate-set-field
function love.keypressed(key, scancode, isrepeat)
    -- Scancode is better for controls then key because it works on other keyboard layouts
    if scancode == "escape" then
        love.event.quit()
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function love.mousepressed(mx, my, mButton)
    local winWidth, winHeight = love.graphics.getDimensions()
    local scale = math.min(winWidth / WIDTH, winHeight / HEIGHT)

    local leftMargin = (winWidth - scale * WIDTH) / 2
    local topMargin = (winHeight - scale * HEIGHT) / 2

    local gameMouseX, gameMouseY = (mx - leftMargin) / scale, (my - topMargin) / scale

    if mButton == 1 then
        if gameState == "mainMenu" then
            if playButton:wasClicked(engladiusFont, gameMouseX, gameMouseY) then
                gameState = "connecting"

                server_peer = client:connect("localhost:9999")
                waitingForDisconnect = false
            end
        end
    end
end
