local mod = HAGAR_MOD

local PULSE_COLOR = Color(1, 1, 1, 1, 1, 0.9, 0.38)

---@param item CollectibleType
---@param rng RNG
---@param player EntityPlayer
---@param flags UseFlag
---@param slot ActiveSlot
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, item, rng, player, flags, slot)
    local fx = player:GetEffects()

    if player:GetPlayerType() == mod.Enums.Character.HAGAR then
        local room = mod.Game:GetRoom()
        local heartCounters = fx:GetNullEffectNum(mod.Enums.NullItems.HAGAR_HEART_COUNTER)
        local cost = mod.Enums.CharacterStats.INCREASED_EL_ROI_COST[room:GetType()] and 2 or 1
        local doBirthrightEffect = false
        if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and heartCounters >= 6 and not fx:HasNullEffect(mod.Enums.NullItems.HAGAR_BIRTHRIGHT_EFFECT) then
            cost = 6
            doBirthrightEffect = true
        end
        if heartCounters >= cost then
            fx:RemoveNullEffect(mod.Enums.NullItems.HAGAR_HEART_COUNTER, cost)
            fx:AddCollectibleEffect(CollectibleType.COLLECTIBLE_WAFER)
            player:AddInnateCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS, -1)
            if doBirthrightEffect then
                fx:AddNullEffect(mod.Enums.NullItems.HAGAR_BIRTHRIGHT_EFFECT)
            end
        else
            return {Discharge = false, ShowAnim = true}
        end
    else
        local hasSufficientRedHealth = player:GetHearts() >= 2
        local hasAddedHealthCushion = player:GetSoulHearts() >= 1 or player:GetBoneHearts() >= 1
        if (hasAddedHealthCushion and hasSufficientRedHealth) or (not hasAddedHealthCushion and player:GetHearts() > 2) then
            player:AddHearts(-2)
            fx:AddCollectibleEffect(CollectibleType.COLLECTIBLE_WAFER)
        else
            return {Discharge = false, ShowAnim = true}
        end
    end

    if fx:GetCollectibleEffectNum(mod.Enums.Collectibles.EL_ROI) <= 1 and mod.Lib.GetMonsterHealthMultiplier() > 1 then

        ---@type Entity[]
        local monsters = mod.Lib.FilterOutTable(Isaac.GetRoomEntities(), function (ent)
            local npc = ent:ToNPC()
            if not npc then return true end
            if not npc:IsActiveEnemy() or mod.Enums.Blacklists.MonsterHPUp:IsBlacklisted(npc) then
                return true
            end
            if npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then return true end

            return false
        end)

        for _, ent in ipairs(monsters) do
            local healthPercentage = ent.HitPoints / ent.MaxHitPoints
            ent.MaxHitPoints = mod.Lib.ScaleDownMonsterHealth(ent.MaxHitPoints)
            ent.HitPoints = ent.MaxHitPoints * healthPercentage
            ent:SetColor(PULSE_COLOR, 30, 1, true, false)
        end
    end

    mod.SFX:Play(SoundEffect.SOUND_DIVINE_INTERVENTION)
    mod.SFX:Play(SoundEffect.SOUND_HOLY, 0.8, 2, false, 1.4)
    return true
end, mod.Enums.Collectibles.EL_ROI)