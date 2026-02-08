local mod = ROBERT_MOD

-- ---@param isSlotSelected boolean
-- local function AwardGreedMark(_, _, isSlotSelected)
--     if not isSlotSelected then
--         return
--     end
    
-- end
-- mod:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD, AwardGreedMark)

---@param player EntityPlayer
local function KillInGreedMode(_, player)
    if player:GetPlayerType() == mod.PlayerType.ROBERT_B
    and Game():IsGreedMode() then
        mod.PostponeUntilUpdate(
            function ()
                player:UseActiveItem(CollectibleType.COLLECTIBLE_PLAN_C)
            end
        )
        Isaac.SetCompletionMark(mod.PlayerType.ROBERT_B, CompletionType.ULTRA_GREED, 2)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, KillInGreedMode)
-- sorry :-(