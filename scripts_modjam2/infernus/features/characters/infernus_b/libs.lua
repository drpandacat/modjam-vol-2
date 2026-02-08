local Libs = {}

local mod = DeadlockMod

---@param tbl table
---@param element any
---@return boolean
function Libs:TableHasElement(tbl, element)
    for _, value in ipairs(tbl) do
        if value == element then
            return true
        end
    end
    return false
end

---@param levelStage LevelStage
---@param stageType StageType
---@return StbType stageID
function Libs.GetStageID(levelStage, stageType)
    if levelStage == LevelStage.STAGE8 then return StbType.HOME end -- HOME

    if levelStage > 8 then
        if levelStage == LevelStage.STAGE4_3 then
            if stageType == StageType.STAGETYPE_REPENTANCE then
                return StbType.ASCENT    -- BACKWARDS
            else
                return StbType.BLUE_WOMB -- BLUE_WOMB
            end
        end

        if levelStage == LevelStage.STAGE7 then return StbType.VOID end

        return stageType + (levelStage - 3) * 2
    end

    if stageType == StageType.STAGETYPE_REPENTANCE then
        return (levelStage - 1) + 27
    end

    local stageOffset = (levelStage - 1) // 2
    if stageType == StageType.STAGETYPE_REPENTANCE_B then
        return stageOffset * 2 + 28
    end

    return stageType + StageType.STAGETYPE_WOTL + stageOffset * 3
end

---@return LevelStage
function Libs:GetAdjustedLevelStage()
    local level = mod.game:GetLevel()
    local stageType = level:GetStageType()

    local isRepentanceStage = (stageType == StageType.STAGETYPE_REPENTANCE or stageType == StageType.STAGETYPE_REPENTANCE_B) and not level:IsAscent()

    return level:GetAbsoluteStage() + (isRepentanceStage and 1 or 0)
end

return Libs
