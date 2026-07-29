local WIDTH, HEIGHT = 640, 360


---@diagnostic disable-next-line: duplicate-set-field
function love.load()

    love.graphics.setDefaultFilter("nearest", "nearest")

    gameCanvas = love.graphics.newCanvas(WIDTH, HEIGHT)

    love.window.setTitle("Engladius")
    love.window.setMode(0, 0, { fullscreen = true, fullscreentype = "desktop" })
    

    

    engladiusFont = love.graphics.newFont("assets/alagard.ttf", 16)
    titleFont = love.graphics.newFont("assets/alagard.ttf", 64)
    
    
end



function gameDraw()
    
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1, 1)
    
    
    love.graphics.print("Engladius", WIDTH / 2 - titleFont:getWidth("Engladius") / 2, 50)

    
end


---@diagnostic disable-next-line: duplicate-set-field
function love.draw()
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear(0, 0.2, 0.2, 1)


    gameDraw()

    
    love.graphics.setCanvas()

    local winWidth, winHeight = love.graphics.getDimensions()
    local scale = math.min(winWidth / WIDTH, winHeight / HEIGHT)
    love.graphics.draw(gameCanvas, 0, 0, 0, scale, scale)
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