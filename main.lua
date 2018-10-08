local Chip, Game

function love.load()
    math.randomseed(os.time())
    for i = 1, 10 do
        math.random()
    end

    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineWidth(4)
    require "variables"
    class = require "lib.middleclass"

    Chip = require "class.Chip"
    Game = require "class.Game"

    presets = require "presets"

    chipClosedImg = love.graphics.newImage("img/chipClosed.png")
    chipOpenImg = love.graphics.newImage("img/chipOpen.png")

    cursorImg = love.graphics.newImage("img/cursor.png")

    -- font = love.graphics.newImageFont("img/font.png", "ABCDEFGHIJKLMNOPQRSTUVWXYZ:-*0123456789 ", 1)
    -- love.graphics.setFont(font)

    fontImg = love.graphics.newImage("img/font.png")
    fontQuads = {}

    local glyphs = "ABCDEFGHIJKLMNOPQRSTUVWXYZ:-*0123456789 "
    for i = 1, #glyphs do
        fontQuads[string.sub(glyphs, i, i)] = love.graphics.newQuad((i-1)*6+1, 0, 5, 7, 241, 7)
    end

    fontBigImg = love.graphics.newImage("img/fontbig.png")
    fontBigQuads = {}

    local glyphs = "0123456789"
    for i = 1, #glyphs do
        fontBigQuads[string.sub(glyphs, i, i)] = love.graphics.newQuad((i-1)*10+1, 0, 9, 15, 101, 15)
    end

    game = Game:new(presets[3])
end

function switchPrint(s, x, y, scale)
    scale = scale or 1
    local xAdd = 0
    for i = 1, #tostring(s) do
        love.graphics.draw(fontImg, fontQuads[string.sub(s, i, i)], x+xAdd, y, 0, scale, scale)
        xAdd = xAdd + 6*scale
    end
end

function switchPrintBig(s, x, y, scale)
    scale = scale or 1
    local xAdd = 0
    for i = 1, #tostring(s) do
        love.graphics.draw(fontBigImg, fontBigQuads[string.sub(s, i, i)], x+xAdd, y, 0, scale, scale)
        xAdd = xAdd + 10*scale
    end
end

function love.update(dt)
    dt = math.min(dt, 1)

    game:update(dt)
end

function love.draw()
    game:draw()
end

function love.mousepressed(x, y, button)
    game:mousepressed(x, y, button)
end

function love.keypressed(key, scancode)
    if key == "escape" then
        love.event.quit()
        return
    end

    game:keypressed(key, scancode)
end

function love.keyreleased(key, scancode)
    game:keyreleased(key, scancode)
end

function love.gamepadpressed(joy, button)
    game:gamepadpressed(joy, button)
end

function love.gamepadreleased(joy, button)
    game:gamepadreleased(joy, button)
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    game:touchpressed(id, x, y, dx, dy, pressure)
end
