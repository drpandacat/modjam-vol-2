local game = Game()

function ROBERT_MOD:AnyoneIsRobert()
    return PlayerManager.AnyoneIsPlayerType(ROBERT_MOD.PlayerType.ROBERT)
    or PlayerManager.AnyoneIsPlayerType(ROBERT_MOD.PlayerType.ROBERT_B)
end

function ROBERT_MOD:GetFirstRobert()
    return PlayerManager.FirstPlayerByType(ROBERT_MOD.PlayerType.ROBERT_B)
    or PlayerManager.FirstPlayerByType(ROBERT_MOD.PlayerType.ROBERT)
    or Isaac.GetPlayer()
end

--Makes the passed function only trigger after the next frame. Intended to use at start of room/floor/run.
--https://github.com/TeamREPENTOGON/REPENTOGON/issues/462
---@param funcToPostpone function
function ROBERT_MOD.PostponeUntilUpdate(funcToPostpone)
    Isaac.CreateTimer(function ()
        Isaac.CreateTimer(funcToPostpone, 1, 1, true)
    end, 1, 1, true)
end

--Blacklisted = Robert's gimmick should be disabled.
---@return boolean
function ROBERT_MOD.IsStageBlacklisted()
    local level = game:GetLevel()
    local levelStage = level:GetStage()
    if game:IsGreedMode() then
        return levelStage == LevelStage.STAGE7_GREED
    end
    if (TheFuture and TheFuture.Stage:IsStage()) then
        return true
    end
    if level:IsAscent()
    or levelStage > LevelStage.STAGE4_2 then
        return true
    end
    return false
end

--TimerImmune = Robert's deadline timer won't go down when entering this room.
---@return boolean
function ROBERT_MOD.IsRoomTimerImmune()
    local level = game:GetLevel()
    local room = game:GetRoom()
    local roomIndex = level:GetCurrentRoomDesc().GridIndex
    if level:GetDimension() ~= Dimension.NORMAL
    or roomIndex < 0
    or (roomIndex == level:GetStartingRoomIndex() and room:IsFirstVisit())
    then
        return true
    end
    return false
end