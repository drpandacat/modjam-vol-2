local mod = ROBERT_MOD

local game = Game()

local function PostNewRoom()
    if not ROBERT_MOD:AnyoneIsRobert()
    or game:IsGreedMode() then
        return
    end
    local room = game:GetRoom()
    if not room:IsFirstVisit() then
        return
    end
    local level = game:GetLevel()
    local levelType = level:GetStageType()
    if level:GetStage() > 1
    or levelType == StageType.STAGETYPE_REPENTANCE
    or levelType == StageType.STAGETYPE_REPENTANCE_B then
        return
    end

    for i = 0, DoorSlot.NUM_DOOR_SLOTS-1 do
        local door = room:GetDoor(i)
        if door
        and door:IsRoomType(RoomType.ROOM_TREASURE)
        and level:GetRoomByIdx(door.TargetRoomIndex).VisitedCount == 0 then
            door:SetLocked(true)
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, PostNewRoom)