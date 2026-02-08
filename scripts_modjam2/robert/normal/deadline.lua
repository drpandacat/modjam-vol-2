local mod = ROBERT_MOD

local game = Game()
local sfx = SFXManager()

--I wanted to use room instead of first Robert as timer null item storage, but unfortunately that gets reset on run exit.
local DEADLINE_TRACKER = ROBERT_MOD.NullItemID.DEADLINE_TRACKER
local TAINTED_MULT = 135

local function PostNewRoom()
    if not ROBERT_MOD:AnyoneIsRobert()
    or game:IsGreedMode()
    or mod.IsStageBlacklisted()
    or mod.IsRoomTimerImmune() then
        return
    end

    local room = game:GetRoom()
    local player = ROBERT_MOD:GetFirstRobert()
    local effects = player:GetEffects()
    local count = effects:GetNullEffectNum(DEADLINE_TRACKER)
    local tainted = player:GetPlayerType() == ROBERT_MOD.PlayerType.ROBERT_B

    if room:GetType() == RoomType.ROOM_BOSS and (not tainted or effects:GetNullEffectNum(DEADLINE_TRACKER) > 0) then
        if count > 0 then
            effects:AddNullEffect(mod.NullItemID.BOSS_BONUS_TRACKER)
        end
        effects:RemoveNullEffect(DEADLINE_TRACKER, -1)
        return
    end

    if count > 0 then
        if count == 1 then
            sfx:Play(SoundEffect.SOUND_WAR_BOMB_TICK)
            mod.PostponeUntilUpdate(
            function ()
                local bossIndex = game:GetLevel():QueryRoomTypeIndex(RoomType.ROOM_BOSS, false, RNG())
                game:StartRoomTransition(bossIndex, Direction.NO_DIRECTION, RoomTransitionAnim.TELEPORT, Isaac.GetPlayer())
            end)
        end
        if not tainted then
            effects:RemoveNullEffect(DEADLINE_TRACKER)
        end
    elseif not tainted then
        effects:AddNullEffect(DEADLINE_TRACKER)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, PostNewRoom)

local function PostNewLevel()
    if not ROBERT_MOD:AnyoneIsRobert()
    or game:IsGreedMode()
    or mod.IsStageBlacklisted() then
        return
    end
    local roomCount = 0
    local rooms = game:GetLevel():GetRooms()
    for i = 0, #rooms-1 do
        local room = rooms:Get(i)
        if room:GetDimension() == Dimension.NORMAL
        and room.Data.Type == RoomType.ROOM_DEFAULT then
            roomCount = roomCount+1
        end
    end
    local roomTimer = math.ceil(roomCount*1)
    if BirthcakeRebaked then
        local mult = BirthcakeRebaked:GetCombinedTrinketMult(mod.PlayerType.ROBERT)
        roomTimer = roomTimer + (mult*3)
    end
    local effects = ROBERT_MOD:GetFirstRobert():GetEffects()
    effects:RemoveNullEffect(ROBERT_MOD.NullItemID.MAX_DEADLINE, -1)
    if PlayerManager.AnyoneIsPlayerType(ROBERT_MOD.PlayerType.ROBERT_B) then
        roomTimer = roomTimer * TAINTED_MULT
        roomTimer = math.ceil(roomTimer / 60) * 60
        effects:AddNullEffect(ROBERT_MOD.NullItemID.MAX_DEADLINE, nil, roomTimer)
    end
    effects:RemoveNullEffect(DEADLINE_TRACKER, -1)
    effects:AddNullEffect(DEADLINE_TRACKER, false, roomTimer)

    mod.PostponeUntilUpdate(
    function ()
        sfx:Play(SoundEffect.SOUND_BUTTON_PRESS)
    end)
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, PostNewLevel)