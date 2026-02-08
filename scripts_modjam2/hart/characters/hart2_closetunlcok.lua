local mod = _HART_MOD

local function trySpawnClosetSlot(playerType, taintedPlayerType, pos)
    local roomConfig = Game():GetLevel():GetCurrentRoomDesc().Data
    if(not (roomConfig.Type==1 and roomConfig.Variant==6 and roomConfig.Subtype==11)) then return false end
    if(not (Isaac.GetPlayer():GetPlayerType()==playerType and Isaac.GetPersistentGameData():Unlocked(mod.Achievement.HART_B)==false)) then return false end

    local slot = Isaac.Spawn(6,14,0,pos,Vector.Zero,nil):ToSlot() ---@cast slot EntitySlot
    local conf = EntityConfig.GetPlayer(taintedPlayerType)
    if(conf) then
        slot:GetSprite():ReplaceSpritesheet(0, conf:GetSkinPath(), true)
    end

    return true
end

---@param pickup EntityPickup
local function replaceCollectibleInCloset(_, pickup)
    if(trySpawnClosetSlot(mod.Character.HART, mod.Character.HART_B, pickup.Position)) then
        pickup:Remove()
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, replaceCollectibleInCloset, PickupVariant.PICKUP_COLLECTIBLE)

---@param npc EntityNPC
local function replaceShopkeeperInCloset(_, npc)
    if(trySpawnClosetSlot(mod.Character.HART, mod.Character.HART_B, npc.Position)) then
        npc:Remove()
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, replaceShopkeeperInCloset, EntityType.ENTITY_SHOPKEEPER)

---@param slot EntitySlot
local function postHartSecretUpdate(_, slot)
    local sprite = slot:GetSprite()
    if(not (sprite:GetAnimation()=="PayPrize" and sprite:IsFinished("PayPrize"))) then return end

    if(Isaac.GetPlayer():GetPlayerType()==mod.Character.HART and Isaac.GetPersistentGameData():Unlocked(mod.Achievement.HART_B)==false) then
        Isaac.GetPersistentGameData():TryUnlock(mod.Achievement.HART_B, false)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, postHartSecretUpdate, SlotVariant.HOME_CLOSET_PLAYER)