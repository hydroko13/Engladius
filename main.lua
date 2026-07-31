local vers = "0.0.1-dev"



local button = require("gui.Button")
local enet = require("enet")
local server_peer
local client
local waitingForDisconnect = false
local connected = false

local player
local camera = {x = 0, y = 0}

local WIDTH, HEIGHT = 640, 360

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
        
    
        if player then
            love.graphics.draw(playerImage, math.round(player.x - playerImage:getWidth() / 2), math.round(player.y - playerImage:getHeight() / 2))
        end

        love.graphics.pop()
    end

   




end


---@diagnostic disable-next-line: duplicate-set-field
function love.draw()

    local winWidth, winHeight = love.graphics.getDimensions()
    local scale = math.min(winWidth / WIDTH,winHeight / HEIGHT)

    local leftMargin = (winWidth - scale * WIDTH) / 2
    local topMargin =  (winHeight - scale * HEIGHT) / 2
    

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
    love.graphics.draw(gameCanvas, winWidth / 2 - (scale * WIDTH / 2), winHeight / 2 - (scale * HEIGHT / 2), 0, scale, scale)
end


function joined()
    player = {x = 0, y = 0}
end

---@diagnostic disable-next-line: duplicate-set-field
function love.update(delta)

    if gameState == "inGame" then
        if player then
            camera.x = camera.x + (player.x - camera.x) * delta * 7.5
            camera.y = camera.y + (player.y - camera.y) * delta * 7.5


            if love.keyboard.isDown("w") then
                player.y = player.y - 60 * delta
            end
            if love.keyboard.isDown("s") then
                player.y = player.y + 60 * delta
            end
            if love.keyboard.isDown("a") then
                player.x = player.x - 60 * delta
            end
            if love.keyboard.isDown("d") then
                player.x = player.x + 60 * delta
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
            print(event.data)
        end



        event = client:service(0)
    end
    
    
end

---@diagnostic disable-next-line: duplicate-set-field
function love.quit()

    if waitingForDisconnect then return false end
    
    if not server_peer then return false end

    if server_peer then
        
        if not connected then
        
            return false
            
        end
        
    end
    
    
        
    server_peer:disconnect()
    waitingForDisconnect = true
    return true
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
    local scale = math.min(winWidth / WIDTH,winHeight / HEIGHT)

    local leftMargin = (winWidth - scale * WIDTH) / 2
    local topMargin =  (winHeight - scale * HEIGHT) / 2
    
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