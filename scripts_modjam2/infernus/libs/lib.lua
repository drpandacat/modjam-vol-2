---@param hex string
---@param additive boolean
function DeadlockMod:ColorFromHex(hex, additive)
    hex = hex:gsub("#", "")
    
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    
    if additive then
        return Color(0, 0, 0, 1, r, g, b)
    else
        return Color(r, g, b, 1, 0, 0, 0)
    end
end

---@param entity Entity
---@return EntityPlayer | nil
function DeadlockMod:TryFindPlayerSpawner(entity)
    while entity ~= nil do
        if entity:ToPlayer() then
            return entity:ToPlayer()
        else
            entity = entity.SpawnerEntity
        end
    end

    return nil
end

-- Thank you guantol! Saved me a lot of trouble!

local TEAR_SCALE_THRESHOLDS = {
    0.0, 0.25, 0.5, 0.625, 0.75,
    0.875, 1.0, 1.125, 1.375, 1.625,
    1.875, 2.125, 2.5, 2.75
}

local BLOOD_TEARS = {
    [TearVariant.BLOOD] = true,
    [TearVariant.CUPID_BLOOD] = true,
    [TearVariant.PUPULA_BLOOD] = true,
    [TearVariant.GODS_FLESH_BLOOD] = true,
    [TearVariant.EYE_BLOOD] = true,
    [TearVariant.GLAUCOMA_BLOOD] = true
}

local TOOTH_TEARS = {
    [TearVariant.TOOTH] = true,
    [TearVariant.BLACK_TOOTH] = true
}

local COIN_TEARS = {
    [TearVariant.COIN] = true
}

local STONE_TEARS = {
    [TearVariant.STONE] = true,
    [TearVariant.BOOGER] = true,
    [TearVariant.EGG] = true,
    [TearVariant.RAZOR] = true,
    [TearVariant.BONE] = true,
    [TearVariant.SPORE] = true
}

---@param tear EntityTear
local function getTearSpriteSize(tear)
    local sizeId = 1
    local scale = tear.Scale
    local variant = tear.Variant

    local scaleCheck = variant * 100

    while sizeId < 13 do
        if scale <= TEAR_SCALE_THRESHOLDS[sizeId + 1] + 0.05 then
            break
        end
        sizeId = sizeId + 1
    end

    scaleCheck = scaleCheck + sizeId

    local animSizeId = sizeId
    local animName
    if BLOOD_TEARS[variant] then
        animName = "BloodTear" .. animSizeId

    elseif TOOTH_TEARS[variant] then
        animSizeId = math.max(math.floor(sizeId / 2), 1)
        animName = "Tooth" .. animSizeId .. "Move"

    elseif COIN_TEARS[variant] then
        animSizeId = math.max(math.floor(sizeId / 2), 1)
        animName = "Rotate" .. animSizeId

    elseif STONE_TEARS[variant] then
        animSizeId = math.max(math.floor(sizeId / 2), 1)
        animName = "Stone" .. animSizeId .. "Move"

    else
        animName = "RegularTear" .. animSizeId
    end

    tear:GetSprite():Play(animName, false)


    local spriteSize
    if sizeId < 13 then
        if tear:HasTearFlags(TearFlags.TEAR_GROW | TearFlags.TEAR_LUDOVICO) then
            spriteSize = 1
        else
            spriteSize = scale / TEAR_SCALE_THRESHOLDS[sizeId + 1]
        end
    else
        spriteSize = scale / TEAR_SCALE_THRESHOLDS[13 + 1]
    end

    return spriteSize
end

---@param tear EntityTear
function DeadlockMod:SetSpriteSize(tear)
    local spriteSize = getTearSpriteSize(tear)
    local layers = tear:GetSprite():GetAllLayers()
    for i = 1, #layers, 1 do
        local layer = layers[i]
        layer:SetSize(Vector(spriteSize, spriteSize))
    end

end

--Again, thanks guantol for the decomp!
---@param tear EntityTear
---@return EntityEffect | nil, integer
function DeadlockMod:spawnCorrectSplash(tear)
    local scale  = tear.Scale
    local sound
    local effect
    local volume = 1.0

    
    if scale < 0.4 then
        sound  = SoundEffect.SOUND_SPLATTER
        effect = EffectVariant.TEAR_POOF_VERYSMALL
        volume = 0.7

    elseif scale < 0.8 then
        sound  = SoundEffect.SOUND_SPLATTER
        effect = EffectVariant.TEAR_POOF_SMALL
        volume = 0.85

    elseif tear.Height <= -5.0 then
        sound  = SoundEffect.SOUND_TEARIMPACTS
        effect = EffectVariant.TEAR_POOF_A

    else
        sound  = SoundEffect.SOUND_SPLATTER
        effect = EffectVariant.TEAR_POOF_B
    end

    -- Spawn effect at tear position
    local splash = DeadlockMod.game:Spawn(
        EntityType.ENTITY_EFFECT,
        effect,
        tear.Position + tear.PositionOffset,
        Vector.Zero,
        nil,
        0,
        tear.InitSeed
    ):ToEffect()


    -- Play sound (we comment this out cuz we got our own sound, normally youd keep this in)
    --DeadlockMod.sfx:Play(sound, volume)

    return splash, volume
end
