local GAME = Game()
local LEVEL = GAME:GetLevel()
local ACHIEVEMENT = Isaac.GetAchievementIdByName("Tainted Anima")
local ANIMA = Isaac.GetPlayerTypeByName("Anima")
local ANIMA2 = Isaac.GetPlayerTypeByName("Anima", true)

--#region Referenced from https://discord.com/channels/962027940131008653/1315959880808398898

AnimaCharacter:AddCallback(ModCallbacks.MC_POST_SLOT_INIT, function(_, slot)
    local player = Isaac.GetPlayer()
    if player:GetPlayerType() ~= ANIMA then return end

    slot:GetSprite():ReplaceSpritesheet(0, EntityConfig.GetPlayer(ANIMA2):GetSkinPath(), true)
end, SlotVariant.HOME_CLOSET_PLAYER)

AnimaCharacter:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, function(_, slot)
    if slot:IsDead() and slot:GetSprite():IsFinished() then
        if Isaac.GetPlayer():GetPlayerType() == ANIMA then
            Isaac.GetPersistentGameData():TryUnlock(ACHIEVEMENT)
        end
    end
end, SlotVariant.HOME_CLOSET_PLAYER)
--#endregion

--#region Referenced from https://discord.com/channels/962027940131008653/1236724375747563520

AnimaCharacter:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
    if LEVEL:GetStage() ~= LevelStage.STAGE8
    or GAME:AchievementUnlocksDisallowed()
    or LEVEL:GetCurrentRoomDesc().SafeGridIndex ~= 94
    or Isaac.GetPersistentGameData():Unlocked(ACHIEVEMENT) then return end

    local room = GAME:GetRoom()
    if not room:IsFirstVisit() then return end

    local player = Isaac.GetPlayer()
    if player:GetPlayerType() ~= ANIMA then return end

    for _, v in ipairs(Isaac.FindByType(EntityType.ENTITY_PICKUP)) do
        v:Remove()
    end

    for _, v in ipairs(Isaac.FindByType(EntityType.ENTITY_SHOPKEEPER)) do
        v:Remove()
    end

    Isaac.Spawn(EntityType.ENTITY_SLOT, SlotVariant.HOME_CLOSET_PLAYER, 0, room:GetCenterPos(), Vector.Zero, nil)
end)
--#endregion