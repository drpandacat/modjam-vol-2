local mod = ROBERT_MOD

local game = Game()

local function PostRoomClear()
    if not ROBERT_MOD:AnyoneIsRobert()
    or game:IsGreedMode() then
        return
    end

    local room = game:GetRoom()
    if room:GetType() ~= RoomType.ROOM_BOSS
    or room:IsMirrorWorld() then
        return
    end

    local level = game:GetLevel()
    local stage = level:GetStage()
    if stage == LevelStage.STAGE3_2
    or mod.IsStageBlacklisted() then
        return
    end

    local player = ROBERT_MOD:GetFirstRobert()
    local effects = player:GetEffects()
    local effectCount = effects:GetNullEffectNum(mod.NullItemID.BOSS_BONUS_TRACKER)

    if effectCount == 0 then
        return
    end

    local spawnPos = Isaac.GetFreeNearPosition(Vector(320, 320), 10)
    Isaac.Spawn(
        EntityType.ENTITY_PICKUP,
        PickupVariant.PICKUP_COLLECTIBLE,
        0,
        spawnPos,
        Vector.Zero,
        nil
    )
    player:AnimateHappy()
end

mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, PostRoomClear)