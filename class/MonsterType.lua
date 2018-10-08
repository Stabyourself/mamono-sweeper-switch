local MonsterType = class("MonsterType")

function MonsterType:initialize(level, img, quad, exp)
    self.level = level
    self.img = img
    self.quad = quad
    self.exp = exp
end

function MonsterType:draw(x, y, scale)
    scale = scale or 1
    love.graphics.draw(self.img, self.quad, x, y, 0, scale, scale)
end

return MonsterType
