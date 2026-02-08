local napalm = {}

--LEVEL 2:
-- decreased cd
-- longer debuff duratioon
--LEVEL 3:
-- higher damage mult
-- higher range


local BASE_NAPALM_RANGE = 60 --60 is a good middle ground
local LVL3_NAPALM_RANGE = 80

local BASE_DEBUFF_DURATION = 4 --in seconds (lower than vanilla game since will work better for isaac imo)
local LVL2_DEBUFF_DURATION = 7 --in seconds, not additive. replaces lower lvl

local LVL1_DMG_MULT = 1.2
local LV3_DMG_MULT = 1.37


local napalmIconSprite = Sprite()
napalmIconSprite:Load("gfx/effects/status_napalm.anm2")
napalmIconSprite:Play("napalmIcon")
StatusEffectLibrary.RegisterStatusEffect(
    "NAPALM",
    napalmIconSprite,
    Color(0.5, 0.5, 0.5, 1),
    EntityFlag.FLAG_SLOW,
    true,
    false
)

---@param entity EntityNPC
---@param damageFlags DamageFlag
local function amplifyDamage(_, entity, amount, damageFlags, source, cd)
    if StatusEffectLibrary:HasStatusEffect(entity, StatusEffectLibrary.StatusFlag.NAPALM) then

        --local player = PlayerManager.FirstPlayerByType(DeadlockMod.playerType.INFERNUS) --holy fuck you should not do this. this is really really bad and shitty but i gotta get this mod out. DO NOT USE GETDATA KIDS crisis averted
        local player = DeadlockMod:TryFindPlayerSpawner(source.Entity)
        if not player then return end

        local effects = player:GetEffects()
        local napalmLevel = effects:GetNullEffectNum(DeadlockMod.NullID.InfernusAbilities.NAPALM)

        if napalmLevel < 3 then
            amount = amount * LVL1_DMG_MULT
        elseif napalmLevel == 3 then
            amount = amount * LV3_DMG_MULT --no 67 for you lol
        end

        
        return {Damage = amount}
    end

    return nil
end
DeadlockMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, amplifyDamage)

---@param entity Entity
local function removeSlowOnEffectRemoval(_, entity)
    entity:ClearEntityFlags(EntityFlag.FLAG_SLOW)
end
StatusEffectLibrary.Callbacks.AddCallback(StatusEffectLibrary.Callbacks.ID.POST_REMOVE_ENTITY_STATUS_EFFECT, removeSlowOnEffectRemoval, StatusEffectLibrary.StatusFlag.NAPALM)




local emptySprite = Sprite()
ThrowableItemLib:RegisterThrowableItem({
    ID = DeadlockMod.CollectibleType.NAPALM,
    Type = ThrowableItemLib.Type.ACTIVE,
    Identifier = "Napalm",
    ThrowFn = function (player, vect)
        DeadlockMod.sfx:Play(DeadlockMod.SoundID.InfernusAbilities.NAPALM.CAST)
        
        local bottle = DeadlockMod.game:Spawn(EntityType.ENTITY_EFFECT, DeadlockMod.EffectVariant.INFERNUS.THROWN_NAPALM, player.Position, vect:Resized(8) + player:GetTearMovementInheritance(vect), player, 0,1):ToEffect()
        if not bottle then return end
        bottle.SpawnerEntity = player

        local sprite = bottle:GetSprite()
        sprite:Play("Thrown")

        if sprite:IsPlaying("thrown") then
            -- print("WOROOORKS") -- Get ridda yo prints bro!
        end

        local config = {
            Height = 12,
            Tags = {
                "Napalm"
            },
        }
        JumpLib:Jump(bottle, config)
    end,
    AnimateFn = function (player, state)
        if state == ThrowableItemLib.State.THROW then
            player:AnimatePickup(emptySprite, true, "HideItem")
            return true
        end
    end
})

---@param entity Entity
local function napalmLand(_, entity, data)
    if not data.Tags["Napalm"] then return end
    
    DeadlockMod.sfx:Play(SoundEffect.SOUND_GLASS_BREAK) --Change this to a diff sound later
    local sprite = entity:GetSprite()
    sprite:Play("Shatter")
    entity.Friction = 0

    local player = entity.SpawnerEntity:ToPlayer()
    if not player then return end -- or player:GetType() ~= DeadlockMod.playerType.INFERNUS

    local effects = player:GetEffects()
    local napalmLevel = effects:GetNullEffectNum(DeadlockMod.NullID.InfernusAbilities.NAPALM)

    local DEBUFF_DURATION = BASE_DEBUFF_DURATION
    if napalmLevel > 1 then --lvl2 increased duration
        DEBUFF_DURATION = LVL2_DEBUFF_DURATION
    end

    local NAPALM_RANGE = BASE_NAPALM_RANGE
    if napalmLevel == 3 then
        NAPALM_RANGE = LVL3_NAPALM_RANGE
    end

    local npcs = Isaac.FindInRadius(entity.Position, NAPALM_RANGE, EntityPartition.ENEMY)
    for i, npc in ipairs(npcs) do
        StatusEffectLibrary:AddStatusEffect(npc, StatusEffectLibrary.StatusFlag.NAPALM, DEBUFF_DURATION*30, EntityRef(entity))
        npc:AddEntityFlags(EntityFlag.FLAG_SLOW)
    end
end
DeadlockMod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, napalmLand)

---@param player EntityPlayer
function napalm:OnCast(player)
    player:UseActiveItem(DeadlockMod.CollectibleType.NAPALM)
end

return napalm