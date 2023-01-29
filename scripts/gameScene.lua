local pd <const> = playdate
local gfx <const> = playdate.graphics

local ldtk <const> = LDtk

TAGS = {
    Pickup = 1,
    Player = 2,
    Hazard = 3
}

Z_INDEXES = {
    Hazard = 20,
    Pickup = 50,
    Player = 100
}

local usePrecomputedLevels = not pd.isSimulator

ldtk.load("levels/world.ldtk", usePrecomputedLevels)

if pd.isSimulator then
    ldtk.export_to_lua_files()
end

class('GameScene').extends()

function GameScene:init()
    self:goToLevel("Level_0")
    self.spawnX = 3 * 16
    self.spawnY = 11 * 16

    self.player = Player(self.spawnX, self.spawnY, self)
end

function GameScene:resetPlayer()
    self.player:moveTo(self.spawnX, self.spawnY)
end

function GameScene:enterRoom(direction)
    local level = ldtk.get_neighbours(self.levelName, direction)[1]
    self:goToLevel(level)
    self.player:add()
    local spawnX, spawnY
    if direction == "north" then
        spawnX, spawnY = self.player.x, 240
    elseif direction == "south" then
        spawnX, spawnY = self.player.x, 0
    elseif direction == "east" then
        spawnX, spawnY = 0, self.player.y
    elseif direction == "west" then
        spawnX, spawnY = 400, self.player.y
    end
    self.player:moveTo(spawnX, spawnY)
    self.spawnX = spawnX
    self.spawnY = spawnY
end

function GameScene:goToLevel(levelName)
    if not levelName then return end

    self.levelName = levelName

    gfx.sprite.removeAll()

    for layerName, layer in pairs(ldtk.get_layers(levelName)) do
        if layer.tiles then
            local tilemap = ldtk.create_tilemap(levelName, layerName)

            local layerSprite = gfx.sprite.new()
            layerSprite:setTilemap(tilemap)
            layerSprite:moveTo(0, 0)
            layerSprite:setCenter(0, 0)
            layerSprite:setZIndex(layer.zIndex)
            layerSprite:add()

            local emptyTiles = ldtk.get_empty_tileIDs(levelName, "Solid", layerName)
            if emptyTiles then
                gfx.sprite.addWallSprites(tilemap, emptyTiles)
            end
        end
    end

    for _, entity in ipairs(ldtk.get_entities(levelName)) do
        local entityX, entityY = entity.position.x, entity.position.y
        local entityName = entity.name
        if entityName == "Ability" then
            Ability(entityX, entityY, entity)
        elseif entityName == "Spike" then
            Spike(entityX, entityY)
        elseif entityName == "Spikeball" then
            Spikeball(entityX, entityY, entity)
        end
    end
end