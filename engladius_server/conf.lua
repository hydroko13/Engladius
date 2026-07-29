
---@diagnostic disable-next-line: duplicate-set-field
function love.conf(t)
    t.window = nil
    t.modules.window = false
    t.modules.graphics = false
    t.modules.sound = false
    t.modules.audio = false
    t.modules.joystick = false
    t.modules.touch = false
end