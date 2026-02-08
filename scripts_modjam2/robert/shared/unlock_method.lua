local mod = ROBERT_MOD

---@param isSlotSelected boolean
local function CheckRetroactiveRobertUnlock(_, _, isSlotSelected)
    if not isSlotSelected then
        return
    end
    local pgd = Isaac.GetPersistentGameData()
    if pgd:Unlocked(mod.Achievement.ROBERT_UNLOCK) then
        return
    end
    for playerType = PlayerType.PLAYER_ISAAC, EntityConfig:GetMaxPlayerType() do
        if Isaac.GetCompletionMark(playerType, CompletionType.BOSS_RUSH) > 0 then
            pgd:TryUnlock(mod.Achievement.ROBERT_UNLOCK)
            break
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD, CheckRetroactiveRobertUnlock)

---@param mark CompletionType
local function PostCompletionEvent(_, mark)
    if mark == CompletionType.BOSS_RUSH then
        Isaac.GetPersistentGameData():TryUnlock(mod.Achievement.ROBERT_UNLOCK)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_COMPLETION_EVENT, PostCompletionEvent)