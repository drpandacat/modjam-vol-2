local Utils = {}

local mod = AnimaCharacter

---@param tbl table
---@param rng RNG
function Utils:ShuffleTable(tbl, rng)
    --rng = rng
    for i = #tbl, 2, -1 do
        local j = rng:RandomInt(1, i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

---@param table1 table
---@param table2 table
---@return table
function Utils:CombineTables(table1, table2) -- combines Table1 and Table2 and returns 1 table with the elements of both. ex. {1, 2, 3} + {4, 5} = {1, 2, 3, 4, 5}
    local CombinedTable = {}
    for i = 1, #table1 do
        CombinedTable[i] = table1[i]
    end
    for i = 1, #table2 do
        CombinedTable[i + #table1] = table2[i]
    end
    return CombinedTable
end

---@return LevelStage
function Utils:GetAdjustedLevelStage()
    local level = mod.Game:GetLevel()
    local stageType = level:GetStageType()

    local isRepentanceStage = (stageType == StageType.STAGETYPE_REPENTANCE or stageType == StageType.STAGETYPE_REPENTANCE_B) and not level:IsAscent()

    return level:GetAbsoluteStage() + (isRepentanceStage and 1 or 0)
end

---@param playertype PlayerType
---@return EntityPlayer[]
function Utils:GetPlayersByType(playertype)
    local players = {}
    for _, player in pairs(mod.PlayerManager:GetPlayers()) do
        if player:GetPlayerType() == playertype then
            players[#players + 1] = player
        end
    end

    return players
end

---@param x integer
---@param p integer
function Utils:HasBit(x, p)
    return (x & p) > 0
end

---@param source EntityRef
function Utils:GetPlayerFromEntityRef(source)
    if source and source.Entity then
        local entity = source.Entity
        if entity.Type == EntityType.ENTITY_FAMILIAR then
            return entity:ToFamiliar().Player
        elseif entity.Parent
        and entity.Parent.Type == EntityType.ENTITY_PLAYER then
            return entity.Parent:ToPlayer()
        elseif entity.SpawnerEntity
        and entity.SpawnerEntity.Type == EntityType.ENTITY_PLAYER then
            return entity.SpawnerEntity:ToPlayer()
        end
    end

    return nil
end

---@param source EntityRef
function Utils:IsPlayerFromEntityRef(source)
    return not not self:GetPlayerFromEntityRef(source)
end

return Utils
