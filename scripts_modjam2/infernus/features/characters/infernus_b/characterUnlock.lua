local mod = DeadlockMod
local modChars = mod.playerType
local pgd = Isaac.GetPersistentGameData()

local taintedUnlockID = Isaac.GetAchievementIdByName("INFERNUS_TAINTED_INFERNUS")

---@param type EntityType
---@param variant SlotVariant
---@param subtype PlayerType | integer
mod:AddCallback(ModCallbacks.MC_PRE_ROOM_ENTITY_SPAWN, function(_, type, variant, subtype)
    if pgd:Unlocked(taintedUnlockID) then
        return
    end

    if type == EntityType.ENTITY_SLOT and variant == SlotVariant.HOME_CLOSET_PLAYER then
        for _, players in ipairs(PlayerManager.GetPlayers()) do
            if players:GetPlayerType() == modChars.INFERNUS then
                return { EntityType.ENTITY_SLOT, SlotVariant.HOME_CLOSET_PLAYER, modChars.INFERNUS }
            end
        end
    end
end)

---@param slot EntitySlot
mod:AddCallback(ModCallbacks.MC_POST_SLOT_INIT, function(_, slot)
    if slot.SubType ~= modChars.INFERNUS then
        return
    end

    local sprite = slot:GetSprite()

    local taintedPlayerConfig = EntityConfig.GetPlayer(modChars.INFERNUS):GetTaintedCounterpart() --[[@as EntityConfigPlayer]]
    local spritesheetPath = taintedPlayerConfig:GetSkinPath()

    for i = 0, sprite:GetLayerCount() do
        sprite:ReplaceSpritesheet(i, spritesheetPath)
    end

    sprite:LoadGraphics()
end)

---@param slot EntitySlot
mod:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, function(_, slot)
    if slot.SubType ~= modChars.INFERNUS then
        return
    end

    local sprite = slot:GetSprite()

    if slot:IsDead() and sprite:IsFinished("PayPrize") then
        pgd:TryUnlock(taintedUnlockID, false)
    end
end, SlotVariant.HOME_CLOSET_PLAYER)
