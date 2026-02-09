local mod = ROBERT_MOD

local ALL_DOORS_MASK = DoorMask.DOWN0 | DoorMask.RIGHT0 | DoorMask.UP0 | DoorMask.LEFT0

local ROOM_TYPES = {
    {RoomType.ROOM_ARCADE, 50},
    {RoomType.ROOM_CHEST, 50},
    {RoomType.ROOM_CURSE, 50},
    {RoomType.ROOM_DICE, 20},
    {RoomType.ROOM_ISAACS, 20},
    {RoomType.ROOM_BARREN, 20},
    {RoomType.ROOM_LIBRARY, 40},
    {RoomType.ROOM_SACRIFICE, 20},
    {RoomType.ROOM_SHOP, 100},
    {RoomType.ROOM_TREASURE, 100}
}

local WOMB_ROOM_TYPES = {
    {RoomType.ROOM_ARCADE, 50},
    {RoomType.ROOM_CHEST, 50},
    {RoomType.ROOM_CURSE, 50},
    {RoomType.ROOM_DICE, 20},
    {RoomType.ROOM_ISAACS, 20},
    {RoomType.ROOM_BARREN, 20},
    {RoomType.ROOM_LIBRARY, 40},
    {RoomType.ROOM_SACRIFICE, 20},
}

local defaultOutcomePicker = WeightedOutcomePicker()
local game = Game()

for _, entry in ipairs(ROOM_TYPES) do
    local roomType, weight = table.unpack(entry)
    defaultOutcomePicker:AddOutcomeWeight(roomType, weight)
end

local wombOutcomePicker = WeightedOutcomePicker()

for _, entry in ipairs(WOMB_ROOM_TYPES) do
    local roomType, weight = table.unpack(entry)
    wombOutcomePicker:AddOutcomeWeight(roomType, weight)
end

local function PostNewLevel()
    if not ROBERT_MOD:AnyoneIsRobert()
    or game:IsGreedMode()
    or mod.IsStageBlacklisted() then
        return
    end

    local level = game:GetLevel()

    local chosenOutcomePicker = defaultOutcomePicker
    if level:GetStage() > LevelStage.STAGE3_2 then
        chosenOutcomePicker = wombOutcomePicker
    end

    local rng = RNG(level:GetDungeonPlacementSeed())
    ---@diagnostic disable-next-line: param-type-mismatch
    local freeSlots = level:FindValidRoomPlacementLocations(RoomShape.ROOMSHAPE_1x1, ALL_DOORS_MASK, Dimension.NORMAL, true, false)
    for _, slot in ipairs(freeSlots) do
        local neighbours = level:GetNeighboringRooms(slot, RoomShape.ROOMSHAPE_1x1, Dimension.NORMAL)
        local doorsNeeded = 0
        for doorMask, _ in pairs(neighbours) do
            doorsNeeded = doorsNeeded | doorMask
        end
        local type = chosenOutcomePicker:PickOutcome(rng)
        local room = RoomConfigHolder.GetRandomRoom(rng:Next(), false, StbType.SPECIAL_ROOMS, type, RoomShape.NUM_ROOMSHAPES, -1, -1, 0, 10, doorsNeeded)
        level:TryPlaceRoom(room, slot, Dimension.NORMAL)
    end

    --Fix for a bug, where new rooms would only appear upon entering a new room.
    --Hopefull it doesn't cause any nasty side effects.
    if MinimapAPI then
        MinimapAPI:LoadDefaultMap()
    end
end
mod:AddPriorityCallback(ModCallbacks.MC_POST_NEW_LEVEL, CallbackPriority.LATE, PostNewLevel)