local gfx <const> = playdate.graphics

local spikeImage <const> = gfx.image.new("images/spike")

class('Spike').extends(gfx.sprite)

function Spike:init(x, y)
    self:setZIndex(Z_INDEXES.Hazard)
    self:setImage(spikeImage)
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.Hazard)
    self:setCollideRect(2, 9, 12, 7)
end