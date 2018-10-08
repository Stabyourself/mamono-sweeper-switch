local BouncyThing = class("BouncyThing")

function BouncyThing:initialize(x, y, monsterType, bottom, left, right)
    self.x = x
    self.y = y

    self.monsterType = monsterType

    self.bottom = bottom
    self.left = left
    self.right = right

    self.speedX = 0
    self.speedY = 0
end

function BouncyThing:update(dt)
    self.x = self.x + self.speedX*dt
    self.y = self.y + self.speedY*dt
    self.speedY = self.speedY + dt*720

    if self.y + 16 > self.bottom then
        self.y = self.bottom - 16
        self.speedX = (math.random()*2-1)*360
        self.speedY = -math.random() * 900
    end

    if self.x < self.left then
        self.x = self.left
        self.speedX = -self.speedX
    end

    if self.x + CHIPSIZE > self.right then
        self.x = self.right - CHIPSIZE
        self.speedX = -self.speedX
    end
end

function BouncyThing:draw(x, y)
    self.monsterType:draw(self.x+x, self.y+y)
end

return BouncyThing
