local Field = class("Field")

local Chip = require("class.Chip")
local MonsterType = require("class.MonsterType")

function Field:initialize(settings, monsterImg, monsterQuad)
    self.settings = settings
    self.monsterImg = monsterImg
    self.monsterQuad = monsterQuad

    self.w = self.settings.mapWidth
    self.h = self.settings.mapHeight
    self.x = math.floor((love.graphics.getWidth()-(self.w*CHIPSIZE))/2)
    self.y = math.floor((love.graphics.getHeight()-(self.h*CHIPSIZE))/2)

    self.cursorX = math.ceil(self.w/2)
    self.cursorY = math.ceil(self.h/2)

    self:makeMonsterTypes()
    self:makeChips()
end


function Field:update(dt)

end

function Field:draw()
    for x = 1, self.w do
        for y = 1, self.h do
            self.map[x][y]:draw(self.x+(x-1)*CHIPSIZE, self.y+(y-1)*CHIPSIZE)
        end
    end

    if true then
        love.graphics.setColor(0.05, 0.7, 0.8)
        love.graphics.rectangle("line", self.x+(self.cursorX-1)*CHIPSIZE, self.y+(self.cursorY-1)*CHIPSIZE, CHIPSIZE, CHIPSIZE)
        love.graphics.setColor(1, 1, 1)
    end
end

function Field:makeMonsterTypes()
    self.monsterTypes = {}

    for i = 1, #self.settings.monsters do
        local exp = 2^(i-1)

        if i == 9 then
            exp = 0
        end

        table.insert(self.monsterTypes, MonsterType:new(i, self.monsterImg, self.monsterQuad[i], exp))
    end
end

function Field:makeChips()
    self.map = {}

    for x = 1, self.w do
        self.map[x] = {}

        for y = 1, self.h do
            self.map[x][y] = Chip:new(self)
        end
    end
end

function Field:distributeMonsters(notX, notY)
    for m = 1, #self.settings.monsters do
        for i = 1, self.settings.monsters[m] do
            self:placeMonster(self.monsterTypes[m], notX, notY)
        end
    end
end

function Field:calculateChips()
    for x = 1, self.w do
        for y = 1, self.h do
            local total = 0

            for yAdd = -1, 1 do
                for xAdd = -1, 1 do
                    if xAdd ~= 0 or yAdd ~= 0 then
                        local nx = x+xAdd
                        local ny = y+yAdd

                        if self:inMap(nx, ny) then
                            total = total + self.map[nx][ny]:getLevel()
                        end
                    end
                end
            end

            self.map[x][y].near = total
        end
    end
end

function Field:placeMonster(monsterType, notX, notY)
    local x, y

    repeat
        local pass = true

        x = math.random(self.w)
        y = math.random(self.h)

        if self.map[x][y].monsterType then -- don't overlap monsters
            pass = false
        end

        if FIRSTCLICKPROTECTION and (x == notX and y == notY) then -- first click protection
            pass = false
        end
    until pass

    self.map[x][y].monsterType = monsterType
end

function Field:inMap(x, y)
    return x > 0 and x < self.w+1 and y > 0 and y < self.h+1
end

function Field:open(x, y)
    if not game.active then
        game.active = true

        self:distributeMonsters(x, y)
        self:calculateChips()
    end

    local chip = self.map[x][y]

    if not chip.open then
        chip.open = true

        if chip.monsterType then
            -- Battle!
            local monsterHP = chip.monsterType.level

            repeat
                monsterHP = math.max(0, monsterHP - game.level)

                if monsterHP > 0 then
                    game.life = math.max(0, game.life - chip.monsterType.level)
                end
            until monsterHP == 0 or game.life == 0

            -- check for rip
            if game.life == 0 then -- rip
                game.over = true

            else -- not rip
                game.exp = game.exp + chip.monsterType.exp

                -- check for level up
                while game.exp >= self:getExpNextLevel(game.level) do
                    game:levelUp()
                end
            end
        end
    end
end

function Field:attemptOpen(x, y)
    local chip = self.map[x][y]

    if chip.open and chip.monsterType then
        chip.showNumber = not chip.showNumber
    end

    -- check for too high mark
    if chip.mark > game.level then
        return
    end

    self:open(x, y)

    if chip.monsterType == false and chip.near == 0 then -- mass reveal
        self:floodOpen(x, y)
    end
end

function Field:floodOpen(x, y)
    local dx = {0, 1, 1, 1, 0, -1, -1, -1} -- relative neighbor x coordinates
    local dy = {-1, -1, 0, 1, 1, 1, 0, -1} -- relative neighbor y coordinates

    local stack = {}
    table.insert(stack, {x, y})

    while (#stack > 0) do
        local x, y = unpack(table.remove(stack))

        self:open(x, y)
        for i = 1, 8 do
            nx = x + dx[i]
            ny = y + dy[i]

            if self:inMap(nx, ny) then
                if not self.map[nx][ny].open and self.map[nx][ny].near == 0 then
                    table.insert(stack, {nx, ny});
                end

                self:open(nx, ny)
            end
        end
    end
end

function Field:getExpNextLevel(level)
    if level > #self.settings.expArray then
        return math.huge
    end

    return self.settings.expArray[level]
end

function Field:toCoordinate(x, y)
    local cx = math.floor(x/CHIPSIZE) + 1
    local cy = math.floor(y/CHIPSIZE) + 1

    return cx, cy
end

function Field:mousepressed(x, y, button)
    local cx, cy = self:toCoordinate(x-self.x, y-self.y)

    if not self:inMap(cx, cy) then
        return
    end

    if button == 1 then
        self:attemptOpen(cx, cy)
    elseif button == 2 then
        self.map[cx][cy]:doCycleMark(1)
    end
end

function Field:keypressed(key, scancode)
    local x, y = love.mouse.getPosition()
    local cx, cy = self:toCoordinate(x-self.x, y-self.y)

    if scancode == "a" then
        if not self:inMap(cx, cy) then
            return
        end
        self.map[cx][cy]:doCycleMark(-1)
    elseif scancode == "d" then
        if not self:inMap(cx, cy) then
            return
        end
        self.map[cx][cy]:doCycleMark(1)
    end

    if scancode == "right" then
        self:right()
    elseif scancode == "left" then
        self:left()
    elseif scancode == "down" then
        self:down()
    elseif scancode == "up" then
        self:up()
    end

    if scancode == "space" then
        self:attemptOpen(self.cursorX, self.cursorY)
    end

    if scancode == "q" then
        self.map[self.cursorX][self.cursorY]:doCycleMark(-1)
    elseif scancode == "e" then
        self.map[self.cursorX][self.cursorY]:doCycleMark(1)
    end
end

function Field:gamepadpressed(joy, button)
    if button == "dpright" then
        self:right()
    elseif button == "dpleft" then
        self:left()
    elseif button == "dpdown" then
        self:down()
    elseif button == "dpup" then
        self:up()
    elseif button == "a" then
        self:attemptOpen(self.cursorX, self.cursorY)
    elseif button == "l" then
        self.map[self.cursorX][self.cursorY]:doCycleMark(-1)
    elseif button == "r" then
        self.map[self.cursorX][self.cursorY]:doCycleMark(1)
    end
end

function Field:right()
    if self.cursorX < self.w then
        self.cursorX = self.cursorX + 1
    end
end

function Field:left()
    if self.cursorX > 1 then
        self.cursorX = self.cursorX - 1
    end
end

function Field:down()
    if self.cursorY < self.h then
        self.cursorY = self.cursorY + 1
    end
end

function Field:up()
    if self.cursorY > 1 then
        self.cursorY = self.cursorY - 1
    end
end

return Field
