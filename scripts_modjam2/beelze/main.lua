---@class ModReference
local mod = RegisterMod("Beelze", 1)
local game = Game()
local sfx = SFXManager()

mod.PLAYER_BEELZE = Isaac.GetPlayerTypeByName("Beelze")
mod.PLAYER_BEELZE_ALT = Isaac.GetPlayerTypeByName("Beelze", true) -- The Verminous

mod.NULLITEM_BOTFLY_MAGGOT = Isaac.GetNullItemIdByName("Botfly Maggot")

mod.FAMILIAR_BOTFLY_MAGGOT = Isaac.GetEntityVariantByName("Botfly Maggot")
mod.FAMILIAR_UTILITY_FLY = Isaac.GetEntityVariantByName("Utility Fly")

mod.ACHIEVEMENT_THE_VERMINOUS = Isaac.GetAchievementIdByName("The Verminous")

mod.CONST_POOTER_ROLL_LOW = 0
mod.CONST_POOTER_ROLL_HIGH = 1 / 3
mod.CONST_SUCKER_ROLL_LOW = 1 / 3
mod.CONST_SUCKER_ROLL_HIGH = 2 / 3
mod.CONST_POOTER_TARGET_DIST = 40 * 4
mod.CONST_POOTER_SLOWDOWN_SPEED = 10
mod.CONST_POOTER_ATTACK_SPEED = 30
mod.CONST_CHARGE_TO_FLY_MULT = 2
mod.CONST_POOTER_PREDICTION_STRENGTH = 7.5
mod.CONST_POOTER_FIRE_COOLDOWN_MULT = 2
mod.CONST_SCALE_OFFSET_MULT = 8

mod.CONST_INFESTED_EYE_MULT = 0.7 -- 30% less damage

mod.CONST_INFESTATION_BULB_CHANCE = 0.03 -- 3% (scales based on the amount of bulbs in the room)
mod.CONST_INFESTATION_FLY_CHANCE = 1 -- 100% (scales based on the amount of flies in the room)
mod.CONST_INFESTATION_FLY_INVINCIBILITY = 15 -- 0.5 seconds (due to the fact they spawn on top of enemies)
mod.CONST_INFESTATION_FLY_SPAWN_SPEED = 10
mod.CONST_INFESTATION_DURATION = 120 -- 4 seconds

mod.CONST_DOUBLE_TAP_WINDOW = 9 -- 0.3 seconds
mod.CONST_RELEASE_KNOCKBACK_SPEED = 3 -- Whenever summing the maggot get knockbacked
mod.CONST_MIN_DAMAGE_FLIES = 2 -- Blue flies that spawn when taking damage
mod.CONST_MAX_DAMAGE_FLIES = 4

mod.CONST_MAGGOT_COOLDOWN = 30 -- 1 second
mod.CONST_MAGGOT_SPEED = 18

mod.CONST_BULB_SPEED = 12
mod.CONST_BULB_ACTIVE_CHARGE = 1
mod.CONST_BULB_FRICTION = 0.85
mod.CONST_BULB_LIFETIME = 300 -- 10 seconds

---@type table<TearVariant, TearVariant>
mod.DICT_BLUE_TEAR_TO_BLOOD_TEAR = {
    [TearVariant.BLUE] = TearVariant.BLOOD,
    [TearVariant.CUPID_BLUE] = TearVariant.CUPID_BLOOD,
    [TearVariant.NAIL] = TearVariant.NAIL_BLOOD,
    [TearVariant.PUPULA] = TearVariant.PUPULA_BLOOD,
    [TearVariant.GODS_FLESH] = TearVariant.GODS_FLESH_BLOOD,
    [TearVariant.GLAUCOMA] = TearVariant.GLAUCOMA_BLOOD,
    [TearVariant.EYE] = TearVariant.EYE_BLOOD,
    [TearVariant.KEY] = TearVariant.KEY_BLOOD,
}

if EID then
    local player = EntityConfig.GetPlayer(mod.PLAYER_BEELZE)
    local old = player:GetModdedCoopMenuSprite()

    if old then
        local new = Sprite()
        local anim = player:GetName()
        new:Load(old:GetFilename())
        new:Play(anim, true)
        new:GetLayer(0):SetSize(Vector.One * 0.7)
        EID:addIcon("Player" .. mod.PLAYER_BEELZE, anim, 0, 16, 16, 7.5, 5, new)
    end
	
	local playerAlt = EntityConfig.GetPlayer(mod.PLAYER_BEELZE_ALT) -- Not using :GetTaintedCounterpart() because it returned nil whenever I booted the game up
	local oldAlt = playerAlt:GetModdedCoopMenuSprite()
	
	if oldAlt then
		local new = Sprite(oldAlt:GetFilename())
		local anim = playerAlt:GetName()
		new:Play(anim, true)
		new:GetLayer(0):SetSize(Vector.One * 0.7)
		EID:addIcon("Player" .. mod.PLAYER_BEELZE_ALT, anim, 0, 16, 16, 7.5, 5, new)
	end

    EID:addCharacterInfo(
        mod.PLAYER_BEELZE,
        "#Blue spiders are replaced with blue flies#Using an active item spawns blue flies#Blue flies copy tear effects and have a chance to be stronger variants",
        "Beelze"
    )
	EID:addCharacterInfo(
        mod.PLAYER_BEELZE_ALT,
        "#{{Damage}} Left eye deals 30% less damage#Double-tap a fire button to release a maggot#Maggot deals Isaac's left-eye damage and infests enemies#Infested enemies have a chance to spawn blue flies when hit#Taking damage spawns 2-4 blue flies",
        "Beelze"
    )

    EID:addBirthright(
        mod.PLAYER_BEELZE,
        "All blue flies are stronger variants"
    )
	EID:addBirthright(
        mod.PLAYER_BEELZE_ALT,
        "Infestation yields double the flies and lasts 50% longer"
    )
end

function mod.RandomIntRange(minimum, maximum, seed, rng)
	rng = rng or RNG(math.max(seed or Random(), 1))
	
	return rng:RandomInt(minimum, maximum)
end

function mod.RandomFloatRange(minimum, maximum, seed, rng)
	rng = rng or RNG(math.max(seed or Random(), 1))
	
	return minimum + rng:RandomFloat() * (maximum - minimum)
end

---@param entity Entity
function mod:GetData(entity)
    local data = entity:GetData()
    data.thisismynewcharacterbeelzeforthemodjam = data.thisismynewcharacterbeelzeforthemodjam or {}
    ---@class BeelzeData
    ---@field Color Color
    ---@field Damage number
    ---@field Flags BitSet128
    ---@field Scale number
    ---@field Sucker boolean
    ---@field Pooter boolean
    ---@field PooterStateFrame integer
    ---@field PooterAimVect Vector
    return data.thisismynewcharacterbeelzeforthemodjam
end

---@param familiar EntityFamiliar
---@param data? table
function mod:UpdateFly(familiar, data)
    data = data or mod:GetData(familiar)

    if data.Color then
        familiar.Color = data.Color
    end

    if data.Scale then
        familiar.SpriteScale = familiar.SpriteScale * data.Scale
    end
end

---@param familiar EntityFamiliar
---@param data? BeelzeData
function mod:ConvertToPooter(familiar, data)
    data = data or mod:GetData(familiar)

    data.Pooter = true

    local sprite = familiar:GetSprite()

    sprite:Load("gfx/familiar_pooter.anm2", true)
    sprite:Play("Fly", true)
end

---@param familiar EntityFamiliar
---@param data? BeelzeData
function mod:ConvertToSucker(familiar, data)
    data = data or mod:GetData(familiar)

    data.Sucker = true

    local sprite = familiar:GetSprite()

    sprite:Load("gfx/familiar_sucker.anm2", true)
    sprite:Play("Fly", true)
end

---@param familiar EntityFamiliar
---@param data? BeelzeData
function mod:TryConvertRandom(familiar, data)
    data = data or mod:GetData(familiar)
	local player = familiar.Player

    if data.Pooter or data.Sucker then
        return false
    end

    local roll = familiar:GetDropRNG():RandomFloat()

    if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and player:GetPlayerType() ~= mod.PLAYER_BEELZE_ALT then
        if roll < 0.5 then
            mod:ConvertToPooter(familiar, data)
        else
            mod:ConvertToSucker(familiar, data)
        end
    else
        if roll >= mod.CONST_POOTER_ROLL_LOW and roll <= mod.CONST_POOTER_ROLL_HIGH then
            mod:ConvertToPooter(familiar, data)
        elseif roll >= mod.CONST_SUCKER_ROLL_LOW and roll <= mod.CONST_SUCKER_ROLL_HIGH then
            mod:ConvertToSucker(familiar, data)
        end
    end

    return true
end

---@param player EntityPlayer
---@param slot ActiveSlot
---@param removed? boolean
function mod:TryAddFliesOnUse(player, slot, removed)
    if player:GetPlayerType() ~= mod.PLAYER_BEELZE then
        return false
    end
    local charge = player:GetActiveMaxCharge(slot)
    if removed then
        charge = 12
    end
    if charge > 12 then
        charge = 1
    end
    charge = charge * mod.CONST_CHARGE_TO_FLY_MULT
    if charge == 0 then
        charge = 1
    end
    player:AddBlueFlies(charge, player.Position, player)
    return true
end

-- Infestation
function mod.AddInfestation(entity, source, duration)
	if entity:IgnoreEffectFromFriendly(source) then return end
	if entity:HasEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS) then return end
	if entity:GetBossStatusEffectCooldown() > 0 then return end
	local entityData = mod:GetData(entity)
	
	if entity:IsBoss() then entity:SetBossStatusEffectCooldown(240) end
	entityData.InfestationDuration = entity:ComputeStatusEffectDuration(duration, source)
	entity:SetColor(Color(1, 1, 1, 1, 0.14, 0.1, 0.07, 4, 3.5, 3.2, 0.25), entityData.InfestationDuration, 0)
end

function mod.GetInfestationDuration(entity)
	return mod:GetData(entity).InfestationDuration or 0
end

function mod.HasInfestation(entity)
	return (mod:GetData(entity).InfestationDuration or 0) ~= 0
end

function mod.ClearInfestation(entity)
	mod:GetData(entity).InfestationDuration = nil
end

function mod.Spawn(type, variant, subtype, position, velocity, spawner, seed)
	return game:Spawn(type, variant, position, velocity or Vector.Zero, spawner, subtype, math.max(seed or Random(), 1))
end

function mod.AddBotflyMaggotFamiliar(player, position, velocity)
	return mod.Spawn(EntityType.ENTITY_FAMILIAR, mod.FAMILIAR_BOTFLY_MAGGOT, 0, position or player.Position, velocity, player):ToFamiliar()
end

function mod.MakeBloodSplat(entity, position, scale, color, offset)
	local effect = mod.Spawn(
		EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_SPLAT, 0, 
		position or entity.Position, nil, entity):ToEffect()
	
	if scale then effect.SpriteScale = scale * Vector.One end
	if color then effect.Color = color end
	if offset then effect.PositionOffset = offset end
	effect:AddEntityFlags(EntityFlag.FLAG_RENDER_FLOOR | EntityFlag.FLAG_RENDER_WALL)
	effect:Update()
	
	return effect
end

function mod.AnyoneHasActiveItem()
	for _, player in pairs(PlayerManager.GetPlayers()) do
		for slot = ActiveSlot.SLOT_PRIMARY, ActiveSlot.SLOT_POCKET2 do
			if player:GetActiveItem(slot) ~= CollectibleType.COLLECTIBLE_NULL then
				return true
			end
		end
	end
	return false
end

---@param player EntityPlayer
---@param params TearParams
---@param source Entity
mod:AddCallback(ModCallbacks.MC_EVALUATE_TEAR_HIT_PARAMS, function (_, player, params, weaponType, damageMult, displacement, source)
	local playerType = player:GetPlayerType()
	
	if playerType == mod.PLAYER_BEELZE_ALT and displacement == -1 then
		params.TearDamage = params.TearDamage * mod.CONST_INFESTED_EYE_MULT
		params.TearScale = params.TearScale * mod.CONST_INFESTED_EYE_MULT
		params.TearColor = Color.ProjectileCorpsePink
	end
    if (playerType ~= mod.PLAYER_BEELZE and playerType ~= mod.PLAYER_BEELZE_ALT)
    or (
        source
        and source.Type == EntityType.ENTITY_FAMILIAR
        and source.Variant == FamiliarVariant.BLUE_FLY
    )
    or not mod.DICT_BLUE_TEAR_TO_BLOOD_TEAR[params.TearVariant] then return end
    params.TearVariant = mod.DICT_BLUE_TEAR_TO_BLOOD_TEAR[params.TearVariant]
end)

mod:AddCallback(ModCallbacks.MC_PLAYER_INIT_POST_LEVEL_INIT_STATS, function(_, player)
	player:AddNullItemEffect(mod.NULLITEM_BOTFLY_MAGGOT, true)
end, mod.PLAYER_BEELZE_ALT)

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_NEW_ROOM_TEMP_EFFECTS, function(_, player)
	player:AddNullItemEffect(mod.NULLITEM_BOTFLY_MAGGOT, true)
end, mod.PLAYER_BEELZE_ALT)

---@param familiar EntityFamiliar
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function (_, familiar)
	local player = familiar.Player
	local playerType = player:GetPlayerType()
	
    if playerType ~= mod.PLAYER_BEELZE and playerType ~= mod.PLAYER_BEELZE_ALT then return end
    player:AddBlueFlies(1, familiar.Position, player)
    familiar:RemoveFromPlayer()
end, FamiliarVariant.BLUE_SPIDER)

---@param familiar EntityFamiliar
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function (_, familiar)
	local player = familiar.Player
	local playerType = player:GetPlayerType()
	
    if playerType ~= mod.PLAYER_BEELZE and playerType ~= mod.PLAYER_BEELZE_ALT then return end

    local data = mod:GetData(familiar)
    local params = familiar.Player:GetTearHitParams(WeaponType.WEAPON_TEARS)

    data.Damage = params.TearDamage * 2
    data.Flags = params.TearFlags
    data.Color = params.TearColor
    data.Scale = params.TearScale

    mod:UpdateFly(familiar, data)
	mod:TryConvertRandom(familiar, data)
end, FamiliarVariant.BLUE_FLY)

---@param familiar EntityFamiliar
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function (_, familiar)
    local data = mod:GetData(familiar)

    mod:UpdateFly(familiar, data)

    if data.Pooter then
        familiar.FireCooldown = familiar.FireCooldown - (familiar.Player:HasTrinket(TrinketType.TRINKET_FORGOTTEN_LULLABY) and 2 or 1)
        local sprite = familiar:GetSprite()
        local shoot = sprite:IsEventTriggered("Shoot")

        if familiar.Target and familiar.FrameCount > 30 then
            familiar.FlipX = familiar.Target.Position.X < familiar.Position.X

            if familiar.Position:Distance(familiar.Target.Position) <= mod.CONST_POOTER_TARGET_DIST then
                data.PooterStateFrame = math.min(mod.CONST_POOTER_SLOWDOWN_SPEED, (data.PooterStateFrame or 0) + 1)

                if familiar.FireCooldown <= 0 then
                    shoot = shoot or sprite:IsPlaying("Attack")
                    sprite:Play("Attack", true)
                    familiar.FireCooldown = math.ceil(familiar.Player.MaxFireDelay * mod.CONST_POOTER_FIRE_COOLDOWN_MULT)
                end
            else
                data.PooterStateFrame = math.max(0, (data.PooterStateFrame or 0) - 1)
            end

            if sprite:IsPlaying("Attack") and not sprite:WasEventTriggered("Shoot") then
                data.PooterAimVect = (familiar.Target.Position - familiar.Position + familiar.Target.Velocity * mod.CONST_POOTER_PREDICTION_STRENGTH)
            end
        else
            data.PooterStateFrame = math.max(0, (data.PooterStateFrame or 0) - 1)
            familiar.FlipX = data.PooterAimVect and data.PooterAimVect.X < 0
        end

        if sprite:IsFinished("Attack") then
            sprite:Play("Fly", true)
        end

        if shoot and data.PooterAimVect then
            local tear = familiar.Player:FireTear(
                familiar.Position,
                data.PooterAimVect:Resized(familiar.Player.ShotSpeed * 10),
                true,
                true,
                false,
                familiar,
                familiar:GetMultiplier()
            )
            tear:AddTearFlags(TearFlags.TEAR_SPECTRAL)
            data.PooterAimVect = nil
        end

        familiar.Velocity = familiar.Velocity * math.max(0, (mod.CONST_POOTER_SLOWDOWN_SPEED - data.PooterStateFrame) / mod.CONST_POOTER_SLOWDOWN_SPEED)
    end
end, FamiliarVariant.BLUE_FLY)

---@param entity Entity
---@param amt number
---@param flags DamageFlag
---@param source EntityRef
---@param cooldown integer
mod:AddPriorityCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CallbackPriority.LATE, function (_, entity, amt, flags, source, cooldown)
    if not source.Entity
    or source.Entity.Type ~= EntityType.ENTITY_FAMILIAR
    or source.Entity.Variant ~= FamiliarVariant.BLUE_FLY then return end

    local npc = entity:ToNPC()
    if not npc then return end

    local data = mod:GetData(source.Entity)

    if data.Sucker then
        local familiar = source.Entity:ToFamiliar()

        for i = 1, 4 do
            local tear = familiar.Player:FireTear(
                familiar.Position,
                Vector(familiar.Player.ShotSpeed * 10, 0):Rotated(90 * i),
                true,
                true,
                false,
                familiar,
                familiar:GetMultiplier() / 2
            )
            tear:AddTearFlags(TearFlags.TEAR_SPECTRAL)
        end
    end

    if data.Damage then
        npc:ApplyTearflagEffects(source.Entity.Position, data.Flags or TearFlags.TEAR_NORMAL, source.Entity, data.Damage / 2)

        return {
            Damage = data.Damage * source.Entity:ToFamiliar():GetMultiplier()
        }
    end
end)

---@param familiar EntityFamiliar
mod:AddPriorityCallback(ModCallbacks.MC_PRE_FAMILIAR_RENDER, CallbackPriority.LATE, function (_, familiar)
    local data = mod:GetData(familiar)
    if not data.Scale then return end
    return Vector(0, (data.Scale - 1) * mod.CONST_SCALE_OFFSET_MULT)
end, FamiliarVariant.BLUE_FLY)

---@param player EntityPlayer
---@param slot ActiveSlot
mod:AddPriorityCallback(ModCallbacks.MC_PRE_USE_ITEM, CallbackPriority.LATE, function (_, _, _, player, _, slot)
    mod:TryAddFliesOnUse(player, slot)
end, CollectibleType.COLLECTIBLE_ESAU_JR)

---@param id CollectibleType
---@param removed boolean
---@param player EntityPlayer
---@param slot ActiveSlot
mod:AddCallback(ModCallbacks.MC_POST_DISCHARGE_ACTIVE_ITEM, function (_, id, removed, player, slot)
    if id == CollectibleType.COLLECTIBLE_ESAU_JR then return end
    mod:TryAddFliesOnUse(player, slot, removed)
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, function (_, _, _, _, _, _, player)
    if player:GetPlayerType() ~= mod.PLAYER_BEELZE then return end
    local hash = GetPtrHash(player)
    for _, v in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY)) do
        v = v:ToFamiliar()
        if GetPtrHash(v.Player) == hash then
            if mod:TryConvertRandom(v) then
                sfx:Play(SoundEffect.SOUND_THUMBSUP)
                Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, v.Position, Vector.Zero, nil)
            end
        end
    end
end, CollectibleType.COLLECTIBLE_BIRTHRIGHT)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        if player:GetPlayerType() == mod.PLAYER_BEELZE then
            for i = ActiveSlot.SLOT_PRIMARY, ActiveSlot.SLOT_POCKET do
                local config = Isaac.GetItemConfig():GetCollectible(player:GetActiveItem(i))
                if config and (config.ChargeType == 1 or player:GetActiveMaxCharge(i) == 0) then
                    local hash = GetPtrHash(player)
                    for _, v in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY)) do
                        v = v:ToFamiliar()
                        if GetPtrHash(v.Player) == hash then
                            v:Remove()
                        end
                    end
                end
            end
        end
    end
end)

-- Infestation
local iconSpr = Sprite("gfx/statuseffect_infestation.anm2")

mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc, offset)
	if game:GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return end
	
	if mod.HasInfestation(npc) then
		local nullFrame = npc:GetSprite():GetNullFrame("OverlayEffect")
		
		if nullFrame and nullFrame:IsVisible() then
			iconSpr:SetFrame("Idle", npc.FrameCount % iconSpr:GetAnimationData("Idle"):GetLength())
			iconSpr:Render(Isaac.GetRenderPosition(npc.Position + npc.PositionOffset) + nullFrame:GetPos() + offset)
		end
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function(_, player, offset) -- Added player rendering for consistency
	if game:GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return end
	
	if mod.HasInfestation(player) then
		local posOffset = player:GetFlyingOffset() - Vector(0, 34) * player.SpriteScale
		
		iconSpr.Scale = player.SpriteScale
		iconSpr:SetFrame("Idle", player.FrameCount % iconSpr:GetAnimationData("Idle"):GetLength())
		iconSpr:Render(Isaac.GetRenderPosition(player.Position + player.PositionOffset) + posOffset + offset)
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	for _, entity in pairs(Isaac.GetRoomEntities()) do
		local entityData = mod:GetData(entity)
		
		if entityData.InfestationDuration and entityData.InfestationDuration > 0 then
			entityData.InfestationDuration = entityData.InfestationDuration - 1
			if entityData.InfestationDuration < 1 then
				entityData.InfestationDuration = nil
			end
		end
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_ENTITY_TAKE_DMG, function(_, entity, amount, flag, source, countdown)
	if entity and mod.HasInfestation(entity) and amount > 0 then
		local rng = entity:GetDropRNG()
		local flyNum = PlayerManager.AnyPlayerTypeHasBirthright(mod.PLAYER_BEELZE_ALT) and 2 or 1
		local flyChance = mod.CONST_INFESTATION_FLY_CHANCE / (#Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY) + 1)
		local bulbChance = mod.CONST_INFESTATION_BULB_CHANCE / (#Isaac.FindByType(EntityType.ENTITY_FAMILIAR, mod.FAMILIAR_UTILITY_FLY) + 1)
		local smallFlyChance = 2 / (#Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.TINY_FLY) + 1) -- Just for the effect :3
		
		if rng:RandomFloat() <= flyChance then
			local fam = game:GetNearestPlayer(entity.Position):AddBlueFlies(flyNum, entity.Position, nil):ToFamiliar() -- Need to spawn flies like this otherwise Compost doesn't work (that's due to the flynum value the player has that only this function increases)
			
			fam.State = mod.CONST_INFESTATION_FLY_INVINCIBILITY
			fam.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			fam:AddVelocity(RandomVector() * mod.CONST_INFESTATION_FLY_SPAWN_SPEED)
		end
		if rng:RandomFloat() <= bulbChance and mod.AnyoneHasActiveItem() then
			local fam = mod.Spawn(EntityType.ENTITY_FAMILIAR, mod.FAMILIAR_UTILITY_FLY, 0, entity.Position, nil, source.Entity):ToFamiliar()
			
			fam:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		end
		if rng:RandomFloat() <= smallFlyChance then
			for _ = 1, flyNum do mod.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TINY_FLY, 0, entity.Position, RandomVector() * 4) end
		end
	end
	local player = entity and entity:ToPlayer()
	
	if player and player:GetPlayerType() == mod.PLAYER_BEELZE_ALT then
		player:AddBlueFlies(mod.RandomIntRange(mod.CONST_MIN_DAMAGE_FLIES, mod.CONST_MAX_DAMAGE_FLIES), player.Position, nil)
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, entity, source)
	if entity and mod.HasInfestation(entity) then
		for _ = 0, math.min(entity.MaxHitPoints // 12, 8) do
			mod.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.WORM, 1, entity.Position)
		end
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
	local playerData = mod:GetData(player)
	local playerFx = player:GetEffects()
	
	if playerFx:HasNullEffect(mod.NULLITEM_BOTFLY_MAGGOT) then
		local fireDir = player:GetFireDirection()
		
		if fireDir ~= Direction.NO_DIRECTION and fireDir ~= playerData.CurrentMaggotDir then
			if fireDir == playerData.LastMaggotDir and player.FrameCount - playerData.LastMaggotFrame <= mod.CONST_DOUBLE_TAP_WINDOW then
				local famDir = Isaac.GetAxisAlignedUnitVectorFromDir(fireDir)
				local fam = mod.AddBotflyMaggotFamiliar(player, nil, famDir * mod.CONST_MAGGOT_SPEED)
				
				fam:AddVelocity(player:GetTearMovementInheritance(fam.Velocity))
				fam:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				
				playerFx:RemoveNullEffect(mod.NULLITEM_BOTFLY_MAGGOT, -1)
				player:AddVelocity(-famDir * mod.CONST_RELEASE_KNOCKBACK_SPEED)
				
				local effectNum = mod.RandomIntRange(1, 2)
				for effectIdx = 1, effectNum + mod.RandomIntRange(1, 3) do
					local effectVel = fam.Velocity:Resized(mod.RandomFloatRange(6, 10)):Rotated(mod.RandomFloatRange(-12, 12))
					local effectType = effectIdx <= effectNum and 0 or 99
					local effect = Isaac.Spawn(
						EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_PARTICLE, effectType, 
						player.Position, effectVel, nil):ToEffect()
					effect.Color = Color.ProjectileCorpsePink
					effect.SplatColor = Color.ProjectileCorpsePink
				end
				mod.MakeBloodSplat(player, nil, nil, Color.ProjectileCorpsePink)
				player:SpawnBloodEffect(2, nil, nil, Color.ProjectileCorpsePink, fam.Velocity:Resized(5))
				
				sfx:Play(SoundEffect.SOUND_PLOP, 0.8, nil, nil, 0.8)
				sfx:Play(849, 0.8, nil, nil, 0.5)
			else
				playerData.LastMaggotDir = fireDir
				playerData.LastMaggotFrame = player.FrameCount
			end
		end
		playerData.CurrentMaggotDir = fireDir
	end
end, mod.PLAYER_BEELZE_ALT)

-- Botfly Maggot
local STATE_MOVE = 0
local STATE_COOLDOWN = 1

mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_, fam)
	fam:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_DONT_OVERWRITE)
end, mod.FAMILIAR_BOTFLY_MAGGOT)

mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, fam)
	local player = fam.Player
	local room = game:GetRoom()
	
	if room:GetFrameCount() == 0 then fam:RemoveFromPlayer() return end
	
	if fam.State == STATE_MOVE then
		local moveAnim = {"MoveRight", "MoveDown", "MoveLeft", "MoveUp"}
		fam:GetSprite():Play(moveAnim[(((fam.Velocity:GetAngleDegrees() + 45) // 90) % 4) + 1])
		
		local weapon = player:GetWeapon(1) -- Only the primary weapon
		fam.CollisionDamage = player:GetTearHitParams(weapon and weapon:GetWeaponType() or WeaponType.WEAPON_TEARS, 1, -1, player).TearDamage
		
		local roomOffset = -80
		if not room:IsPositionInRoom(fam.Position, roomOffset) then fam.Hearts = 1 end
		fam.Position = room:GetClampedPosition(room:ScreenWrapPosition(fam.Position, roomOffset), roomOffset)
		
		local famSpeed = fam.Velocity:Length()
		if famSpeed > 0 and fam.Hearts == 1 then
			fam.Velocity = (player.Position - fam.Position):Normalized() * famSpeed
		end
	elseif fam.State == STATE_COOLDOWN then
		fam.Keys = fam.Keys + 1
		fam.CollisionDamage = 0
		fam.Position = player.Position
		fam.Velocity = Vector.Zero
		fam.Visible = false
		
		if fam.Keys > mod.CONST_MAGGOT_COOLDOWN then
			player:AddNullItemEffect(mod.NULLITEM_BOTFLY_MAGGOT, true)
			sfx:Play(SoundEffect.SOUND_PLOP, 0.8, nil, nil, 1.4)
			fam:RemoveFromPlayer()
		end
	end
end, mod.FAMILIAR_BOTFLY_MAGGOT)

mod:AddCallback(ModCallbacks.MC_POST_FAMILIAR_COLLISION, function(_, fam, collider)
	local player = fam.Player
	
	if fam.State == STATE_MOVE then
		if fam.Hearts == 1 and GetPtrHash(player) == GetPtrHash(collider) then
			player:SpawnBloodEffect(2, nil, nil, Color.ProjectileCorpsePink)
			sfx:Play(913, 0.8) -- Void consume (they forgot about the enums in this patch lol)
			fam.State = STATE_COOLDOWN
		end
		if collider:IsEnemy() and collider:IsActiveEnemy() and not EntityRef(collider).IsCharmed then
			local InfestationMult = PlayerManager.AnyPlayerTypeHasBirthright(mod.PLAYER_BEELZE_ALT) and 1.5 or 1
			
			mod.AddInfestation(collider, EntityRef(player), mod.CONST_INFESTATION_DURATION * InfestationMult)
		end
	end
end, mod.FAMILIAR_BOTFLY_MAGGOT)

-- Bulb
local STATE_IDLE = 0
local STATE_MOVE = 1

mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_, fam)
	mod:GetData(fam).moveDir = Vector.Zero
	fam.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
end, mod.FAMILIAR_UTILITY_FLY)

mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, fam)
	local famData = mod:GetData(fam)
	local player = fam.Player
	
	if game:GetRoom():GetFrameCount() == 0 then fam:RemoveFromPlayer() return end
	if fam.FrameCount > mod.CONST_BULB_LIFETIME then
		fam:SpawnBloodEffect(2, nil, Vector(0, -16), Color(0, 0, 0, 0.6, 0.7, 0.7)).DepthOffset = 10
		EntityEffect.CreateLight(fam.Position, 0.75, 3, 3, Color(1, 1, 0)):GetSprite():SetFrame(1)
		sfx:Play(SoundEffect.SOUND_BULB_FLASH)
		fam:RemoveFromPlayer()
		return
	end
	
	local toPlayer = player.Position - fam.Position
	local distToPlayer = toPlayer:Length()
	
	if fam.State == STATE_IDLE then
		fam.Velocity = fam.Velocity * mod.CONST_BULB_FRICTION
		
		if game:GetFrameCount() % 5 == 0 then
			local randomVec = RandomVector() * mod.RandomIntRange(1, 6)
			
			fam:AddVelocity(-famData.moveDir + randomVec)
			famData.moveDir = randomVec
		end
		fam.Hearts = fam.Hearts - 1
		
		if fam.Hearts <= 0 then
			local randomOffset = RandomVector() * mod.RandomIntRange(30, 60)
			fam.TargetPosition = fam.Position + randomOffset
			
			famData.moveDir = randomOffset:Normalized()
			
			fam.Hearts = mod.RandomIntRange(6, 30)
			fam.Keys = 6
			fam.State = STATE_MOVE
			
			fam:AddVelocity(famData.moveDir * 4)
			fam:GetSprite().FlipX = famData.moveDir.X < 0
		end
	elseif fam.State == STATE_MOVE then
		fam.Velocity = fam.Velocity * mod.CONST_BULB_FRICTION
		fam:AddVelocity(famData.moveDir * 2)
		
		if fam.Velocity:Length() > mod.CONST_BULB_SPEED then
			fam.Velocity = fam.Velocity:Resized(mod.CONST_BULB_SPEED)
		end
		fam.Keys = fam.Keys - 1
		
		if (fam.TargetPosition - fam.Position):Dot(famData.moveDir) < 0 or fam.Keys <= 0 then
			fam:AddVelocity(-famData.moveDir * 4)
			fam.State = STATE_IDLE
			famData.moveDir = Vector.Zero
		end
	end
end, mod.FAMILIAR_UTILITY_FLY)

mod:AddCallback(ModCallbacks.MC_POST_FAMILIAR_COLLISION, function(_, fam, collider)
	local player = collider and collider:ToPlayer()
	if not player then return end
	
	for slot = ActiveSlot.SLOT_PRIMARY, ActiveSlot.SLOT_POCKET2 do
		if player:NeedsCharge(slot) then
			local effect = mod.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 1, player.Position, nil, player):ToEffect()
			effect.SpriteOffset = Vector(0, -24)
			effect.DepthOffset = 1
			
			fam:SpawnBloodEffect(2, nil, Vector(0, -16), Color(0, 0, 0, 0.6, 0.7, 0.7)).DepthOffset = 10
			EntityEffect.CreateLight(fam.Position, 0.75, 3, 3, Color(1, 1, 0)):GetSprite():SetFrame(1)
			
			player:AddActiveCharge(mod.CONST_BULB_ACTIVE_CHARGE, slot, nil, nil, true)
			sfx:Play(SoundEffect.SOUND_BULB_FLASH)
			fam:RemoveFromPlayer()
			
			break
		end
	end
end, mod.FAMILIAR_UTILITY_FLY)

--------------------------
-- << UNLOCK TAINTED >> --
--------------------------
mod:AddCallback(ModCallbacks.MC_PRE_ROOM_ENTITY_SPAWN, function(_, type, variant, subtype, gridId, seed)
	if Isaac.GetPlayer():GetPlayerType() ~= mod.PLAYER_BEELZE then return end
    if Isaac.GetPersistentGameData():Unlocked(mod.ACHIEVEMENT_THE_VERMINOUS) then return end
	if type == EntityType.ENTITY_SLOT and variant == SlotVariant.HOME_CLOSET_PLAYER then return {type, variant} end
end)

mod:AddCallback(ModCallbacks.MC_POST_SLOT_INIT, function(_, slot) -- The game doesn't do this for tainted modded characters
	if Isaac.GetPlayer():GetPlayerType() ~= mod.PLAYER_BEELZE then return end
	local playerConfig = EntityConfig.GetPlayer(mod.PLAYER_BEELZE):GetTaintedCounterpart()
	
	slot:GetSprite():ReplaceSpritesheet(0, playerConfig:GetSkinPath(), true)
end, SlotVariant.HOME_CLOSET_PLAYER)

mod:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, function(_, slot)
	if slot:IsDead() and slot:GetSprite():IsFinished() then
		if Isaac.GetPlayer():GetPlayerType() == mod.PLAYER_BEELZE then
			Isaac.GetPersistentGameData():TryUnlock(mod.ACHIEVEMENT_THE_VERMINOUS)
		end
	end
end, SlotVariant.HOME_CLOSET_PLAYER)

--[[
local spr = Sprite("gfx/001.000_player.anm2", true)
spr:ReplaceSpritesheet(PlayerSpriteLayer.SPRITE_BODY, "gfx/characters/costume_botfly_maggot_skin", true)

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function(_, player, offset)
	if player:GetEffects():HasCollectibleEffect(mod.NULLITEM_BOTFLY_MAGGOT) then
		spr:Play(player:GetAnimation())
		spr:Render(player.Position)
	end
end)
--]]

return mod