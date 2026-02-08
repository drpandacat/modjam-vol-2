local mod = ROBERT_MOD

local game = Game()

local function PostNewLevel()
    if not ROBERT_MOD:AnyoneIsRobert()
    or game:IsGreedMode() then
        return
    end

    if mod.IsStageBlacklisted() then
        game:GetSeeds():RemoveSeedEffect(SeedEffect.SEED_NO_BOSS_ROOM_EXITS)
    else
        game:GetLevel():ApplyCompassEffect(true)
        game:GetSeeds():AddSeedEffect(SeedEffect.SEED_NO_BOSS_ROOM_EXITS)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, PostNewLevel)