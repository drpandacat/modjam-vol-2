local mod = HAGAR_MOD

local CLOSET_ROOM_IDX = 94
local CHARACTER_SPRITESHEET = "gfx/characters/costumes/character_thagar.png"

local function PostNewRoom()
    if Isaac.GetPlayer():GetPlayerType() ~= mod.Enums.Character.HAGAR then --Allegedly vanilla unlock method only cares about player 0.
        return
    end
    local level = mod.Game:GetLevel()
    local room = mod.Game:GetRoom()
    if level:GetStage() ~= LevelStage.STAGE8
    or level:GetCurrentRoomIndex() ~= CLOSET_ROOM_IDX
    or not room:IsFirstVisit()
    or Isaac.GetPersistentGameData():Unlocked(mod.Enums.Achievements.THAGAR_UNLOCK)
    or #Isaac.FindByType(EntityType.ENTITY_SLOT, SlotVariant.HOME_CLOSET_PLAYER) > 0 then
        return
    end
    for _, shopKeep in ipairs(Isaac.FindByType(EntityType.ENTITY_SHOPKEEPER)) do
        shopKeep:Remove()
    end
    for _, innerChild in ipairs(Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_INNER_CHILD)) do
        innerChild:Remove()
    end
    local closetCharacter = Isaac.Spawn(
        EntityType.ENTITY_SLOT,
        SlotVariant.HOME_CLOSET_PLAYER,
        0,
        room:GetCenterPos(),
        Vector.Zero,
        nil
    )
    closetCharacter:GetSprite():ReplaceSpritesheet(0, CHARACTER_SPRITESHEET, true)
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, PostNewRoom)

---@param closetCharacter EntitySlot
local function ClosetCharacterUpdate(_, closetCharacter)
    local sprite = closetCharacter:GetSprite()
    if sprite:IsFinished("PayPrize") then
        local spritesheet = sprite:GetLayer(0):GetSpritesheetPath()
        if spritesheet == CHARACTER_SPRITESHEET then
            Isaac.GetPersistentGameData():TryUnlock(mod.Enums.Achievements.THAGAR_UNLOCK)
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, ClosetCharacterUpdate, SlotVariant.HOME_CLOSET_PLAYER)