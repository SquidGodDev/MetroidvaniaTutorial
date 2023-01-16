local pd <const> = playdate
local gfx <const> = playdate.graphics

local ldtk <const> = LDtk

TAGS = {
	Solid = 1,
	Pickup = 2
}

Z_INDEXES = {
	PLAYER = 100,
	PICKUP = 50
}

-- local usePrecomputedLevels = not pd.isSimulator

ldtk.load("levels/world.ldtk", false)

if pd.isSimulator then
	ldtk.export_to_lua_files()
end

class('GameScene').extends()

function GameScene:init()
    self:goToLevel("Level_0")
    self.spawnX = 5 * 16
    self.spawnY = 6 * 16

    self.player = Player(self.spawnX, self.spawnY, self, abilities)
end

function GameScene:resetPlayer()
	self.player:moveTo(self.spawnX, self.spawnY)
end

function GameScene:enterRoom(direction)
	local level = ldtk.get_neighbours(self.level_name, direction)[1]
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

function GameScene:goToLevel(level_name)
    if not level_name then return end

	self.level_name = level_name

	gfx.sprite.removeAll()

	for layer_name, layer in pairs(ldtk.get_layers(level_name)) do
		if layer.tiles then
			local tilemap = ldtk.create_tilemap(level_name, layer_name)

			local layerSprite = gfx.sprite.new()
			layerSprite:setTilemap(tilemap)
			layerSprite:moveTo(0, 0)
			layerSprite:setCenter(0, 0)
			layerSprite:setZIndex(layer.zIndex)
			layerSprite:add()

            local emptyTiles = ldtk.get_empty_tileIDs(level_name, "Solid", layer_name)
            if emptyTiles then
                local tileSprites = gfx.sprite.addWallSprites(tilemap, emptyTiles)
                for i=1,#tileSprites do
                    local tileSprite = tileSprites[i]
                    tileSprite:setTag(TAGS.Solid)
                end
            end
		end
	end

	for _, entity in ipairs(ldtk.get_entities(level_name)) do
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