local Chip = class("Chip")

function Chip:initialize(field)
    self.field = field

    self.open = false
    self.monsterType = false
    self.mark = 0
    self.near = 0

    self.showNumber = false
end

function Chip:draw(x, y)
    if self.open then
        love.graphics.draw(chipOpenImg, x, y)
        if self.monsterType and not self.showNumber then
            self.monsterType:draw(math.floor((CHIPSIZE-16)/2)+x, math.floor((CHIPSIZE-16)/2)+y)
        end

        if (not self.monsterType and self.near > 0) or (self.showNumber) then
            if self.showNumber then
                love.graphics.setColor(1, 0, 0)
            end
            switchPrint(self.near, x+13-#tostring(self.near)*3, y+math.floor(CHIPSIZE/2)-3)
            love.graphics.setColor(1, 1, 1)
        end
    else
        love.graphics.draw(chipClosedImg, x, y)

        if self.mark > 0 then
            love.graphics.setColor(0, 1, 0)
            switchPrint(self.mark, x+13-#tostring(self.mark)*3, y+math.floor(CHIPSIZE/2)-3)
            love.graphics.setColor(1, 1, 1)
        end
    end
end

function Chip:getLevel()
    if not self.monsterType then
        return 0
    else
        return self.monsterType.level
    end
end

function Chip:doMark(i)
    self.mark = i
end

function Chip:doCycleMark(dir)
    local new = self.mark + dir

    if new > #self.field.monsterTypes then
        new = 0
    elseif new < 0 then
        new = #self.field.monsterTypes
    end

    self:doMark(new)
end

return Chip
