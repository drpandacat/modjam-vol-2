local afterburn = {}

--LEVEL 2:
-- adds fire behind tear
-- longer duration
-- less damage required to proc
--LEVEL 3:
-- adds trail behind tear
-- dps up
-- less damage required to proc

local BASE_DURATION = 2.5
local LEVEL2_DURATION = 5

local DAMAGE_REQUIRED_L1 = 20
local DAMAGE_REQUIRED_L2 = 15
local DAMAGE_REQUIRED_L3 = 10

local BASE_DAMAGE_PER_TICK = 1.45 --multiplier of player damage
local LEVEL3_DAMAGE_PER_TICK = 1.85

local afterburnIconSprite = Sprite()
afterburnIconSprite:Load("gfx/effects/status_afterburn.anm2")
afterburnIconSprite:Play("afterburnIcon")
StatusEffectLibrary.RegisterStatusEffect(
    "AFTERBURN",
    afterburnIconSprite,
    Color(1, 0.35, 0.35, 1),
    EntityFlag.FLAG_SLOW,
    true,
    false
)

---@param tear EntityTear
local function tearInit(_, tear)
    local player = DeadlockMod:TryFindPlayerSpawner(tear)
    if not player or player:GetPlayerType() ~= DeadlockMod.playerType.INFERNUS then return end

    if player:GetEffects():HasNullEffect(DeadlockMod.NullID.InfernusAbilities.AFTERBURN) then
       tear:SetInitSound(DeadlockMod.SoundID.InfernusAbilities.TEAR_SHOOT)
    end
end
DeadlockMod:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, tearInit)

---@param tear EntityTear
function afterburn:PostFireTear(tear)
    local player = DeadlockMod:TryFindPlayerSpawner(tear)
    if not player or not tear or player:GetPlayerType() ~= DeadlockMod.playerType.INFERNUS  then return end

    local level = player:GetEffects():GetNullEffectNum(DeadlockMod.NullID.InfernusAbilities.AFTERBURN)

    if level >= 1 then
        tear:ChangeVariant(DeadlockMod.tearVariant.INFERNUS_TEAR)
        
        if level > 1 then
            tear:AddTearFlags(TearFlags.TEAR_BURN)
            local fireSprite = tear:GetTearEffectSprite()
            fireSprite.Color = DeadlockMod:ColorFromHex("#c04031", true)
            fireSprite.Color.A = 0
        end
        
        if level == 3 then
            local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SPRITE_TRAIL, 0, tear.Position + tear.PositionOffset + tear.SpriteOffset, Vector.Zero, tear):ToEffect()
            if not trail then return end
            trail.Parent = tear
            trail.Color = DeadlockMod:ColorFromHex("#c04031", true)
            trail.MinRadius = 0.2225 / tear.Scale
            
            
        end
    end

end
DeadlockMod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, afterburn.PostFireTear)
--consider changing the callback to mc_post_tear_update, along with a system to pick the animation based on scale (and not whatever the fuck im doing right now)
--atp might be worth it to just set a diff color instead of a whole new variant (this would be lazy, im goated so i figured it out)

--This game is so fucking stupid dude fuck this
---@param tear EntityTear
function afterburn:PostTearUpdate(tear)
    DeadlockMod:SetSpriteSize(tear)

    local fireSprite = tear:GetTearEffectSprite()
    fireSprite.Color.A = 1
end
DeadlockMod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, afterburn.PostTearUpdate, DeadlockMod.tearVariant.INFERNUS_TEAR)

--CHECK ON THIS FUN LATER
---@param effect EntityEffect
function afterburn:PostTrailUpdate(effect)
    local tear = effect.Parent
    if not tear or tear.Variant ~= DeadlockMod.tearVariant.INFERNUS_TEAR then return end

    effect.Position = tear.Position + tear.PositionOffset + tear.SpriteOffset
end
DeadlockMod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, afterburn.PostTrailUpdate, EffectVariant.SPRITE_TRAIL)

function afterburn:removeFireMind(tear, collider)
    local player = DeadlockMod:TryFindPlayerSpawner(tear)
    if not player or not player:HasCollectible(CollectibleType.COLLECTIBLE_FIRE_MIND) then
        tear:ClearTearFlags(TearFlags.TEAR_BURN)
    end
end
DeadlockMod:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, afterburn.removeFireMind, DeadlockMod.tearVariant.INFERNUS_TEAR)


---@param tear EntityTear
function afterburn:OnTearDeath(tear)
    local player = tear.SpawnerEntity
    if not player then return end

    --remove tear mind effect stuff
    tear:ClearTearFlags(TearFlags.TEAR_BURN)

    --Crater stuff
    local ash = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_CRATER, 0, tear.Position, Vector.Zero, player)
    ash.SpriteScale = ash.SpriteScale / (6/tear.Scale)

    --splash stuff
    ---@type EntityEffect?
    local splash, volume = DeadlockMod:spawnCorrectSplash(tear)
    
    splash.Color = DeadlockMod:ColorFromHex("#ff7650", true)

    --noise stuff
    DeadlockMod.sfx:Play(DeadlockMod.SoundID.InfernusAbilities.TEAR_IMPACT, volume)
end
DeadlockMod:AddCallback(ModCallbacks.MC_POST_TEAR_DEATH, afterburn.OnTearDeath, DeadlockMod.tearVariant.INFERNUS_TEAR)

---@param entity EntityNPC
local function afterburnOnDamage(_, entity, amount, flags, source, cd)
    local player = DeadlockMod:TryFindPlayerSpawner(source.Entity)
    if not player or player:GetPlayerType() ~= DeadlockMod.playerType.INFERNUS or flags == DamageFlag.DAMAGE_CLONES or not entity:IsActiveEnemy(false) or not entity:IsVulnerableEnemy() then --entity:IsInvincible() 
        return
    end

    local level = player:GetEffects():GetNullEffectNum(DeadlockMod.NullID.InfernusAbilities.AFTERBURN)
    if level < 1 then return end

    local data = entity:GetData()

    data.player = player

    if not data.buildup then
        data.buildup = 0
    end

    local DURATION = BASE_DURATION
    if level > 1 then
        DURATION = LEVEL2_DURATION
    end

    --refresh duration
    if StatusEffectLibrary:HasStatusEffect(entity, StatusEffectLibrary.StatusFlag.AFTERBURN) then
        StatusEffectLibrary:AddStatusEffect(
            entity,
            StatusEffectLibrary.StatusFlag.AFTERBURN,
            DURATION * 30,
            EntityRef(player)
        )
        return
    end

    data.buildup = data.buildup + amount

    local required
    if level == 1 then
        required = DAMAGE_REQUIRED_L1
    elseif level == 2 then
        required = DAMAGE_REQUIRED_L2
    else
        required = DAMAGE_REQUIRED_L3
    end

    data.required = required

    --proc
    if data.buildup >= required then
        StatusEffectLibrary:AddStatusEffect(
            entity,
            StatusEffectLibrary.StatusFlag.AFTERBURN,
            DURATION * 30,
            EntityRef(player)
        )

        DeadlockMod.sfx:Play(DeadlockMod.SoundID.InfernusAbilities.AFTERBURN.PROC)

        data.buildup = 0
    end
end
DeadlockMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, afterburnOnDamage)

local function applyAfterburnTint(npc, percent)

    -- From normal → red-hot
    local r = 1
    local g = 1 - (0.6 * percent)
    local b = 1 - (0.6 * percent)

    npc:SetColor(Color(r, g, b, 1), 2, 1, false, false)
end


---@param npc EntityNPC
local function afterburnNPCUpdate(_, npc)
    local data = npc:GetData()
    if not data.buildup or not data.required then return end

    ---@type EntityPlayer
    local player = data.player
    local level = player:GetEffects():GetNullEffectNum(DeadlockMod.NullID.InfernusAbilities.AFTERBURN)

    local percent = data.buildup / data.required


    local DAMAGE_PER_TICK = BASE_DAMAGE_PER_TICK
    if level == 3 then
        DAMAGE_PER_TICK = LEVEL3_DAMAGE_PER_TICK
    end

    local DECAY_PER_SECOND = player.Damage * 0.6
    if DECAY_PER_SECOND < 1 then
        DECAY_PER_SECOND = 1
    end
    local AFTERBURN_DECAY_PER_FRAME = DECAY_PER_SECOND / 30

    local DAMAGE = player.Damage * DAMAGE_PER_TICK
    if DAMAGE < 2 then
        DAMAGE = 2
    end
    if StatusEffectLibrary:HasStatusEffect(npc, StatusEffectLibrary.StatusFlag.AFTERBURN) then
        if DeadlockMod.game:GetFrameCount() % 15 == 0 then
            npc:TakeDamage(DAMAGE, DamageFlag.DAMAGE_CLONES, EntityRef(player), 1)
        end
    else
        applyAfterburnTint(npc, percent)
        data.buildup = math.max(0, data.buildup - AFTERBURN_DECAY_PER_FRAME)
    end

end
DeadlockMod:AddCallback(ModCallbacks.MC_NPC_UPDATE, afterburnNPCUpdate)

---@param npc EntityNPC
local function afterburnNPCRender(_, npc)
    local data = npc:GetData()
    if not data.buildup then return end

    local screenPos = Isaac.WorldToScreen(npc.Position)

    Isaac.RenderText(tostring(data.buildup), screenPos.X, screenPos.Y, 1, 1, 1, 1)
end
--DeadlockMod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, afterburnNPCRender) --USEFUL FOR DEBUGGING, KEEP AROUND



return afterburn