local mod = ROBERT_MOD

local game = Game()

local ALT_PATH_SUBTYPES = {27, 29, 31}
local MAIN_PATH_SUBTYPES = {1, 4, 7}

---@param levelStage LevelStage
---@param roomDesc RoomDescriptor
---@param key string
local function AscentRoomRestore(_, levelStage, roomDesc, key)
    if key ~= "treasure_1"
    or not ROBERT_MOD:AnyoneIsRobert() then
        return
    end

    local level = game:GetLevel()
    local isAltStage = level:IsAltStage()

    local trueStage = levelStage
    if isAltStage then
        trueStage = trueStage-1
    end
    local chapter = math.ceil(trueStage/2)

    local roomSubtype
    if isAltStage then
        roomSubtype = MAIN_PATH_SUBTYPES[chapter]
    else
        roomSubtype = ALT_PATH_SUBTYPES[chapter]
    end
    roomSubtype = roomSubtype or 1

    local newRoomData = RoomConfigHolder.GetRandomRoom(
        roomDesc.AwardSeed,
        false,
        StbType.ASCENT,
        RoomType.ROOM_DEFAULT,
        RoomShape.ROOMSHAPE_1x1,
        -1, -1,
        0, 10,
        roomDesc.AllowedDoors,
        roomSubtype
    )
    roomDesc.Data = newRoomData or roomDesc.Data
end
mod:AddCallback(ModCallbacks.MC_POST_BACKWARDS_ROOM_RESTORE, AscentRoomRestore)