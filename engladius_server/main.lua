io.stdout:setvbuf("no")

---@diagnostic disable-next-line: duplicate-set-field
function love.load()
    print("Engladius Server Software (ESS) version 0.0.1-dev")
    love.event.quit()
end