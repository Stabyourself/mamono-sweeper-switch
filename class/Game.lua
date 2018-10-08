local Game = class("Game")

local Field = require "class.Field"


local monsterImg = love.graphics.newImage("img/monsters.png")
local monsterQuad = {}
for i = 1, 9 do
    table.insert(monsterQuad, love.graphics.newQuad((i-1)*16, 0, 16, 16, 144, 16))
end

function Game:initialize(settings)
    self.field = Field:new(settings, monsterImg, monsterQuad)

    self.life = settings.life
    self.level = settings.level
    self.exp = settings.exp
    self.expArray = settings.expArray
    self.type = settings.type

    self.timer = 0
    self.active = false
    self.over = false
end

function Game:levelUp()
    self.level = self.level + 1
end

function Game:update(dt)
    self.field:update(dt)

    if self.active and not self.over then
        self.timer = self.timer + dt
    end
end

function Game:draw()
    self.field:draw()

    -- info
    local next = self.field:getExpNextLevel(self.level)

    if next == math.huge then
        next = "-"
    end

    local s = string.format("LV:%s HP:%s EX:%s NE:%s", self.level, self.life, self.exp, next)

    switchPrint(s, self.field.x, (self.field.y-32), 4)

    -- time
    local s = string.format("TIME:%d", math.floor(self.timer))

    switchPrint(s, (self.field.x+self.field.w*CHIPSIZE) - #tostring(s)*24, (self.field.y-32), 4)

    -- monster counts
    for i = 1, #self.field.monsterTypes do
        love.graphics.push()
        local x = love.graphics.getWidth() - (#self.field.monsterTypes/2-i)*142 - 768
        local y = love.graphics.getHeight()-42

        self.field.monsterTypes[i]:draw(x, y, 2)
        local s = string.format("LV%s:*%d", i, 14)
        switchPrint(s, x+32, y+10, 2)
        love.graphics.pop()
    end
end

function Game:gamepadpressed(joy, button)
    self.field:gamepadpressed(joy, button)
end

function Game:mousepressed(x, y, button)
    self.field:mousepressed(x, y, button)
end

function Game:keypressed(key, scancode)
    self.field:keypressed(key, scancode)
end

return Game
