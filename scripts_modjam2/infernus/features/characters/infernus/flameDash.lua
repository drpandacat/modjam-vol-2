local dash = {}


--LEVEL 2:
-- +1 second duration of dash and its creep
-- bigger creep
-- creep applies slow entity flag

--LEVEL 3:
-- -15s cooldown
-- dmg up 
-- applies stun instead of slow

---@param player EntityPlayer
function dash:OnCast(player)
    local effects = player:GetEffects()


    if not effects:HasNullEffect(DeadlockMod.NullID.InfernusAbilities.TEMP_DASH) then
        DeadlockMod.sfx:Play(DeadlockMod.SoundID.InfernusAbilities.FLAME_DASH.CAST)
        effects:AddNullEffect(DeadlockMod.NullID.InfernusAbilities.TEMP_DASH)
    end

end

---@param player EntityPlayer
function dash:OnPlayerUpdate(player)
    local effects = player:GetEffects()
    local level = effects:GetNullEffectNum(DeadlockMod.NullID.InfernusAbilities.FLAME_DASH)

    local tearParams = player:GetTearHitParams(WeaponType.WEAPON_TEARS, 1, 1, nil)
    tearParams.TearFlags = TearFlags.TEAR_TELEPORT

    --STATS
    local DPS = 3
    local SIZE_MULT = 1.8 --tbd change this for 2nd flame dash upgrade
    local DURATION = 4

    if level > 1 then
        SIZE_MULT = 2.2
        DPS = 4
        tearParams.TearFlags = TearFlags.TEAR_SLOW
        DURATION = 5
        
        if level == 3 then
            DPS = 5
            tearParams.TearFlags = TearFlags.TEAR_FREEZE
        end

    end

    if effects:HasNullEffect(DeadlockMod.NullID.InfernusAbilities.TEMP_DASH) and DeadlockMod.game:GetFrameCount() % 3 == 0 then
        local creep = player:SpawnAquariusCreep(tearParams)
        if not creep then return end

        creep.CollisionDamage = DPS / 10
        creep.Color = DeadlockMod:ColorFromHex("0c0608", true)
        creep.SpriteScale = creep.SpriteScale * SIZE_MULT
        creep.Timeout = DURATION * 30 -- make sure this is higher than the duration of the null item
    end
end
DeadlockMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, dash.OnPlayerUpdate)

return dash