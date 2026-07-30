local WIDTH, HEIGHT = 640, 360


---@diagnostic disable-next-line: duplicate-set-field
function love.load()

    love.graphics.setDefaultFilter("nearest", "nearest")

   

    gameCanvas = love.graphics.newCanvas(WIDTH, HEIGHT)

    love.window.setTitle("Engladius")
    love.window.setMode(0, 0, { fullscreen = true, fullscreentype = "desktop" })

    love.window.setVSync(1)

    love.mouse.setVisible(false)
    

    engladiusFont = love.graphics.newFont("assets/alagard.ttf", 16)
    titleFont = love.graphics.newFont("assets/alagard.ttf", 64)

    cursorImg = love.graphics.newImage("assets/cursor.png")
    
    
    
end



function gameDraw(gameMouseX, gameMouseY)
    
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1, 1)
    
    
    love.graphics.print("Engladius", WIDTH / 2 - titleFont:getWidth("Engladius") / 2, 50)


    love.graphics.draw(cursorImg, gameMouseX - 16, gameMouseY - 16, 0, 2, 2)
    
end


---@diagnostic disable-next-line: duplicate-set-field
function love.draw()

    local winWidth, winHeight = love.graphics.getDimensions()
    local scale = math.min(math.floor(winWidth / WIDTH), math.floor(winHeight / HEIGHT))

    local leftMargin = (winWidth - scale * WIDTH) / 2
    local topMargin =  (winHeight - scale * HEIGHT) / 2
    

    -- calculate scale before drawing anything so i can calculate game mouse pos

    local mx, my = love.mouse.getPosition()

    local gameMouseX, gameMouseY = (mx - leftMargin) / scale, (my - topMargin) / scale
    
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear(0, 0.2, 0.2, 1)

    

    
    

    gameDraw(gameMouseX, gameMouseY)

    
    love.graphics.setCanvas()

    -- now we use scale value
    love.graphics.draw(gameCanvas, winWidth / 2 - (scale * WIDTH / 2), winHeight / 2 - (scale * HEIGHT / 2), 0, scale, scale)
end

---@diagnostic disable-next-line: duplicate-set-field
function love.update(delta)

end

---@diagnostic disable-next-line: duplicate-set-field
function love.keypressed(key, scancode, isrepeat)


    -- Scancode is better for controls then key because it works on other keyboard layouts
    if scancode == "escape" then
        love.event.quit()
    end
end