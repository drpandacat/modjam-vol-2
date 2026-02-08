local mod = ROBERT_MOD

local SPECIAL_ROOM_INDICES = {
    [83] = true,
    [85] = true,
    [98] = true,
}

local ROOM_TYPES = {
    {RoomType.ROOM_ARCADE, 50},
    {RoomType.ROOM_CHEST, 50},
    {RoomType.ROOM_CURSE, 50},
    {RoomType.ROOM_ISAACS, 20},
    {RoomType.ROOM_LIBRARY, 40},
    {RoomType.ROOM_TREASURE, 100}
}

local outcomePicker = WeightedOutcomePicker()
local game = Game()

for _, entry in ipairs(ROOM_TYPES) do
    local roomType, weight = table.unpack(entry)
    outcomePicker:AddOutcomeWeight(roomType, weight)
end

---@param generationSlot LevelGeneratorRoom
---@param config RoomConfigRoom
---@param seed integer
local function PrePlaceRoom(_, generationSlot, config, seed)
    if not ROBERT_MOD:AnyoneIsRobert()
    or not game:IsGreedMode() then
        return
    end

    local gridIndex = generationSlot:Column() + (generationSlot:Row()*13)
    if not SPECIAL_ROOM_INDICES[gridIndex] then
        return
    end

    local roomType = outcomePicker:PickOutcome(RNG(seed))

    local newConfig = RoomConfig.GetRandomRoom(
        seed,
        false,
        StbType.SPECIAL_ROOMS,
        roomType,
        config.Shape,
        -1,
        -1,
        0,
        10,
        config.Doors
    )

    return newConfig
end
mod:AddCallback(ModCallbacks.MC_PRE_LEVEL_PLACE_ROOM, PrePlaceRoom)