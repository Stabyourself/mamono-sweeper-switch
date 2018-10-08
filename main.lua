local Chip, Game, presets

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineWidth(4)
    require "variables"
    class = require "lib.middleclass"

    Chip = require "class.Chip"
    Game = require "class.Game"

    presets = require "presets"

    chipClosedImg = love.graphics.newImage("img/chipClosed.png")
    chipOpenImg = love.graphics.newImage("img/chipOpen.png")

    -- font = love.graphics.newImageFont("img/font.png", "ABCDEFGHIJKLMNOPQRSTUVWXYZ:-*0123456789 ", 1)
    -- love.graphics.setFont(font)

    fontImg = love.graphics.newImage("img/font.png")
    fontQuads = {}

    local glyphs = "ABCDEFGHIJKLMNOPQRSTUVWXYZ:-*0123456789 "
    for i = 1, #glyphs do
        fontQuads[string.sub(glyphs, i, i)] = love.graphics.newQuad((i-1)*6+1, 0, 5, 7, 241, 7)
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

function love.update(dt)
    game:update(dt)
end

function love.draw()
    game:draw()
end

function love.gamepadpressed(joy, button)
    if game.over then
        game = Game:new(presets[3])
    else
        game:gamepadpressed(joy, button)
    end
end

function love.mousepressed(x, y, button)
    if game.over then
        game = Game:new(presets[3])
    else
        game:mousepressed(x, y, button)
    end
end

function love.keypressed(key, scancode)
    if key == "escape" then
        love.event.quit()
        return
    end

    game:keypressed(key, scancode)
end
