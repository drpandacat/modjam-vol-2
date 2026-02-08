local GAME = Game()
local LEVEL = GAME:GetLevel()

--#region Referenced from https://discord.com/channels/962027940131008653/1315959880808398898

ROBERT_MOD:AddCallback(ModCallbacks.MC_POST_SLOT_INIT, function(_, slot)
    local player = Isaac.GetPlayer()
    if player:GetPlayerType() ~= ROBERT_MOD.PlayerType.ROBERT then return end

    slot:GetSprite():ReplaceSpritesheet(0, EntityConfig.GetPlayer(ROBERT_MOD.PlayerType.ROBERT_B):GetSkinPath(), true)
end, SlotVariant.HOME_CLOSET_PLAYER)

ROBERT_MOD:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, function(_, slot)
    if slot:IsDead() and slot:GetSprite():IsFinished() then
        if Isaac.GetPlayer():GetPlayerType() == ROBERT_MOD.PlayerType.ROBERT then
            Isaac.GetPersistentGameData():TryUnlock(ROBERT_MOD.Achievement.ROBERT_B_UNLOCK)
        end
    end
end, SlotVariant.HOME_CLOSET_PLAYER)
--#endregion

--#region Referenced from https://discord.com/channels/962027940131008653/1236724375747563520

ROBERT_MOD:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
    if LEVEL:GetStage() ~= LevelStage.STAGE8
    or GAME:AchievementUnlocksDisallowed()
    or LEVEL:GetCurrentRoomDesc().SafeGridIndex ~= 94
    or Isaac.GetPersistentGameData():Unlocked(ROBERT_MOD.Achievement.ROBERT_B_UNLOCK) then return end

    local room = GAME:GetRoom()
    if not room:IsFirstVisit() then return end

    local player = Isaac.GetPlayer()
    if player:GetPlayerType() ~= ROBERT_MOD.PlayerType.ROBERT then return end

    for _, v in ipairs(Isaac.FindByType(EntityType.ENTITY_PICKUP)) do
        v:Remove()
    end

    for _, v in ipairs(Isaac.FindByType(EntityType.ENTITY_SHOPKEEPER)) do
        v:Remove()
    end

    Isaac.Spawn(EntityType.ENTITY_SLOT, SlotVariant.HOME_CLOSET_PLAYER, 0, room:GetCenterPos(), Vector.Zero, nil)
end)
--#endregion