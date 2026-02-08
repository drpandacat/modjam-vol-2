local mod = _HART_MOD
local game = Game()
local sfx = SFXManager()

local IFRAMES_MULTIPLIER = 1.5
local DAMAGE_MULTIPLIER = 1.4

--[[
local SOUL_HEART_CHANCE = 0.3
local SOUL_HEART_REPLACE_SUBS = {
    [HeartSubType.HEART_FULL] = HeartSubType.HEART_SOUL,
    [HeartSubType.HEART_HALF] = HeartSubType.HEART_HALF_SOUL,
    [HeartSubType.HEART_BLENDED] = HeartSubType.HEART_SOUL,
}
--]]

local PETRIFY_FREEZE_COLOR = Color(0.22,0.22,0.33,1,0.16,0.18,0.24,0,0,0,0)

local FREEZE_COLOR = Color(0.8,0.8,0.8,1,0.3,0.5,0.8,1,1,1,0.5)
local ONHIT_FREEZE_DURATION = 30*10
local FREEZE_MASH_DECREASE = 20
local FREEZE_MASH_HOP = 3
local FREEZE_MASH_BACKHOP = 0.4
local MASH_BUTTON_MAP = {
    [ButtonAction.ACTION_LEFT] = 1,
    [ButtonAction.ACTION_UP] = 1,
    [ButtonAction.ACTION_DOWN] = 1,
    [ButtonAction.ACTION_RIGHT] = 1,
    [ButtonAction.ACTION_SHOOTRIGHT] = 0,
    [ButtonAction.ACTION_SHOOTLEFT] = 0,
    [ButtonAction.ACTION_SHOOTDOWN] = 0,
    [ButtonAction.ACTION_SHOOTUP] = 0,
    [ButtonAction.ACTION_BOMB] = 0,
    [ButtonAction.ACTION_ITEM] = 0,
    [ButtonAction.ACTION_PILLCARD] = 0,
}

local BRFREEZE_SPEED = 6
local BRFREEZE_CONTACTDMG = 15
local BRFREEZE_SHATTER_TEARSNUM = 7

local BRFREEZE_TICKTHRESHOLD_SLOW = 30*3
local BRFREEZE_TICKFREQ_SLOW = 15
local BRFREEZE_TICKDUR_SLOW = 5
local BRFREEZE_TICKTHRESHOLD_FAST = 30*1
local BRFREEZE_TICKFREQ_FAST = 10
local BRFREEZE_TICKDUR_FAST = 4

---@param luck number
local function getFreezeChance(luck)
	return 0.16 + 0.03 * luck
end

---@param pl EntityPlayer
local function tHartInit(_, pl)
    if(pl:GetPlayerType()==mod.Character.HART_B) then
        local sp = pl:GetSprite()
        sp:Load("gfx/characters/character_t_hart.anm2", true)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, tHartInit, PlayerVariant.PLAYER)

---@param isContinued boolean
local function removeEvilCharm(_, isContinued)
    if(PlayerManager.AnyoneIsPlayerType(mod.Character.HART_B)) then
        local pool = game:GetItemPool()
        if(pool:HasCollectible(CollectibleType.COLLECTIBLE_EVIL_CHARM)) then
			pool:RemoveCollectible(CollectibleType.COLLECTIBLE_EVIL_CHARM)
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, removeEvilCharm)

---@param pl EntityPlayer
---@param params TearParams
local function tHartParams(_, pl, params)
    if(RNG(math.max(Random(), 1)):RandomFloat()<getFreezeChance(pl.Luck * (pl:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 2 or 1))) then
        params.TearFlags = params.TearFlags | TearFlags.TEAR_FREEZE | TearFlags.TEAR_ICE
        params.TearVariant = TearVariant.ICE
    end
    if(pl:GetIceCountdown()>0 or pl:HasEntityFlags(EntityFlag.FLAG_ICE)) then
        params.TearVariant = TearVariant.ICE
    end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_TEAR_HIT_PARAMS, tHartParams, mod.Character.HART_B)

---@param pl EntityPlayer
---@param num number
local function evaluateDamage(_, pl, _, num)
    if(pl:GetPlayerType()==mod.Character.HART_B) then
        return num * DAMAGE_MULTIPLIER
    end
end
mod:AddPriorityCallback(ModCallbacks.MC_EVALUATE_STAT, CallbackPriority.LATE, evaluateDamage, EvaluateStatStage.FLAT_DAMAGE)

---@param pl EntityPlayer
local function updateHartB(_, pl)
    if(not pl:GetPlayerType()==mod.Character.HART_B) then return end

    if(pl:GetIceCountdown()>0 and not pl:IsDead()) then
        local hasBirthright = pl:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)

        local sp = pl:GetSprite()
        if(not hasBirthright) then
            local desiredFrame = 6
            if(sp:GetFrame()<desiredFrame) then
                sp.PlaybackSpeed = sp.PlaybackSpeed*0.94
            else
                sp.PlaybackSpeed = 0
                sp:SetFrame(desiredFrame)
            end

            pl:SetColor(FREEZE_COLOR, 2, 99, false, false)
        end

        local chosenDir = Vector(0,0)
        local isMashing = false

        local chosenAction = nil
        local cIdx = pl.ControllerIndex
        for action, val in pairs(MASH_BUTTON_MAP) do
            if(val==1 and Input.IsActionTriggered(action, cIdx)) then
                chosenAction = action
                isMashing = true
                break
            end
        end

        if(chosenAction) then
            for i, substr in ipairs({"RIGHT","DOWN","LEFT","UP"}) do
                if(chosenAction==ButtonAction["ACTION_"..substr] or chosenAction==ButtonAction["ACTION_SHOOT"..substr]) then
                    chosenDir = Vector.FromAngle((i-1)*90)
                    break
                end
            end
        end

        if(hasBirthright) then
            if(sp:GetAnimation()~="IceBlock") then
                sp:Play("IceBlock")
            end

            local data = pl:GetData()
            if(not (data.THartBounceTear and data.THartBounceTear:Exists())) then
                local vel = pl.Velocity:Resized(BRFREEZE_SPEED)
                local tear = Isaac.Spawn(2,0,0,pl.Position,vel,nil):ToTear() ---@cast tear EntityTear
                tear.Visible = false
                tear.TearFlags = TearFlags.TEAR_NORMAL | TearFlags.TEAR_BOUNCE
                tear.FallingAcceleration = -0.1
                tear.FallingSpeed = 0
                tear.CollisionDamage = BRFREEZE_CONTACTDMG

                tear.Scale = (pl.Size*2+1)/7
                --tear:SetSize(pl.Size, pl.SizeMulti, 12)

                data.THartBounceTear = tear
            end

            data.THartBounceTear.Position = pl.Position

            pl.Velocity = data.THartBounceTear.Velocity:Resized(BRFREEZE_SPEED)
            pl.Friction = 1

            pl:SetMinDamageCooldown(60)

            if(pl:GetIceCountdown()<=BRFREEZE_TICKTHRESHOLD_FAST) then
                if(pl:GetIceCountdown()%BRFREEZE_TICKFREQ_FAST==BRFREEZE_TICKFREQ_FAST-1) then
                    pl:SetColor(FREEZE_COLOR, BRFREEZE_TICKDUR_FAST, 10, false, true)
                end
            elseif(pl:GetIceCountdown()<=BRFREEZE_TICKTHRESHOLD_SLOW) then
                if(pl:GetIceCountdown()%BRFREEZE_TICKFREQ_SLOW==BRFREEZE_TICKFREQ_SLOW-1) then
                    pl:SetColor(FREEZE_COLOR, BRFREEZE_TICKDUR_SLOW, 10, false, true)
                end
            end

            if(data.THartEveryOtherFrame and pl.FrameCount%2==0) then
                local smokevel = Vector.FromAngle(math.random(1,360))*2-pl.Velocity:Normalized()*1
                local smoke = Isaac.Spawn(1000, EffectVariant.DUST_CLOUD, 1, pl.Position, smokevel, pl):ToEffect() ---@cast smoke EntityEffect
                smoke.SpriteRotation = math.random(360)
                smoke.Color = FREEZE_COLOR
                smoke.Color.A = 0.3

                smoke.SpriteScale = smoke.SpriteScale * math.random(70,100)/1000
                smoke:SetTimeout(20)
                smoke:Update()

                smoke.DepthOffset = 100
            end
            if(data.THartEveryOtherFrame and math.random()<0.33) then
                local creep = Isaac.Spawn(1000, EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL, 0, pl.Position, Vector.Zero, pl):ToEffect() ---@cast creep EntityEffect
                
                creep.CollisionDamage = 2

                creep.SpriteScale = creep.SpriteScale*pl.SpriteScale
                creep:SetTimeout(80)

                creep:Update()
            end
            
            data.THartEveryOtherFrame = not data.THartEveryOtherFrame
        else
            pl.Velocity = pl.Velocity*0.9
        end

        local justShattered = false
        if(isMashing) then
            pl:SetIceCountdown(math.max(0, pl:GetIceCountdown()-FREEZE_MASH_DECREASE))
            if(pl:GetIceCountdown()==0) then
                justShattered = true
            else
                sfx:Play(SoundEffect.SOUND_ANIMA_BREAK, 0.5, 4, false, 0.9+math.random()*0.2)

                pl.Position = pl.Position+chosenDir*FREEZE_MASH_HOP
                pl.Velocity = pl.Velocity-chosenDir*FREEZE_MASH_BACKHOP
            end

            local smokevel = Vector.FromAngle(math.random(1,360))*2-chosenDir*1
            local smoke = Isaac.Spawn(1000, EffectVariant.DUST_CLOUD, 1, pl.Position, smokevel, pl):ToEffect() ---@cast smoke EntityEffect
			smoke.SpriteRotation = math.random(360)
			smoke.Color = FREEZE_COLOR
            smoke.Color.A = 0.3

			smoke.SpriteScale = smoke.SpriteScale * math.random(70,100)/500
            smoke:SetTimeout(15)
			smoke:Update()

            smoke.DepthOffset = 100
        elseif(pl:GetIceCountdown()<=1) then
            justShattered = true
        end

        if(justShattered) then
            sp.PlaybackSpeed = 1

            pl:SetCanShoot(true)
            pl:UpdateCanShoot()

            if(hasBirthright) then
                local data = pl:GetData()
                if(data.THartBounceTear) then
                    if(data.THartBounceTear:Exists()) then
                        data.THartBounceTear:Remove()
                    end
                    data.THartBounceTear = nil
                end
                pl:StopExtraAnimation()

                pl:AddCacheFlags(CacheFlag.CACHE_SIZE)
                pl:EvaluateItems()

                local iceTearDmg = 12+2*(Game():GetLevel():GetAbsoluteStage()-1)
                for i=1, BRFREEZE_SHATTER_TEARSNUM do
                    local vel = Vector.FromAngle(i/BRFREEZE_SHATTER_TEARSNUM*360)*17
                    local tear = pl:FireTear(pl.Position,vel,false,true,false,pl,1)
                    tear.CollisionDamage = iceTearDmg
                    tear:AddTearFlags(TearFlags.TEAR_FREEZE | TearFlags.TEAR_ICE)
                    tear.FallingAcceleration = -0.05
                end
            end

            pl:SetIceCountdown(0)
            pl:ClearEntityFlags(EntityFlag.FLAG_ICE)

            sfx:Play(SoundEffect.SOUND_FREEZE_SHATTER)
            for _=1,3 do
                local vel = Vector.FromAngle(math.random(1,360))*Vector(3,1)
                local particle = Isaac.Spawn(1000, EffectVariant.ROCK_PARTICLE, 0, pl.Position, vel, pl):ToEffect() ---@cast particle EntityEffect
                particle.Color = FREEZE_COLOR
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, updateHartB, PlayerVariant.PLAYER)

---@param ent Entity
---@param flag DamageFlag
local function freezeOnHit(_, ent, _, flag, _, _)
    local pl = ent and ent:ToPlayer()
    if(pl and pl:GetPlayerType()==mod.Character.HART_B) then
        local doVfx = false
        if(not pl:IsDead() and flag & (DamageFlag.DAMAGE_RED_HEARTS | DamageFlag.DAMAGE_NO_PENALTIES) == 0) then
            local hasBirthright = pl:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
            
            if(pl:GetIceCountdown()==0 and not pl:HasEntityFlags(EntityFlag.FLAG_ICE)) then
                pl:AddIce(EntityRef(nil), -ONHIT_FREEZE_DURATION) -- i didnt know this works as a setter, thanks foks!
            end
            pl:SetMinDamageCooldown((pl:GetDamageCooldown()*IFRAMES_MULTIPLIER)//1)
            pl:SetCanShoot(false)

            if(hasBirthright) then
                pl:PlayExtraAnimation("IceBlock")
                pl:AddCacheFlags(CacheFlag.CACHE_SIZE)
                pl:EvaluateItems()
            end

            doVfx = true
        elseif(pl:IsDead()) then
            doVfx = true
		end

        if(doVfx) then
            sfx:Play(SoundEffect.SOUND_FREEZE)
            for _=math.random(0,1), 3 do
                local vel = Vector.FromAngle(math.random(1,360))*Vector(4,2)
                local particle = Isaac.Spawn(1000, EffectVariant.TOOTH_PARTICLE, 0, pl.Position, vel, pl):ToEffect() ---@cast particle EntityEffect
                particle.Color = FREEZE_COLOR
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_TAKE_DMG, freezeOnHit, EntityType.ENTITY_PLAYER)

---@param ent Entity
---@param hook InputHook
---@param action ButtonAction
local function cancelActionsWhileFrozen(_, ent, hook, action)
    local pl = ent and ent:ToPlayer()
    if(pl and pl:GetPlayerType()==mod.Character.HART_B and pl:HasEntityFlags(EntityFlag.FLAG_ICE)) then
        if(MASH_BUTTON_MAP[action]) then
            if(hook==InputHook.GET_ACTION_VALUE) then
                return 0
            else
                return false
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, cancelActionsWhileFrozen)

local statusFailsafe = false

---@param entity Entity
---@param source EntityRef
---@param duration number
local function hartBPetrifyEnemies(_, _, entity, source, duration)
    if(statusFailsafe) then return end

    local pl = source and source.Entity and mod.GetPlayerFromEntity(source.Entity)
    if(pl and pl:GetPlayerType()==mod.Character.HART_B) then
        local npc = entity and entity:ToNPC()
        if(npc) then
            statusFailsafe = true
            npc:AddIce(source, duration)
            statusFailsafe = false

            npc:GetData().HartBFrozen = true
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_STATUS_EFFECT_APPLY, hartBPetrifyEnemies, StatusEffect.FREEZE)

---@param npc EntityNPC
local function updateHartBFrozenenemy(_, npc)
    if(not npc:GetData().HartBFrozen) then return end

    if(npc:GetFreezeCountdown()>0) then
        npc.Color = PETRIFY_FREEZE_COLOR
    else
        npc.Color = Color.Default
        npc:GetData().HartBFrozen = nil
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, updateHartBFrozenenemy)

--[[
---@param pickup EntityPickup
---@param var PickupVariant
---@param sub integer
---@param rVar PickupVariant
---@param rSub integer
---@param rng RNG
local function replaceWithSoulHearts(_, pickup, var, sub, rVar, rSub, rng)
    if(var==PickupVariant.PICKUP_HEART and rSub==0) then
        if(SOUL_HEART_REPLACE_SUBS[sub] and rng:RandomFloat()<SOUL_HEART_CHANCE) then
            return {var, SOUL_HEART_REPLACE_SUBS[sub]}
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_SELECTION, replaceWithSoulHearts)
--]]

--[[
mod:AddPriorityCallback(ModCallbacks.MC_EVALUATE_STAT, CallbackPriority.LATE, function(_, player, stat, num) -- Works with Ipecac :3
	if player:GetPlayerType() == mod.Character.HART_B then return num * DAMAGE_MULTIPLIER end
end, EvaluateStatStage.FLAT_DAMAGE)
--]]