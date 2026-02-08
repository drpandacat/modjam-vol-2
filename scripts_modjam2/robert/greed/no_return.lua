local mod = ROBERT_MOD

local game = Game()

local REGULAR_EXTRA_ROOM_INDICES = {
    [83] = true,
    [85] = true,
    [98] = true,
    [70] = true,
    [71] = true,
}

local LOCKED_DOOR_SLOTS = {DoorSlot.LEFT0, DoorSlot.UP0, DoorSlot.RIGHT0, DoorSlot.RIGHT1}

local STARTING_ROOM_INDEX = 84

---@return boolean
local function WasBossWaveStarted()
    return game:GetGreedWavesNum() - game:GetLevel().GreedModeWave < 3
end

---@param targetIdx integer
---@param dimension Dimension
local function PreChangeRoom(_, targetIdx, dimension)
    if dimension ~= Dimension.NORMAL
    or not REGULAR_EXTRA_ROOM_INDICES[targetIdx]
    or not ROBERT_MOD:AnyoneIsRobert()
    or not game:IsGreedMode()
    or game:GetLevel():GetStage() == LevelStage.STAGE7_GREED then
        return
    end
    if WasBossWaveStarted() then
        return {STARTING_ROOM_INDEX, Dimension.NORMAL}
    end
end

mod:AddCallback(ModCallbacks.MC_PRE_CHANGE_ROOM, PreChangeRoom)

local function PostUpdate()
    if not ROBERT_MOD:AnyoneIsRobert()
    or not game:IsGreedMode() then
        return
    end
    local level = game:GetLevel()
    if level:GetDimension() ~= Dimension.NORMAL
    or level:GetCurrentRoomDesc().GridIndex ~= STARTING_ROOM_INDEX
    or level:GetStage() == LevelStage.STAGE7_GREED
    or not WasBossWaveStarted() then
        return
    end
    local room = game:GetRoom()
    for _, slot in ipairs(LOCKED_DOOR_SLOTS) do
        local door = room:GetDoor(slot)
        if door then
            door:Close(true)
            door:GetSprite():Play("Closed")
            door:Bar()
            door:GetExtraSprite():Play("Idle")
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, PostUpdate)