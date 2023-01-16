
local pd <const> = playdate
local gfx <const> = playdate.graphics

class('Player').extends(AnimatedSprite)

function Player:init(x, y, gameManager)
    self.gameManager = gameManager

    local playerImageTable = gfx.imagetable.new("images/player-table-16-16")
    Player.super.init(self, playerImageTable)

    self:addState("idle", 1, 1)
    self:addState("run", 1, 3, {tickStep = 4})
    self:addState("jump", 4, 4)
    self:addState("dash", 4, 4)

    self.xVelocity = 0
    self.yVelocity = 0
    self.gravity = 0.8
    self.fallingGravity = 1.0
    self.maxSpeed = 2
    self.startVelocity = 1.5
    self.jumpVelocity = -6
    self.doubleJumpAvailable = true
    self.doubleJumpDelayMax = 4
    self.doubleJumpDelay = self.doubleJumpDelayMax

    self.dead = false

    self.friction = 0.5
    self.drag = 0.1
    self.acceleration = 0.5

    self.touchingGround = true
    self.touchingCeiling = false
    self.touchingWall = false

    -- Dash
    self.dashAvailable = true
    self.dashSpeed = 7
    self.dashMinimumSpeed = 5
    self.dashDrag = 0.8
    self.dashHeightBoost = -3
    self.dashGravity = 0.5

    -- Abilities
    self.doubleJumpAbility = true
    self.dashAbility = true

    self:setCollideRect(3, 3, 10, 13)

    self:setZIndex(Z_INDEXES.PLAYER)

    self:playAnimation()
    self:moveTo(x, y)
end

function Player:collisionResponse(other)
    local tag = other:getTag()
    if tag == TAGS.Pickup then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end

function Player:update()
    if self.dead then
        return
    end

    self:updateAnimation()

    if self.currentState == "idle" then
        if pd.buttonIsPressed(pd.kButtonA) then
            self:changeToJumpState()
        elseif pd.buttonJustPressed(pd.kButtonB) and self.dashAvailable and self.dashAbility then
            self:changeToDashState()
        elseif pd.buttonIsPressed(pd.kButtonLeft) then
            self:changeToRunState("left")
        elseif pd.buttonIsPressed(pd.kButtonRight) then
            self:changeToRunState("right")
        end
        self:applyFriction()
        self:applyGravity()
    elseif self.currentState == "run" then
        if pd.buttonIsPressed(pd.kButtonA)then
            self:changeToJumpState()
        elseif pd.buttonJustPressed(pd.kButtonB) and self.dashAbility then
            self:changeToDashState()
        elseif pd.buttonIsPressed(pd.kButtonLeft) then
            self:accelerateLeft()
        elseif pd.buttonIsPressed(pd.kButtonRight) then
            self:accelerateRight()
        else
            self:changeState("idle")
        end
        self:applyGravity()
    elseif self.currentState == "jump" then
        if pd.buttonJustPressed(pd.kButtonB) and self.dashAvailable and self.dashAbility then
            self:changeToDashState()
        else
            self:handleJumpPhysics()
            if self.yVelocity == 0 then
                if pd.buttonIsPressed(pd.kButtonLeft) then
                    self:changeToRunState("left")
                elseif pd.buttonIsPressed(pd.kButtonRight) then
                    self:changeToRunState("right")
                else
                    self:changeState("idle")
                end
            end
            self:applyGravity()
        end
    elseif self.currentState == "dash" then
        if self.xVelocity > 0 then
            self.xVelocity -= self.dashDrag
        elseif self.xVelocity < 0 then
            self.xVelocity += self.dashDrag
        end

        self.yVelocity += self.dashGravity

        if math.abs(self.xVelocity) <= self.dashMinimumSpeed then
            self:changeState("jump")
        end
    end

    self:handleMovementAndCollisions()

    if self.xVelocity < 0 then
        self.globalFlip = 1
    elseif self.xVelocity > 0 then
        self.globalFlip = 0
    end

	if self.x < 0 then
		self.gameManager:enterRoom("west")
    elseif self.x > 400  then
        self.gameManager:enterRoom("east")
    elseif self.y < 0 then
        self.gameManager:enterRoom("north")
    elseif self.y > 240 then
        self.gameManager:enterRoom("south")
	end
end

function Player:handleMovementAndCollisions()
    local _, _, collisions, length = self:moveWithCollisions(self.x + self.xVelocity, self.y + self.yVelocity)
    self.touchingCeiling = false
    self.touchingWall = false
    self.interactingObject = nil

    local touchedGround = false
    local died = false
    for i=1,length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionTag = collision.other:getTag()
        if collisionType == gfx.sprite.kCollisionTypeOverlap then
            if collisionTag == TAGS.Pickup then
                collision.other:pickUp()
            end
        else
            if collision.normal.y == -1 then
                touchedGround = true
            elseif collision.normal.y == 1 then
                self.touchingCeiling = true
            end
            if collision.normal.x == -1 or collision.normal.x == 1 then
                -- Wall Jump?
            end
        end

        if collisionTag == TAGS.Hazard then
            died = true
        end
    end

    self.touchingGround = touchedGround
    if self.touchingGround then
        self.yVelocity = 0
        self.doubleJumpAvailable = true
        self.dashAvailable = true
    end

    if self.touchingCeiling then
        self.yVelocity = 0
    end

    if self.touchingWall then
        self.xVelocity = 0
    end

    if died then
        self:die()
    end
end

function Player:die()
    self.xVelocity = 0
    self.yVelocity = 0
    self.dead = true
    self:setCollisionsEnabled(false)
    pd.timer.performAfterDelay(200, function()
        self:setVisible(false)
        pd.timer.performAfterDelay(400, function()
            self:setVisible(true)
            self:setCollisionsEnabled(true)
            self.gameManager:resetPlayer()
            self.dead = false
        end)
    end)
end

function Player:changeToJumpState()
    self.yVelocity = self.jumpVelocity
    self.doubleJumpDelay = self.doubleJumpDelayMax
    self:changeState("jump")
end

function Player:changeToDashState()
    self.dashAvailable = false
    self.yVelocity = self.dashHeightBoost
    if pd.buttonIsPressed(pd.kButtonLeft) then
        self.xVelocity = -self.dashSpeed
        self.globalFlip = 1
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self.xVelocity = self.dashSpeed
        self.globalFlip = 0
    else
        if self.globalFlip == 1 then
            self.xVelocity = -self.dashSpeed
        else
            self.xVelocity = self.dashSpeed
        end
    end
    self:changeState("dash")
end

function Player:changeToRunState(direction)
    if direction == "left" then
        self.xVelocity = -self.startVelocity
            self.globalFlip = 1
    elseif direction == "right" then
        self.xVelocity = self.startVelocity
        self.globalFlip = 0
    end
    self:changeState("run")
end

function Player:handleJumpPhysics()
    self.doubleJumpDelay -= 1
    if self.doubleJumpDelay <= 0 then
        self.doubleJumpDelay = 0
    end
    if pd.buttonJustPressed(pd.kButtonA) and self.doubleJumpAvailable and self.doubleJumpAbility and self.doubleJumpDelay <= 0 then
        self.doubleJumpAvailable = false
        self:changeToJumpState()
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        self:accelerateLeft()
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self:accelerateRight()
    else
        self:applyDrag()
    end
end

function Player:accelerateLeft()
    if self.xVelocity > 0 then
        self.xVelocity = 0
    end
    self.xVelocity -= self.acceleration
    if self.xVelocity <= -self.maxSpeed then
        self.xVelocity = -self.maxSpeed
    end
end

function Player:accelerateRight()
    if self.xVelocity < 0 then
        self.xVelocity = 0
    end
    self.xVelocity += self.acceleration
    if self.xVelocity >= self.maxSpeed then
        self.xVelocity = self.maxSpeed
    end
end

function Player:applyGravity()
    if self.yVelocity < 0 then
        self.yVelocity += self.gravity
    else
        self.yVelocity += self.fallingGravity
    end
end

function Player:applyDrag()
    if self.xVelocity > 0 then
        self.xVelocity -= self.drag
    elseif self.xVelocity < 0 then
        self.xVelocity += self.drag
    end

    if math.abs(self.xVelocity) < 0.5 then
        self.xVelocity = 0
    end
end

function Player:applyFriction()
    if self.xVelocity > 0 then
        self.xVelocity -= self.friction
    elseif self.xVelocity < 0 then
        self.xVelocity += self.friction
    end

    if math.abs(self.xVelocity) < 0.5 then
        self.xVelocity = 0
    end
end
