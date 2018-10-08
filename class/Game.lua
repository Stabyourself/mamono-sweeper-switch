local Game = class("Game")

local Field = require "class.Field"


local monsterImg = love.graphics.newImage("img/monsters.png")
local monsterQuad = {}
for i = 1, 9 do
    table.insert(monsterQuad, love.graphics.newQuad((i-1)*16, 0, 16, 16, 144, 16))
end

local shakeTime = 0.15
local flashTime = 0.25
local shakeIntensity = 6

function Game:initialize(settings)
    self.fieldX = math.floor((love.graphics.getWidth()-(settings.mapWidth*CHIPSIZE))/2)
    self.fieldY = math.floor((love.graphics.getHeight()-(settings.mapHeight*CHIPSIZE))/2)

    self.field = Field:new(settings, monsterImg, monsterQuad)

    self.life = settings.life
    self.level = settings.level
    self.exp = settings.exp
    self.expArray = settings.expArray
    self.type = settings.type

    self.timer = 0
    self.active = false
    self.over = false
    self.won = false

    self.shakeTimer = shakeTime
    self.flashTimer = flashTime
end

function Game:update(dt)
    self.field:update(dt)

    if self.active and not self.over then
        self.timer = self.timer + dt
    end

    if self.flashTimer < flashTime then
        self.flashTimer = math.min(flashTime, self.flashTimer+dt)
    end

    if self.shakeTimer < shakeTime then
        self.shakeTimer = math.min(shakeTime, self.shakeTimer+dt)
    end
end

function Game:draw()
    local offX = 0
    local offY = 0

    if self.shakeTimer < shakeTime then
        offX = (math.random()*2-1)*shakeIntensity
        offY = (math.random()*2-1)*shakeIntensity
    end

    self.field:draw(self.fieldX+offX, self.fieldY+offY)

    -- info
    local next = self.field:getExpNextLevel(self.level)

    if next == math.huge then
        next = "-"
    end

    local s = string.format("LV:%s HP:%s EX:%s NE:%s", self.level, self.life, self.exp, next)

    switchPrint(s, self.fieldX, (self.fieldY-32), 4)

    -- time
    local s = string.format("TIME:%d", math.floor(self.timer))

    switchPrint(s, (self.fieldX+self.field.w*CHIPSIZE) - #tostring(s)*24, (self.fieldY-32), 4)

    -- monster counts
    for i = 1, #self.field.monsterTypes do
        love.graphics.push()
        local x = love.graphics.getWidth() - (#self.field.monsterTypes/2-i)*142 - 768
        local y = love.graphics.getHeight()-42

        self.field.monsterTypes[i]:draw(x, y, 2)
        local s = string.format("LV%s:*%d", i, self.field.monsterCounts[i])
        switchPrint(s, x+32, y+10, 2)
        love.graphics.pop()
    end

    -- flash
    if self.flashTimer < flashTime then
        local a = 1-self.flashTimer/flashTime

        love.graphics.setColor(self.flashColor[1], self.flashColor[2], self.flashColor[3], a)

        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

        love.graphics.setColor(1, 1, 1)
    end
end

function Game:levelUp()
    self.level = self.level + 1
    self:flash(0, 1, 0)
end

function Game:flash(r, g, b)
    self.flashColor = {r, g, b}
    self.flashTimer = 0
end

function Game:shake()
    self.shakeTimer = 0
end

function Game:gamepadpressed(joy, button)
    if game.over then
        if (button == "a") then
            game = Game:new(presets[3])
        end
    else
        self.field:gamepadpressed(joy, button)
    end
end

function Game:gamepadreleased(joy, button)
    self.field:gamepadreleased(joy, button)
end

function Game:mousepressed(x, y, button)
    if game.over then
        game = Game:new(presets[3])
    else
        self.field:mousepressed(x, y, button)
    end
end

function Game:touchpressed(id, x, y, dx, dy, pressure)
    if game.over then
        game = Game:new(presets[3])
    else
        self.field:mousepressed(x, y, 1)
    end
end

function Game:keypressed(key, scancode)
    if game.over then
        if scancode == "space" then
            game = Game:new(presets[3])
        end
    else
        self.field:keypressed(key, scancode)
    end
end

function Game:keyreleased(key, scancode)
    self.field:keyreleased(key, scancode)
end

return Game
