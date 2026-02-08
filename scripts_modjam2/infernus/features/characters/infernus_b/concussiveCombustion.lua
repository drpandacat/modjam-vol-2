local combustion = {}

--LEVEL 2:
-- longer stun
-- bomb explosion
-- smaller damage increase
--LEVEL 3:
-- bigger aoe
-- dmg increase
-- cd reduction


local BASE_STUN_DURATION = 1
local LEVEL2_STUN_DURATION = 3

local BASE_RADIUS = 135
local LEVEL3_RADIUS = 155

local BASE_DAMAGE = 70
local LEVEL2_DAMAGE = 90
local LEVEL3_DAMAGE = 120

---@param player EntityPlayer
function combustion:OnCast(ability, player)
    DeadlockMod.sfx:Play(DeadlockMod.SoundID.InfernusAbilities.CONCUSSIVE_COMBUSTION.CAST)

    local explosion = DeadlockMod.game:Spawn(EntityType.ENTITY_EFFECT, DeadlockMod.EffectVariant.INFERNUS.CONCUSSIVE_EXPLOSION, player.Position, Vector.Zero, player, 0, 1):ToEffect()
    if not explosion then return end
    explosion:FollowParent(player)
    explosion:AddEntityFlags(EntityFlag.FLAG_PERSISTENT)

    if ability.level > 2 then
        explosion.SpriteScale = explosion.SpriteScale * 1.7
    else
        explosion.SpriteScale = explosion.SpriteScale * 1.55
    end

    Isaac.CreateTimer(function ()
        DeadlockMod.sfx:Play(DeadlockMod.SoundID.InfernusAbilities.CONCUSSIVE_COMBUSTION.EXPLOSION)
        DeadlockMod.game:ShakeScreen(20)

        player:AnimatePitfallOut()
        explosion:GetSprite():Play("end")
        
        

        local STUN_DURATION = BASE_STUN_DURATION
        local DAMAGE = BASE_DAMAGE
        if ability.level > 1 then --level 2, creates an explosion (and longer stun)!
            Isaac.Explode(player.Position, player, 0)
            STUN_DURATION = LEVEL2_STUN_DURATION
            DAMAGE = LEVEL2_DAMAGE
        end
        
        local RADIUS = BASE_RADIUS
        if ability.level > 2 then
            RADIUS = LEVEL3_RADIUS
            DAMAGE = LEVEL3_DAMAGE
        end

        local npcs = Isaac.FindInRadius(player.Position, RADIUS, EntityPartition.ENEMY)
        for i, npc in ipairs(npcs) do
            npc:TakeDamage(DAMAGE, DamageFlag.DAMAGE_CRUSH, EntityRef(player), 1)
            npc:AddConfusion(EntityRef(player), STUN_DURATION*30, true)
        end
    end, 97, 0, true)

end

local function muteExplosionSoundDuringUlt()
    if DeadlockMod.sfx:IsPlaying(DeadlockMod.SoundID.InfernusAbilities.CONCUSSIVE_COMBUSTION.EXPLOSION) then
        return false
    end
end
DeadlockMod:AddCallback(ModCallbacks.MC_PRE_SFX_PLAY, muteExplosionSoundDuringUlt, SoundEffect.SOUND_BOSS1_EXPLOSIONS)

---@param effect EntityEffect
local function explosionUpdate(_, effect)
    local sprite = effect:GetSprite()


    if sprite:IsFinished("start") then
        sprite:Play("loop")
    end

    if sprite:IsPlaying("end") then
        --sprite.Color.A = sprite.Color.A - 0.15
    end

    if sprite:IsFinished("end") then
        effect:Remove()
    end
end
DeadlockMod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, explosionUpdate, DeadlockMod.EffectVariant.INFERNUS.CONCUSSIVE_EXPLOSION)

return combustion
