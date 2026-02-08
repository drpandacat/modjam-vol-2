local mod = HAGAR_MOD

local HEART_TYPE_LIMIT = 2
local HEART_DROWN_COLOR = Color(0.2,0.7,1, 1, 0.4,0.5,0.8)

local HEART_SUBTYPE_TO_ADD_HEART_TYPE = {
    [HeartSubType.HEART_HALF] = AddHealthType.RED,
    [HeartSubType.HEART_FULL] = AddHealthType.RED,
    [HeartSubType.HEART_DOUBLEPACK] = AddHealthType.RED,
    [HeartSubType.HEART_SCARED] = AddHealthType.RED,
    [HeartSubType.HEART_BLENDED] = AddHealthType.RED,

    [HeartSubType.HEART_HALF_SOUL] = AddHealthType.SOUL,
    [HeartSubType.HEART_SOUL] = AddHealthType.SOUL,

    [HeartSubType.HEART_BLACK] = AddHealthType.BLACK,
    [HeartSubType.HEART_ETERNAL] = AddHealthType.ETERNAL,
    [HeartSubType.HEART_GOLDEN] = AddHealthType.GOLDEN,
    [HeartSubType.HEART_BONE] = AddHealthType.BONE,
    [HeartSubType.HEART_ROTTEN] = AddHealthType.ROTTEN,
}

local ADD_HEART_TYPE_TO_STORED_HEART_KEY = {
    [AddHealthType.RED] = mod.Enums.StoredHeartKeys.RED,
    [AddHealthType.SOUL] = mod.Enums.StoredHeartKeys.SOUL,
    [AddHealthType.BLACK] = mod.Enums.StoredHeartKeys.BLACK,
    [AddHealthType.ETERNAL] = mod.Enums.StoredHeartKeys.ETERNAL,
    [AddHealthType.GOLDEN] = mod.Enums.StoredHeartKeys.GOLDEN,
    [AddHealthType.BONE] = mod.Enums.StoredHeartKeys.BONE,
    [AddHealthType.ROTTEN] = mod.Enums.StoredHeartKeys.ROTTEN,
}

---@param position Vector
local function HeartAbsorbEffects(position)
    mod.SFX:Play(SoundEffect.SOUND_HEARTIN, 0.4, 10, false, 0.6)
    local heartSplash = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.BLOOD_EXPLOSION,
        0,
        position,
        Vector.Zero,
        nil
    )
    heartSplash:GetSprite().Color = HEART_DROWN_COLOR
end

---@param player EntityPlayer
---@param healthType AddHealthType
local function CanAddHealthType(player, healthType)
    if healthType == AddHealthType.MAX
    or healthType == AddHealthType.BROKEN then
        return true
    end
    local currentHearts = mod.Lib.CurrentHealthTypes(player)
    if #currentHearts < HEART_TYPE_LIMIT then
        return true
    end
    for _, ownedType in ipairs(currentHearts) do
        if ownedType == healthType then
            return true
        end
    end
    return false
end

---@param player EntityPlayer
---@param heart EntityPickup
local function TryAbsorb(player, heart)
    if heart.Price ~= 0 then
        return
    end

    local animation = heart:GetSprite():GetAnimation()

    if animation == "Appear" or animation == "Collect" then
        return
    end

    local heartType = HEART_SUBTYPE_TO_ADD_HEART_TYPE[heart.SubType] or AddHealthType.RED
    local heartKey = ADD_HEART_TYPE_TO_STORED_HEART_KEY[heartType]
    local addSecondTime = heart.SubType == HeartSubType.HEART_DOUBLEPACK    --TODO: Maybe make this more reusable for RepPlus Hoarder Heart.
    heartKey = Isaac.RunCallback(mod.Enums.Callbacks.GET_HEART_KEY, heart) or heartKey
    if mod.Zamzam.AddToBuffer(player, heartKey) then
        HeartAbsorbEffects(heart.Position)
        heart:TriggerTheresOptionsPickup()
        heart:Remove()
    end
    if addSecondTime then
        mod.Zamzam.AddToBuffer(player, heartKey)
    end
end

---@param heart EntityPickup
---@param collider Entity
local function PreHeartCollision(_, heart, collider)
    local player = collider:ToPlayer()
    if not (player and player:GetPlayerType() == mod.Enums.Character.T_HAGAR) then
        return
    end

    local variant = heart.Variant

    local moddedHealthType = Isaac.RunCallback(mod.Enums.Callbacks.CHECK_HEART_HEALTH_TYPE, heart)
    if not (variant == PickupVariant.PICKUP_HEART or moddedHealthType) then
        return
    end

    local subType = heart.SubType

    local healthType = moddedHealthType or HEART_SUBTYPE_TO_ADD_HEART_TYPE[subType] or AddHealthType.RED
    if variant == PickupVariant.PICKUP_HEART
    and subType == HeartSubType.HEART_BLENDED
    and player:HasFullHealth() then
        healthType = AddHealthType.SOUL
    end

    --If I could, I would use post pickup collision instead of this.
    Isaac.CreateTimer(function ()
        TryAbsorb(player, heart)
    end, 1, 1, false)

    if not CanAddHealthType(player, healthType) then
        return false
    end
end
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, PreHeartCollision)