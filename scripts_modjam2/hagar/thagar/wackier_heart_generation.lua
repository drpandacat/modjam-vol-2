local mod = HAGAR_MOD

local MAX_HEART_SUBTYPE = HeartSubType.HEART_ROTTEN

local UNLOCKABLE_HEARTS = {
    [HeartSubType.HEART_GOLDEN] = Achievement.GOLDEN_HEARTS,
    [HeartSubType.HEART_HALF_SOUL] = Achievement.EVERYTHING_IS_TERRIBLE,
    [HeartSubType.HEART_SCARED] = Achievement.SCARED_HEART,
    [HeartSubType.HEART_BONE] = Achievement.BONE_HEARTS,
    [HeartSubType.HEART_ROTTEN] = Achievement.ROTTEN_HEARTS,
}

---@param pickup EntityPickup
---@param variant integer
---@param subType integer
---@param requestedVariant integer
---@param requestedSubtype integer
---@param rng RNG
local function PostHeartSelection(_, pickup, variant, subType, requestedVariant, requestedSubtype, rng)
    if variant ~= PickupVariant.PICKUP_HEART
    or requestedSubtype ~= 0
    or not PlayerManager.AnyoneIsPlayerType(mod.Enums.Character.T_HAGAR) then
        return
    end
    local newSubType = rng:RandomInt(MAX_HEART_SUBTYPE)+1
    if UNLOCKABLE_HEARTS[newSubType] then
        if not Isaac.GetPersistentGameData():Unlocked(UNLOCKABLE_HEARTS[newSubType]) then
            return
        end
    end
    return {PickupVariant.PICKUP_HEART, newSubType}
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_SELECTION, PostHeartSelection)