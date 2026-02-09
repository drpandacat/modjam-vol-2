local game = HAGAR_MOD.Game

HAGAR_MOD.Lib = {}

--#region Shared functions

---Removes any values in the table that cause the provided function in func to return true
---@param tableToFilter table
---@param func any
---@return table
function HAGAR_MOD.Lib.FilterOutTable(tableToFilter, func)
    local filteredTable = {}
    for _, v in ipairs(tableToFilter) do
        if not func(v) then
            table.insert(filteredTable, v)
        end
    end
    return filteredTable
end

--#endregion

--#region Hagar functions

---Get the multiplier for Hagar's gimmick of enemy's health being scaled up.
---@param isBoss boolean?
---@return number
function HAGAR_MOD.Lib.GetMonsterHealthMultiplier(isBoss)
    isBoss = isBoss or false
    local level = game:GetLevel()
    local stage = math.ceil(level:GetAbsoluteStage() / 2)
    local ascentStage = level:IsAscent() and math.abs(stage - 7) or 0
    local multiplier = 0.2 * (stage + ascentStage - 1) ^ 1.8 + 1
    if isBoss then multiplier = math.min(multiplier, 3) end

    return multiplier
end

---Hagar's gimmick of increasing enemy HP based on the chapter.
---@param baseHP number
---@param isBoss boolean?
---@return number
function HAGAR_MOD.Lib.ScaleUpMonsterHealth(baseHP, isBoss)
    isBoss = isBoss or false
    local multiplier = HAGAR_MOD.Lib.GetMonsterHealthMultiplier(isBoss)
    return baseHP * multiplier
end

---Reverse of Hagar's enemy HP up gimmick, used by her pocket active El Roi.
---@param baseHP number
---@param isBoss boolean?
---@return number
function HAGAR_MOD.Lib.ScaleDownMonsterHealth(baseHP, isBoss)
    isBoss = isBoss or false
    local multiplier = HAGAR_MOD.Lib.GetMonsterHealthMultiplier(isBoss)
    return baseHP / multiplier
end

---Get Hagar's red heart cap. Returns 0 if player provided isn't Hagar
---@param player EntityPlayer
---@return integer
function HAGAR_MOD.Lib.GetHagarRedHeartCap(player)
    if player:GetPlayerType() ~= HAGAR_MOD.Enums.Character.HAGAR then return 0 end
    return player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and HAGAR_MOD.Enums.CharacterStats.HEART_CAP_BIRTHRIGHT or HAGAR_MOD.Enums.CharacterStats.HEART_CAP
end

---@param player EntityPlayer
---@return integer
local function BlackHeartCount(player)
    local blackHearts = player:GetBlackHearts()
    local count = 0
    while blackHearts > 0 do
        count = count + 1
        blackHearts = blackHearts & blackHearts - 1
    end
    return count*2
end

---@param player EntityPlayer
---@return table
function HAGAR_MOD.Lib.CurrentHealthTypes(player)
    local result = {}
    if CustomHealthAPI then
        if CustomHealthAPI.Library.GetHPOfKey(player, "BONE_HEART") > 0 then
            table.insert(result, AddHealthType.BONE)
        end
        if CustomHealthAPI.Library.GetHPOfKey(player, "RED_HEART") > 0 then
            table.insert(result, AddHealthType.RED)
        end
        if CustomHealthAPI.Library.GetHPOfKey(player, "ROTTEN_HEART") > 0 then
            table.insert(result, AddHealthType.ROTTEN)
        end
        if CustomHealthAPI.Library.GetHPOfKey(player, "SOUL_HEART") > 0 then
            table.insert(result, AddHealthType.SOUL)
        end
        if CustomHealthAPI.Library.GetHPOfKey(player, "BLACK_HEART") > 0 then
            table.insert(result, AddHealthType.BLACK)
        end
        if CustomHealthAPI.Library.GetHPOfKey(player, "GOLDEN_HEART") > 0 then
            table.insert(result, AddHealthType.GOLDEN)
        end
        if CustomHealthAPI.Library.GetHPOfKey(player, "ETERNAL_HEART") > 0 then
            table.insert(result, AddHealthType.ETERNAL)
        end
    else
        if player:GetBoneHearts() > 0 then
            table.insert(result, AddHealthType.BONE)
        end
        local rottenHeartCount = player:GetRottenHearts()
        if player:GetHearts() > rottenHeartCount * 2 then
            table.insert(result, AddHealthType.RED)
        end
        if rottenHeartCount > 0 then
            table.insert(result, AddHealthType.ROTTEN)
        end
        local blackHeartCount = BlackHeartCount(player)
        if player:GetSoulHearts() > blackHeartCount then
            table.insert(result, AddHealthType.SOUL)
        end
        if blackHeartCount > 0 then
            table.insert(result, AddHealthType.BLACK)
        end
        if player:GetGoldenHearts() > 0 then
            table.insert(result, AddHealthType.GOLDEN)
        end
        if player:GetEternalHearts() > 0 then
            table.insert(result, AddHealthType.ETERNAL)
        end
    end
    for _, callback in ipairs(Isaac.GetCallbacks(HAGAR_MOD.Enums.Callbacks.CHECK_OWNED_HEALTH_TYPES)) do
        local ret = callback.Function(callback.Mod, player)
        if ret then
            table.insert(result, ret)
        end
    end
    return result
end

---@class HagarHealthSnapshot
---@field Red integer
---@field Soul integer
---@field Black integer
---@field Eternal integer
---@field Gold integer
---@field Bone integer
---@field Rotten integer

---@param player EntityPlayer
---@return HagarHealthSnapshot
function HAGAR_MOD.Lib.HealthCounts(player)
    if CustomHealthAPI then
        return {
            Red = CustomHealthAPI.Library.GetHPOfKey(player, "RED_HEART"),
            Soul = CustomHealthAPI.Library.GetHPOfKey(player, "SOUL_HEART"),
            Black = CustomHealthAPI.Library.GetHPOfKey(player, "BLACK_HEART"),
            Eternal = CustomHealthAPI.Library.GetHPOfKey(player, "ETERNAL_HEART"),
            Gold = CustomHealthAPI.Library.GetHPOfKey(player, "GOLDEN_HEART"),
            Bone = CustomHealthAPI.Library.GetHPOfKey(player, "BONE_HEART"),
            Rotten = CustomHealthAPI.Library.GetHPOfKey(player, "ROTTEN_HEART"),
        }
    else
        local rottenHeartCount = player:GetRottenHearts()
        local blackHearts = BlackHeartCount(player)

        return {
            Red = player:GetHearts() - rottenHeartCount*2,
            Soul = player:GetSoulHearts() - blackHearts,
            Black = blackHearts,
            Eternal = player:GetEternalHearts(),
            Gold = player:GetGoldenHearts(),
            Bone = player:GetBoneHearts(),
            Rotten = rottenHeartCount,
        }
    end
end

--#endregion