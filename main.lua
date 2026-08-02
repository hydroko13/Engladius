local vers = "0.0.1-dev"



local button = require("gui.Button")
local enet = require("enet")
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



        love.graphics.translate(math.round(camoffsetx), math.round(camoffsety))

        for i = -50, 50, 1 do
            for j = -50, 50, 1 do
                love.graphics.draw(grassImage, math.round(i * grassImage:getWidth()),
                    math.round(j * grassImage:getHeight()))
            end
        end

        for player_id, server_player in pairs(server_players) do
            love.graphics.draw(playerImage, math.round(server_player.x + playerImage:getWidth() / 2),
                math.round(server_player.y + playerImage:getHeight() / 2))
        end

        if player then
            love.graphics.draw(playerImage, math.round(player.x - playerImage:getWidth() / 2),
                math.round(player.y - playerImage:getHeight() / 2))
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
        local pos_packet_string = love.data.pack("string", "<ff", player.x, player.y)
        server_peer:send("p" .. pos_packet_string, 0, "unreliable")
    end
end

function joined()
    player = { x = 0, y = 0 }
end

---@diagnostic disable-next-line: duplicate-set-field
function love.update(delta)
    if gameState == "inGame" then
        tick_timer = tick_timer + delta
        if tick_timer >= 1.0 / tick_rate then
            tick = tick + 1
            tick_timer = 0.0
            ontick()
        end

        if player then
            camera.x = camera.x + (player.x - camera.x) * delta * 5.5
            camera.y = camera.y + (player.y - camera.y) * delta * 5.5


            if love.keyboard.isDown("w") then
                player.y = player.y - 130 * delta
            end
            if love.keyboard.isDown("s") then
                player.y = player.y + 130 * delta
            end
            if love.keyboard.isDown("a") then
                player.x = player.x - 130 * delta
            end
            if love.keyboard.isDown("d") then
                player.x = player.x + 130 * delta
            end
        end
    end

    if not client then return end
    if not server_peer then return end

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
            end
        end


        event = client:service(0)
    end


    for player_id, server_player in pairs(server_players) do
        server_player.x = lerp(server_player.x, server_player.target_x, delta * 45)
        server_player.y = lerp(server_player.y, server_player.target_y, delta * 45)
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
