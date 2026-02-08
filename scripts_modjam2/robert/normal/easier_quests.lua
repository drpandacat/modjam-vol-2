local mod = ROBERT_MOD

local game = Game()

local WHITE_FIRE_VARIANT = 4

---@param level Level
---@param roomData RoomConfigRoom
---@return boolean
local function IsDownpourMirrorRoom(level, roomData)
    return true
    and roomData.Subtype == 34
    and roomData.Type == RoomType.ROOM_DEFAULT
    and level:HasMirrorDimension()
end

---@param level Level
---@param roomData RoomConfigRoom
---@return boolean
local function IsMineshaftRoom(level, roomData)
    return true
    and roomData.Subtype == 10
    and roomData.Type == RoomType.ROOM_DEFAULT
    and level:HasAbandonedMineshaft()
end

---@param level Level
---@param roomData RoomConfigRoom
---@return boolean
local function IsDepthsMomFight(level, roomData)
    return true
    and roomData.Type == RoomType.ROOM_BOSS
    and level:GetStage() == LevelStage.STAGE3_2
end

local function PostNewRoom()
    if not ROBERT_MOD:AnyoneIsRobert()
    or game:IsGreedMode() then
        return
    end
    local level = game:GetLevel()
    local roomDesc = level:GetCurrentRoomDesc()
    local roomData = roomDesc.Data
    if IsDownpourMirrorRoom(level, roomData) then
        Isaac.Spawn(
            EntityType.ENTITY_FIREPLACE,
            WHITE_FIRE_VARIANT,
            0,
            Vector(320,280),
            Vector.Zero,
            nil
        )
    elseif IsDepthsMomFight(level, roomData) then
        local room = game:GetRoom()
        if room:IsFirstVisit() then
            room:SpawnGridEntity(28, GridEntityType.GRID_ROCK_ALT2)
        end
    elseif IsMineshaftRoom(level, roomData) then
        local room = game:GetRoom()
        if room:IsFirstVisit() then
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP,
                PickupVariant.PICKUP_TAROTCARD,
                Card.CARD_HANGED_MAN,
                Vector(320,480),
                Vector.Zero,
                nil
            )
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, PostNewRoom)

local function PostNewLevel()
    if not ROBERT_MOD:AnyoneIsRobert()
    or game:IsGreedMode() then
        return
    end
    local level = game:GetLevel()

    if level:HasMirrorDimension() then
        local rooms = level:GetRooms()
        for i = 0, #rooms-1 do
            local room = rooms:Get(i)
            local data = room.Data
            if data.Subtype == 34
            and data.Type == RoomType.ROOM_DEFAULT then
                room.DisplayFlags = 7
                break
            end
        end
    elseif level:HasAbandonedMineshaft() then
        local rooms = level:GetRooms()
        for i = 0, #rooms-1 do
            local room = rooms:Get(i)
            local data = room.Data
            if data.Subtype == 10
            and data.Type == RoomType.ROOM_DEFAULT then
                room.DisplayFlags = 7
                break
            end
        end
    end

end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, PostNewLevel)