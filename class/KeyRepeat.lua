local KeyRepeat = class("KeyRepeat")

function KeyRepeat:initialize(delay, interval, func)
	self.key = key
	self.delay = delay
	self.interval = interval
	self.func = func

	self.timer = 0
	self.pressed = false
end

function KeyRepeat:update(dt)
	if self.pressed then
		self.timer = self.timer + dt

		while self.timer >= self.delay + self.interval do
			self.timer = self.timer - self.interval

			self.func()
		end

		self.tickTimer = 0
	end
end

function KeyRepeat:down()
	self.pressed = true
	self.timer = 0
end

function KeyRepeat:up()
	self.pressed = false
	self.timer = 0
end

function KeyRepeat:isFiring()
	return self.timer >= self.delay
end

return KeyRepeat
