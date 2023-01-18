local gfx <const> = playdate.graphics

local spikeballImage <const> = gfx.image.new("images/spikeball")

class('Spikeball').extends(gfx.sprite)

function Spikeball:init(x, y, entity)
    self:setZIndex(Z_INDEXES.Hazard)
    self:setImage(spikeballImage)
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.Hazard)
    self:setCollideRect(4, 4, 8, 8)

    local fields = entity.fields
    self.xVelocity = fields.xVelocity
    self.yVelocity = fields.yVelocity
end

function Spikeball:collisionResponse(other)
    if other:getTag() == TAGS.Player then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeBounce
end

function Spikeball:update()
    local _, _, collisions, length = self:moveWithCollisions(self.x + self.xVelocity, self.y + self.yVelocity)
    local hitWall = false
    for i=1,length do
        local collision = collisions[i]
        if collision.other:getTag() ~= TAGS.Player then
            hitWall = true
        end
    end

    if hitWall then
        self.xVelocity *= -1
        self.yVelocity *= -1
    end
end