local mod = ROBERT_MOD

local game = Game()

---@param curses integer
local function PostCurseEval(_, curses)
    if not ROBERT_MOD:AnyoneIsRobert()
    or game:IsGreedMode()
    or mod.IsStageBlacklisted() then
        return
    end

    if curses & LevelCurse.CURSE_OF_LABYRINTH ~= 0 then
        curses = curses & ~LevelCurse.CURSE_OF_LABYRINTH
        curses = curses | LevelCurse.CURSE_OF_DARKNESS
    end

    if curses & LevelCurse.CURSE_OF_MAZE ~= 0 then
        curses = curses & ~LevelCurse.CURSE_OF_MAZE
        curses = curses | LevelCurse.CURSE_OF_THE_UNKNOWN
    end

    if curses & LevelCurse.CURSE_OF_THE_LOST ~= 0 then
        curses = curses & ~LevelCurse.CURSE_OF_THE_LOST
        curses = curses | LevelCurse.CURSE_OF_BLIND
    end

    return curses
end

mod:AddCallback(ModCallbacks.MC_POST_CURSE_EVAL, PostCurseEval)