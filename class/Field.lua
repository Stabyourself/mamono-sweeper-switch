local Field = class("Field")

local KeyRepeat = require("class.KeyRepeat")
local BouncyThing = require("class.BouncyThing")
local Chip = require("class.Chip")
local MonsterType = require("class.MonsterType")

local cursorColor = {0.05, 0.7, 0.8}

function Field:initialize(settings, monsterImg, monsterQuad)
    self.settings = settings
    self.monsterImg = monsterImg
    self.monsterQuad = monsterQuad

    self.w = self.settings.mapWidth
    self.h = self.settings.mapHeight

    self.cursorX = math.ceil(self.w/2)
    self.cursorY = math.ceil(self.h/2)

    self.cursorTimer = 0
    self.cursorVisible = true

    -- key repeats
    local delay = 0.3
    local interval = 0.05

    self.keyRepeats = {
        left = KeyRepeat:new(delay, interval, function() self:left() end),
        right = KeyRepeat:new(delay, interval, function() self:right() end),
        down = KeyRepeat:new(delay, interval, function() self:down() end),
        up = KeyRepeat:new(delay, interval, function() self:up() end),
        markDown = KeyRepeat:new(0.3, 0.1, function() self:markDown() end),
        markUp = KeyRepeat:new(0.3, 0.1, function() self:markUp() end),
        mark = KeyRepeat:new(math.huge, 1, function() end)
    }

    self.monsterCounts = {}

    for i = 1, #self.settings.monsters do
        self.monsterCounts[i] = (self.monsterCounts[i] or 0) + self.settings.monsters[i]
    end

    self:makeMonsterTypes()
    self:makeChips()
end


function Field:update(dt)
    for _, v in pairs(self.keyRepeats) do
        v:update(dt)
    end

    self.cursorTimer = self.cursorTimer + dt*5

    if game.won then
        for _, v in ipairs(self.bouncyThings) do
            v:update(dt)
        end
    end
end

function Field:draw(x, y)
    if not game.won then -- regular field
        for cx = 1, self.w do
            for cy = 1, self.h do
                self.map[cx][cy]:draw(x+(cx-1)*CHIPSIZE, y+(cy-1)*CHIPSIZE)
            end
        end

        if self.cursorVisible then
            local colors = {}
            local mul = (math.sin(self.cursorTimer)+1)/2

            for i = 1, 3 do
                colors[i] = cursorColor[i] + (1-cursorColor[i])*mul
            end

            love.graphics.setColor(colors)
            love.graphics.draw(cursorImg, x+(self.cursorX-1)*CHIPSIZE-2, y+(self.cursorY-1)*CHIPSIZE-2)
            love.graphics.setColor(1, 1, 1)
        end
    else -- bouncy stuff
        for _, v in ipairs(self.bouncyThings) do
            v:draw(x, y)
        end
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

function Field:win()
    game.over = true
    game.won = true

    self.bouncyThings = {}

    -- transform chips into bouncy things
    for cy = 1, self.h do
        for cx = 1, self.w do
            local chip = self.map[cx][cy]

            if chip.monsterType then
                local x, y = self:fromCoordinate(cx, cy)
                table.insert(self.bouncyThings, BouncyThing:new(x-8, y-8, chip.monsterType, self.h*CHIPSIZE, 0, self.w*CHIPSIZE))
            end
        end
    end
end

function Field:lose()
    for _, v in pairs(self.keyRepeats) do
        v:up()
    end

    game.over = true
    game:flash(1, 0, 0)
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
            local gotDamage = false

            repeat
                monsterHP = math.max(0, monsterHP - game.level)

                if monsterHP > 0 then
                    game.life = math.max(0, game.life - chip.monsterType.level)
                    gotDamage = true
                end
            until monsterHP == 0 or game.life == 0

            if gotDamage then
                game:shake()
            end

            self.monsterCounts[chip.monsterType.level] = self.monsterCounts[chip.monsterType.level] - 1

            -- check for rip
            if game.life == 0 then -- rip
                self:lose()

            else -- not rip
                game.exp = game.exp + chip.monsterType.exp

                -- check for level up
                while game.exp >= self:getExpNextLevel(game.level) do
                    game:levelUp()
                end

                -- check for win
                local win = true
                for _, v in ipairs(self.monsterCounts) do
                    if v > 0 then
                        win = false
                    end
                end

                if win then
                    self:win()
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

function Field:fromCoordinate(cx, cy)
    local x = (cx-.5)*CHIPSIZE
    local y = (cy-.5)*CHIPSIZE

    return x, y
end

function Field:mousepressed(x, y, button)
    local cx, cy = self:toCoordinate(x-game.fieldX, y-game.fieldY)

    if not self:inMap(cx, cy) then
        return
    end

    self.cursorX = cx
    self.cursorY = cy

    if button == 1 then
        self:attemptOpen(cx, cy)
    elseif button == 2 then
        self.map[cx][cy]:doCycleMark(1)
    end
end

function Field:keypressed(key, scancode)
    self.cursorVisible = true

    local x, y = love.mouse.getPosition()
    local cx, cy = self:toCoordinate(x-game.fieldX, y-game.fieldY)

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
        self.keyRepeats.right:down()
    elseif scancode == "left" then
        self:left()
        self.keyRepeats.left:down()
    elseif scancode == "down" then
        self:down()
        self.keyRepeats.down:down()
    elseif scancode == "up" then
        self:up()
        self.keyRepeats.up:down()
    end

    if scancode == "space" then
        self:attemptOpen(self.cursorX, self.cursorY)
        self.keyRepeats.mark:down()
    end

    if scancode == "q" then
        self:markDown()
        self.keyRepeats.markDown:down()
    elseif scancode == "e" then
        self:markUp()
        self.keyRepeats.markUp:down()
    end
end

function Field:keyreleased(key, scancode)
    if scancode == "right" then
        self.keyRepeats.right:up()
    elseif scancode == "left" then
        self.keyRepeats.left:up()
    elseif scancode == "down" then
        self.keyRepeats.down:up()
    elseif scancode == "up" then
        self.keyRepeats.up:up()

    elseif scancode == "space" then
        self.keyRepeats.mark:up()

    elseif scancode == "q" then
        self.keyRepeats.markDown:up()
    elseif scancode == "e" then
        self.keyRepeats.markUp:up()
    end
end

function Field:gamepadpressed(joy, button)
    self.cursorVisible = true

    if button == "dpright" then
        self:right()
        self.keyRepeats.right:down()
    elseif button == "dpleft" then
        self:left()
        self.keyRepeats.left:down()
    elseif button == "dpdown" then
        self:down()
        self.keyRepeats.down:down()
    elseif button == "dpup" then
        self:up()
        self.keyRepeats.up:down()

    elseif button == "l" then
        self:markDown()
        self.keyRepeats.markDown:down()
    elseif button == "r" then
        self:markUp()
        self.keyRepeats.markUp:down()

    elseif button == "a" then
        self:attemptOpen(self.cursorX, self.cursorY)
        self.keyRepeats.mark:down()
    end
end

function Field:gamepadreleased(joy, button)
    if button == "dpright" then
        self.keyRepeats.right:up()
    elseif button == "dpleft" then
        self.keyRepeats.left:up()
    elseif button == "dpdown" then
        self.keyRepeats.down:up()
    elseif button == "dpup" then
        self.keyRepeats.up:up()

    elseif button == "l" then
        self.keyRepeats.markDown:up()
    elseif button == "r" then
        self.keyRepeats.markUp:up()

    elseif button == "a" then
        self.keyRepeats.mark:up()
    end
end

function Field:markDown()
    self.map[self.cursorX][self.cursorY]:doCycleMark(-1)
end

function Field:markUp()
    self.map[self.cursorX][self.cursorY]:doCycleMark(1)
end

function Field:right()
    if self.cursorX < self.w then
        self.cursorX = self.cursorX + 1
    end

    if self.keyRepeats.mark.pressed then
        self:attemptOpen(self.cursorX, self.cursorY)
    end
end

function Field:left()
    if self.cursorX > 1 then
        self.cursorX = self.cursorX - 1
    end

    if self.keyRepeats.mark.pressed then
        self:attemptOpen(self.cursorX, self.cursorY)
    end
end

function Field:down()
    if self.cursorY < self.h then
        self.cursorY = self.cursorY + 1
    end

    if self.keyRepeats.mark.pressed then
        self:attemptOpen(self.cursorX, self.cursorY)
    end
end

function Field:up()
    if self.cursorY > 1 then
        self.cursorY = self.cursorY - 1
    end

    if self.keyRepeats.mark.pressed then
        self:attemptOpen(self.cursorX, self.cursorY)
    end
end

return Field
