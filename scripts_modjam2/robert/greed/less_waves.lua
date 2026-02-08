local mod = ROBERT_MOD

local game = Game()

local function PostNewRoom()
    if not ROBERT_MOD:AnyoneIsRobert()
    or not game:IsGreedMode() then
        return
    end
    local level = game:GetLevel()
    local startingWave = 2
    if BirthcakeRebaked then
        local mult = BirthcakeRebaked:GetCombinedTrinketMult(mod.PlayerType.ROBERT)
        startingWave = math.max(0, startingWave-mult)
    end
    level.GreedModeWave = math.max(startingWave, level.GreedModeWave)
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, PostNewRoom) --For some reason it goes back to 0 on each room so I have to do it each room.