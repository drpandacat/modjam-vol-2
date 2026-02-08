local mod = ROBERT_MOD

local DOOR_SLOT_TO_DIRECTION = {
    [DoorSlot.LEFT0] = Direction.LEFT,
    [DoorSlot.LEFT1] = Direction.LEFT,

    [DoorSlot.UP0] = Direction.UP,
    [DoorSlot.UP1] = Direction.UP,

    [DoorSlot.RIGHT0] = Direction.RIGHT,
    [DoorSlot.RIGHT1] = Direction.RIGHT,

    [DoorSlot.DOWN0] = Direction.DOWN,
    [DoorSlot.DOWN1] = Direction.DOWN,
}

local SPECIAL_ROOMS = {
    [RoomType.ROOM_ARCADE] = true,
    [RoomType.ROOM_CHALLENGE] = true,
    [RoomType.ROOM_CHEST] = true,
    [RoomType.ROOM_CURSE] = true,
    [RoomType.ROOM_DICE] = true,
    [RoomType.ROOM_ISAACS] = true,
    [RoomType.ROOM_BARREN] = true,
    [RoomType.ROOM_LIBRARY] = true,
    [RoomType.ROOM_SACRIFICE] = true,
    [RoomType.ROOM_SHOP] = true,
    [RoomType.ROOM_TREASURE] = true,
    [RoomType.ROOM_PLANETARIUM] = true,
}

local game = Game()
local sfx = SFXManager()

local lastEnteredThroughExit = false

local function PostNewRoom()
    if not lastEnteredThroughExit then
        return
    end
    lastEnteredThroughExit = false
    local room = game:GetRoom()
    local lastDoorSlot = game:GetLevel().EnterDoor
    local direction = DOOR_SLOT_TO_DIRECTION[lastDoorSlot]
    local spawnPos = room:GetDoorSlotPosition(lastDoorSlot) + Isaac.GetAxisAlignedUnitVectorFromDir(direction)*-23

    local doorEffect = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        mod.EffectVariant.BIRTHRIGHT_DOOR,
        lastDoorSlot,
        spawnPos,
        Vector.Zero,
        nil
    )
    doorEffect.SortingLayer = SortingLayer.SORTING_DOOR
    doorEffect:GetSprite():Play("Close")
    doorEffect.SpriteRotation = Isaac.GetAxisAlignedUnitVectorFromDir(direction):GetAngleDegrees()+90

    sfx:Play(SoundEffect.SOUND_DOOR_HEAVY_CLOSE)

    local previousDoor = room:GetDoor(lastDoorSlot)
    if previousDoor then
        previousDoor:GetSprite().Color = Color(1,1,1,0)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, PostNewRoom)

---@param effect EntityEffect
local function PostDoorUpdate(_, effect)
    local sprite = effect:GetSprite()
    if sprite:IsFinished("Close") then
        local poofEffect = Isaac.Spawn(
            EntityType.ENTITY_EFFECT,
            EffectVariant.POOF01,
            0,
            effect.Position,
            Vector.Zero,
            nil
        )
        poofEffect.Color = Color(1, 1, 1, 1, 0.2, 0.2, 0.2)
        poofEffect.SpriteScale = Vector(1.5, 1.5)

        local previousDoor = game:GetRoom():GetDoor(effect.SubType)
        if previousDoor then
            previousDoor:GetSprite().Color = Color(1,1,1,1)
        end

        effect:Remove()
        return
    end
    if effect:GetSprite():IsFinished("Open") then
        for _, _ in ipairs(Isaac.FindInRadius(effect.Position, 10, EntityPartition.PLAYER)) do
            lastEnteredThroughExit = true
            local targetGridIndex = effect.SubType
            if game:IsGreedMode() then
                targetGridIndex = GridRooms.ROOM_ERROR_IDX
            end
            game:StartRoomTransition(targetGridIndex, Direction.NO_DIRECTION, RoomTransitionAnim.WALK)
            break
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, PostDoorUpdate, mod.EffectVariant.BIRTHRIGHT_DOOR)


---@return integer[]
local function FindUnvisitedSpecialRooms()
    local level = game:GetLevel()
    local rooms = level:GetRooms()

    local results = {}

    for i = 0, #rooms-1 do
        local room = rooms:Get(i)
        if room.Clear then
            goto continue
        end
        local data = room.Data
        if not data or not SPECIAL_ROOMS[data.Type] then
            goto continue
        end
        table.insert(results, room.GridIndex)
        ::continue::
    end

    return results
end

---@param gridIndex integer
---@param direction Direction
---@return integer
local function FindBestPortalDestination(gridIndex, direction)
    local targetsList = FindUnvisitedSpecialRooms()
    if #targetsList == 0
    or game:IsGreedMode() then
        return gridIndex
    end
    local sourceX = gridIndex%13
    local sourceY = math.floor(gridIndex/13)

    local bestGridIndex = targetsList[1]
    local bestGridDistance = math.huge

    for _, targetIndex in ipairs(targetsList) do
        local targetX = targetIndex%13
        local targetY = math.floor(targetIndex/13)

        local diffX = targetX - sourceX
        local diffY = targetY - sourceY

        local dist = 0

        if direction == Direction.LEFT then
            if diffX < 0 then
                dist = dist + math.abs(diffX)
            else
                dist = dist + (math.abs(diffX)*500)
            end
            dist = dist + math.abs(diffY*25)

        elseif direction == Direction.RIGHT then
            if diffX > 0 then
                dist = dist + math.abs(diffX)
            else
                dist = dist + (math.abs(diffX)*500)
            end
            dist = dist + math.abs(diffY*25)

        elseif direction == Direction.UP then
            if diffY < 0 then
                dist = dist + math.abs(diffY)
            else
                dist = dist + (math.abs(diffY)*500)
            end
            dist = dist + math.abs(diffX*25)

        elseif direction == Direction.DOWN then
            if diffY > 0 then
                dist = dist + math.abs(diffY)
            else
                dist = dist + (math.abs(diffY)*500)
            end
            dist = dist + math.abs(diffX*25)
        end

        if dist < bestGridDistance then
            bestGridIndex = targetIndex
            bestGridDistance = dist
        end
    end

    return bestGridIndex
end

---@return DoorSlot[]
local function ValidDoorSlotsInRoom()
    local roomDescriptor = game:GetLevel():GetCurrentRoomDesc()
    local doorMask = roomDescriptor.Data.Doors

    local results = {}

    for doorSlot = 0, DoorSlot.NUM_DOOR_SLOTS-1 do
        if doorMask & (1 << doorSlot) ~= 0 then
            table.insert(results, doorSlot)
        end
    end

    return results
end

---@param player EntityPlayer
local function UseKeycard(_, _, player)
    local slots = ValidDoorSlotsInRoom()
    if #slots == 0 then
        return --Idk if this can actually ever happen in regular gameplay, but let's be safe.
    end

    sfx:Play(SoundEffect.SOUND_DOOR_HEAVY_OPEN)

    local room = game:GetRoom()

    local closestDoorSlotDistance = math.huge
    local closestDoorSlot = slots[1]

    for _, doorSlot in ipairs(slots) do
        local doorPos = room:GetDoorSlotPosition(doorSlot)
        local distance = doorPos:Distance(player.Position)

        if distance < closestDoorSlotDistance then
            closestDoorSlotDistance = distance
            closestDoorSlot = doorSlot
        end
    end

    local direction = DOOR_SLOT_TO_DIRECTION[closestDoorSlot]
    local currentGridIndex = game:GetLevel():GetCurrentRoomDesc().GridIndex
    if closestDoorSlot == DoorSlot.LEFT1 then
        currentGridIndex = currentGridIndex+13
    elseif closestDoorSlot == DoorSlot.RIGHT1 then
        currentGridIndex = currentGridIndex+14
    elseif closestDoorSlot == DoorSlot.UP1 then
        currentGridIndex = currentGridIndex+1
    elseif closestDoorSlot == DoorSlot.DOWN1 then
        currentGridIndex = currentGridIndex+14
    end
    local destination = FindBestPortalDestination(currentGridIndex, direction)
    local spawnPos = room:GetDoorSlotPosition(closestDoorSlot) + Isaac.GetAxisAlignedUnitVectorFromDir(direction)*-23

    local doorEffect = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        mod.EffectVariant.BIRTHRIGHT_DOOR,
        destination,
        spawnPos,
        Vector.Zero,
        nil
    )
    doorEffect.SortingLayer = SortingLayer.SORTING_DOOR
    doorEffect:GetSprite():Play("Open")
    doorEffect.SpriteRotation = Isaac.GetAxisAlignedUnitVectorFromDir(direction):GetAngleDegrees()+90

    local poofEffect = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.POOF01,
        0,
        spawnPos,
        Vector.Zero,
        nil
    )
    poofEffect.Color = Color(1,1,1,1,0.2,0.2,0.2)
    poofEffect.SpriteScale = Vector(1.5,1.5)

    local previousDoor = room:GetDoor(closestDoorSlot)
    if previousDoor then
        previousDoor:GetSprite().Color = Color(1,1,1,0)
    end
end

mod:AddCallback(ModCallbacks.MC_USE_CARD, UseKeycard, mod.Card.EXIT_KEYCARD)