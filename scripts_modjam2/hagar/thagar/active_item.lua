local mod = HAGAR_MOD

local VENGEFUL_MONSTER_COLOR = Color()
VENGEFUL_MONSTER_COLOR:SetColorize(2, 0.8, 2, 1)

---@param rng RNG
---@param player EntityPlayer
local function UseItem(_, _, rng, player)
    local key = mod.Zamzam.PopFromBuffer(player)
    if not key then
        player:AnimateSad()
        return
    end

    local data = player:GetData()
    data.HagarZamzamBuffs = data.HagarZamzamBuffs or {}

    data.HagarZamzamColor = data.HagarZamzamColor or Color(0,0,0)

    local pitch = 1 + 0.05*#data.HagarZamzamBuffs
    mod.SFX:Play(SoundEffect.SOUND_VAMP_GULP, 0.7, 2, false, pitch)

    local heartData = mod.THagarHeartTypes[key]
    if heartData then
        local effectCount = #data.HagarZamzamBuffs
        local newColor = Color(
            ((data.HagarZamzamColor.R*effectCount) + heartData.R) / (effectCount+1),
            ((data.HagarZamzamColor.G*effectCount) + heartData.G) / (effectCount+1),
            ((data.HagarZamzamColor.B*effectCount) + heartData.B) / (effectCount+1)
        )
        data.HagarZamzamColor = newColor
    end

    table.insert(data.HagarZamzamBuffs, key)

    local frames = Isaac.RunCallbackWithParam(mod.Enums.Callbacks.ZAMZAM_ACTIVATE_HEART, key, player, key)
    player:AddCollectibleEffect(CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS, false, frames or 150, true)
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, UseItem, mod.Enums.Collectibles.ZAMZAM)

---@param npc EntityNPC
---@param collider Entity
local function NPCCollision(_, npc, collider)
    local player = collider:ToPlayer()
    if not player then
        return
    end
    local data = player:GetData()
    if not data.HagarZamzamBuffs then
        return
    end
    local enemyData = npc:GetData()
    local lastFrameHit = enemyData.HagarZamzamLastFrameHit or 0
    local currentFrame = mod.Game:GetFrameCount()
    if not npc:IsVulnerableEnemy()
    or npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
    or currentFrame - lastFrameHit < 20 then
        return
    end
    enemyData.HagarZamzamLastFrameHit = currentFrame    --I was doing this using game's damage cooldown systems, but it caused an anti-synergy with anything on-hit.
    npc:TakeDamage(player.Damage*3 + 3.5, 0, EntityRef(player), 0)
    player:AddNullItemEffect(mod.Enums.NullItems.THAGAR_ZAMZAM_BONUS, false, 300*#data.HagarZamzamBuffs, true)
    for _, effectType in ipairs(data.HagarZamzamBuffs) do
        Isaac.RunCallbackWithParam(mod.Enums.Callbacks.ZAMZAM_ENEMY_COLLISION, effectType, npc, player)
    end
end
mod:AddPriorityCallback(ModCallbacks.MC_PRE_NPC_COLLISION, CallbackPriority.LATE, NPCCollision)

---@param player EntityPlayer
local function PostShieldExpire(_, player)
    local data = player:GetData()

    if not data.HagarZamzamBuffs then
        return
    end

    if not mod.Game:IsPaused() then --To make it not play on room transistions.
        mod.SFX:Play(SoundEffect.SOUND_BATTERYDISCHARGE)
    end

    if player:GetPlayerType() == mod.Enums.Character.T_HAGAR
    and player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
    and not mod.Game:IsPaused() then
        mod.SFX:Play(SoundEffect.SOUND_DEATH_BURST_LARGE)
        mod.Game:MakeShockwave(player.Position, 0.05, 0.025, 10)

        local splashPuddle = Isaac.Spawn(
            EntityType.ENTITY_EFFECT,
            EffectVariant.LARGE_BLOOD_EXPLOSION,
            0,
            player.Position,
            Vector.Zero,
            player
        )
        local shieldColor = data.HagarZamzamColor
        splashPuddle.Color = Color(0,0,0, 0.15, shieldColor.R, shieldColor.G, shieldColor.B)

        local playerRef = EntityRef(player)
        local impactDamage = (player.Damage*5 + 10) * #data.HagarZamzamBuffs
        for _, enemy in ipairs(Isaac.FindInRadius(player.Position, 180, EntityPartition.ENEMY)) do
            if enemy:IsVulnerableEnemy()
            and not enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                local npc = enemy:ToNPC()
                ---@cast npc EntityNPC
                npc:TakeDamage(impactDamage, 0, playerRef, 0)
                for _, effectType in ipairs(data.HagarZamzamBuffs) do
                    player:AddNullItemEffect(mod.Enums.NullItems.THAGAR_ZAMZAM_BONUS, false, 300, true)
                    Isaac.RunCallbackWithParam(mod.Enums.Callbacks.ZAMZAM_ENEMY_COLLISION, effectType, npc, player)
                end
            end
        end

        for _, bullet in ipairs(Isaac.FindInRadius(player.Position, 180, EntityPartition.BULLET)) do
            local projectile = bullet:ToProjectile()
            ---@cast projectile EntityProjectile
            if not projectile:HasProjectileFlags(ProjectileFlags.CANT_HIT_PLAYER) then
                projectile:AddProjectileFlags(ProjectileFlags.CANT_HIT_PLAYER | ProjectileFlags.HIT_ENEMIES)
                projectile.Color = Color.Lerp(projectile.Color, VENGEFUL_MONSTER_COLOR, 0.8)
                projectile.Velocity = -projectile.Velocity
                for _, effectType in ipairs(data.HagarZamzamBuffs) do
                    Isaac.RunCallbackWithParam(mod.Enums.Callbacks.ZAMZAM_BULLET_REFLECTED, effectType, projectile, player)
                end
            end
        end
    end
    data.HagarZamzamBuffs = nil
    data.HagarZamzamColor = nil
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_TRIGGER_EFFECT_REMOVED, PostShieldExpire, Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS))

---@param player EntityPlayer
---@param stat EvaluateStatStage
---@param value number
local function PlayerEvaluateFlatTears(_, player, stat, value)
    local effects = player:GetEffects()
    if not effects:HasNullEffect(mod.Enums.NullItems.THAGAR_ZAMZAM_BONUS) then
        return
    end
    local cooldown = effects:GetNullEffect(mod.Enums.NullItems.THAGAR_ZAMZAM_BONUS).Cooldown

    return value + (cooldown/1500)
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_STAT, PlayerEvaluateFlatTears, EvaluateStatStage.FLAT_TEARS)

---@param player EntityPlayer
local function PostPlayerUpdate(_, player)
    if player.FrameCount%6 ~= 0 then
        return
    end
    local effects = player:GetEffects()
    if not effects:HasNullEffect(mod.Enums.NullItems.THAGAR_ZAMZAM_BONUS) then
        return
    end
    player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY, true)
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, PostPlayerUpdate)