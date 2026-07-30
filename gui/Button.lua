local btn = {
   
}

function wasClicked(self, font, mousex, mousey)
    love.graphics.setFont(font)
    

    local btnWidth = font:getWidth(self.text) + 15
    local btnHeight = font:getHeight(self.text) + 8
    local hovered = false

    if mousex >= self.centerx - btnWidth / 2 and mousex <= self.centerx + btnWidth / 2 and mousey >= self.centery - btnHeight / 2 and mousey <= self.centery + btnHeight / 2 then
        hovered = true
    end
    
    return hovered
end

function drawButton(self, font, mousex, mousey)
    love.graphics.setFont(font)
    

    local btnWidth = font:getWidth(self.text) + 15
    local btnHeight = font:getHeight(self.text) + 8
    local hovered = false

    if mousex >= self.centerx - btnWidth / 2 and mousex <= self.centerx + btnWidth / 2 and mousey >= self.centery - btnHeight / 2 and mousey <= self.centery + btnHeight / 2 then
       hovered = true
    end

    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", self.centerx - btnWidth / 2,
        self.centery - btnHeight / 2, btnWidth, btnHeight, 6, 6)
    if hovered then
         love.graphics.setColor(1, 1, 1, 1)
    else
       
        love.graphics.setColor(0.05, 0.05, 0.05, 1)
    end
    love.graphics.setLineWidth(1.9)
    love.graphics.rectangle("line", self.centerx - btnWidth / 2,
        self.centery - btnHeight / 2, btnWidth, btnHeight, 6, 6)
     love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(self.text, self.centerx - font:getWidth(self.text) / 2, self.centery - font:getHeight(self.text) / 2)
end

function btn.newButton(centerx, centery, text)
    return {
        centerx = centerx,
        centery = centery,
        text = text,
        drawButton = drawButton,
        wasClicked = wasClicked
    }
end




return btn