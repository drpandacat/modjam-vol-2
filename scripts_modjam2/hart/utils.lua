local mod = _HART_MOD
local game = Game()
local sfx = SFXManager()

----------------
-- << MATH >> --
----------------
function mod.Round(num, decimals)
	local factor = 10 ^ (decimals or 0)
	
	return math.floor(num * factor + 0.5) / factor
end

function mod.Clamp(value, minimum, maximum)
	if getmetatable(value) == getmetatable(Vector.Zero) then -- Checks if it is a vector
		return value:Resized(math.min(math.max(value:Length(), minimum), maximum))
	end
	return math.min(math.max(value, minimum), maximum)
end

function mod.Lerp(from, to, fraction)
	return from + (to - from) * fraction
end

function mod.LerpAngle(from, to, fraction, onlyPositive)
	local maxAngle = 360
    local disAngle = (to - from) % maxAngle
	
    if onlyPositive then
        disAngle = disAngle % maxAngle
    elseif disAngle > maxAngle / 2 then
        disAngle = disAngle - maxAngle
    end
    return (from + disAngle * fraction) % maxAngle
end

function mod.FireDelayToFireRate(fireDelay)
	return 30 / (fireDelay + 1)
end

function mod.FireRateToFireDelay(fireRate)
	return (30 / fireRate) - 1
end

function mod.ModifyFireRate(fireDelay, fireRate, isMult)
	local rate = mod.FireDelayToFireRate(fireDelay)
	
    return mod.FireRateToFireDelay(isMult and rate * fireRate or rate + fireRate)
end

---------------
-- << RNG >> --
---------------
function mod.RandomIntRange(minimum, maximum, seed, rng)
	rng = rng or RNG(math.max(seed or Random(), 1))
	
	return rng:RandomInt(minimum, maximum)
end

function mod.RandomFloatRange(minimum, maximum, seed, rng)
	rng = rng or RNG(math.max(seed or Random(), 1))
	
	return minimum + rng:RandomFloat() * (maximum - minimum)
end

function mod.GetRandomListValue(list, seed, rng)
	rng = rng or RNG(math.max(seed or Random(), 1))
	
	return list[rng:RandomInt(#list) + 1]
end

-----------------
-- << ISAAC >> --
-----------------
function mod.Spawn(type, variant, subtype, position, velocity, spawner, seed)
	return game:Spawn(type, variant, position, velocity or Vector.Zero, spawner, subtype, math.max(seed or Random(), 1))
end

function mod.SpawnPickup(variant, subtype, position, velocity, spawner, timeout, delay, touched)
	local pickupVel = velocity
	
	if type(velocity) == "number" then pickupVel = EntityPickup.GetRandomPickupVelocity(position) * velocity end
	local pickup = mod.Spawn(EntityType.ENTITY_PICKUP, variant, subtype, position, pickupVel, spawner):ToPickup()
	
	if timeout then pickup.Timeout = timeout end
	if delay then pickup:SetDropDelay(delay) end
	if touched then pickup.Touched = touched end
	
	return pickup
end

--------------------------
-- << PLAYER MANAGER >> --
--------------------------
function mod.AnyoneHasTemporaryEffect(itemConfig)
	for _, player in pairs(PlayerManager.GetPlayers()) do
		local effects = player:GetEffects():GetEffectsList()
		
		for effectId = 0, #effects - 1 do
			if GetPtrHash(effects:Get(effectId).Item) == GetPtrHash(itemConfig) then
				return true
			end
		end
	end
	return false
end

function mod.NearestCollectibleOwner(collectible, position)
	local nearestDistance = math.huge
	local nearestPlayer = nil
	
	for _, player in pairs(PlayerManager.GetPlayers()) do
		if player:HasCollectible(collectible) then
			local distanceSqr = position:DistanceSquared(player.Position)
			
			if distanceSqr < nearestDistance then
				nearestDistance = distanceSqr
				nearestPlayer = player
			end
		end
	end
	return nearestPlayer
end

function mod.NearestTrinketOwner(trinket, position)
	local nearestDistance = math.huge
	local nearestPlayer = nil
	
	for _, player in pairs(PlayerManager.GetPlayers()) do
		if player:GetTrinketMultiplier(trinket) > 0 then
			local distanceSqr = position:DistanceSquared(player.Position)
			
			if distanceSqr < nearestDistance then
				nearestDistance = distanceSqr
				nearestPlayer = player
			end
		end
	end
	return nearestPlayer
end

------------------
-- << ENTITY >> --
------------------
function mod.GetEntityData(entity) -- To mitigate issues with other mods
	if not entity then return end
	local entityData = entity:GetData()
	
	entityData[mod.Name] = entityData[mod.Name] or {}
	
	return entityData[mod.Name]
end

function mod.IsActiveVulnerableEnemy(entity, includeFriendly, includeDead)
	if not entity then return end
	local isFriendly = entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
	
	return entity:IsVulnerableEnemy() and entity:IsActiveEnemy(includeDead) and (includeFriendly or not isFriendly)
end

function mod.GetRandomEntity(func, seed, rng)
	rng = rng or RNG(math.max(seed or Random(), 1))
	
	local entityList = {}
	for _, entity in pairs(Isaac.GetRoomEntities()) do
		if entity and func and func(entity) then
			table.insert(entityList, entity)
		end
	end
	return mod.GetRandomListValue(entityList, seed, rng)
end

function mod.GetNearestEntity(func, position)
	local nearestDistance = math.huge
	local nearestEntity = nil
	
	for _, entity in pairs(Isaac.GetRoomEntities()) do
		if entity and func and func(entity) then
			local distanceSqr = position:DistanceSquared(entity.Position)
			
			if distanceSqr < nearestDistance then
				nearestDistance = distanceSqr
				nearestEntity = entity
			end
		end
	end
	return nearestEntity
end

function mod.GetPlayerFromEntity(entity)
	if not entity then return end
	if entity.Parent then
		local player = entity.Parent:ToPlayer()
		local fam = entity.Parent:ToFamiliar()
		
		return fam and fam.Player or player
	end
	if entity.SpawnerEntity then
		local player = entity.SpawnerEntity:ToPlayer()
		local fam = entity.SpawnerEntity:ToFamiliar()
		
		return fam and fam.Player or player
	end
	return entity:ToPlayer()
end

function mod.GetFamiliarFromEntity(entity)
	if not entity then return end
	if entity.Parent then
		return entity.Parent:ToFamiliar()
	end
	if entity.SpawnerEntity then
		return entity.SpawnerEntity:ToFamiliar()
	end
	return entity:ToFamiliar()
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

function mod.AttachTrail(entity, length, scale, color, offset)
	local effect = mod.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SPRITE_TRAIL, 0, entity.Position, nil, entity):ToEffect()
	
	effect:FollowParent(entity) -- Needs to be above parent offset otherwise it bugs out
	if scale then effect.SpriteScale = scale * Vector.One end
	if color then effect.Color = color end
	if offset then effect.ParentOffset = offset end
	if length then effect:SetRadii(length, length) end
	effect.RenderZOffset = 0 -- Allows depth interaction
	effect:Update()
	
	--[[ 
	local effectSpr = effect:GetSprite()
	
	effectSpr:GetLayer(0):GetBlendMode():SetMode(BlendType.NORMAL) -- Allows black trails
	--]]
	
	return effect
end

------------------
-- << PLAYER >> --
------------------
function mod.GetFamiliarNum(player, collectible)
	return player:GetCollectibleNum(collectible) + player:GetEffects():GetCollectibleEffectNum(collectible)
end

function mod.DropTrinket(player, trinket, position, velocity, timeout)
	player:FlushQueueItem() -- Called here to prevent bugs with golden trinkets
	
	if player:HasGoldenTrinket(trinket) then
		trinket = trinket | TrinketType.TRINKET_GOLDEN_FLAG
	end
	if player:HasTrinket(trinket) and player:TryRemoveTrinket(trinket) then
		return mod.SpawnPickup(PickupVariant.PICKUP_TRINKET, trinket, position or player.Position, velocity, player, timeout, nil, true)
	end
end

function mod.TeleportToRoom(player, roomId, dimension)
	game:GetLevel().LeaveDoor = DoorSlot.NO_DOOR_SLOT
	game:StartRoomTransition(roomId, Direction.NO_DIRECTION, RoomTransitionAnim.TELEPORT, player, dimension or Dimension.NORMAL)
end

--------------------
-- << FAMILIAR >> --
--------------------
function mod.GetModifiedFireRate(fam, fireRate, mult)
	if fam.Player:GetTrinketMultiplier(TrinketType.TRINKET_FORGOTTEN_LULLABY) > 0 then
		fireRate = fireRate * (mult or 0.5)
	end
	return fireRate
end

----------------
-- << TEAR >> --
----------------
function mod.GetBloodTearVariant(tear)
	local bloodVariant = {
		[TearVariant.BLUE] = TearVariant.BLOOD,
		[TearVariant.CUPID_BLUE] = TearVariant.CUPID_BLOOD,
		[TearVariant.NAIL] = TearVariant.NAIL_BLOOD,
		[TearVariant.PUPULA] = TearVariant.PUPULA_BLOOD,
		[TearVariant.GODS_FLESH] = TearVariant.GODS_FLESH_BLOOD,
		[TearVariant.GLAUCOMA] = TearVariant.GLAUCOMA_BLOOD,
		[TearVariant.EYE] = TearVariant.EYE_BLOOD,
		--[TearVariant.KEY] = TearVariant.KEY_BLOOD, -- Not in the vanilla function
	}
	return bloodVariant[type(tear) == "number" and tear or tear.Variant] -- You can either just put the tear entity there or get the variant from a number
end

------------------
-- << PICKUP >> --
------------------
function mod.IsDealItem(pickup)
	local dealPrice = {
		[PickupPrice.PRICE_ONE_HEART] = true,
		[PickupPrice.PRICE_TWO_HEARTS] = true,
		[PickupPrice.PRICE_THREE_SOULHEARTS] = true,
		[PickupPrice.PRICE_ONE_HEART_AND_TWO_SOULHEARTS] = true,
		[PickupPrice.PRICE_ONE_SOUL_HEART] = true,
		[PickupPrice.PRICE_TWO_SOUL_HEARTS] = true,
		[PickupPrice.PRICE_ONE_HEART_AND_ONE_SOUL_HEART] = true,
	}
	return dealPrice[type(pickup) == "number" and pickup or pickup.Price]
end

function mod.IsBlind(pickup)
	if pickup:IsBlind() or game:GetLevel():GetCurses() & LevelCurse.CURSE_OF_BLIND > 0 
	or pickup:GetSprite():GetLayer(1):GetSpritesheetPath():lower():find("questionmark") 
	then
		return true
	end
	return false
end

----------------
-- << ROOM >> --
----------------
function mod.GetRandomDoor(room, blacklist, seed, rng)
    rng = rng or RNG(math.max(seed or Random(), 1))
	
	local doorBlacklist = {}
	local doorList = {}
	
	if blacklist then
        for _, slot in ipairs(blacklist) do
            doorBlacklist[slot] = true
        end
    end
	for slot = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
		local door = room:GetDoor(slot)
		
		if door and not doorBlacklist[slot] and room:IsDoorSlotAllowed(slot) then
			table.insert(doorList, door)
		end
	end
	return mod.GetRandomListValue(doorList, seed, rng)
end

function mod.HasDoorOfType(room, roomTypes)
    local roomTable = type(roomTypes) == "table" and roomTypes or {roomTypes}

    for slot = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
        local door = room:GetDoor(slot)
        if door then
            for _, roomType in ipairs(roomTable) do
                if door:IsRoomType(roomType) then
                    return true
                end
            end
        end
    end
    return false
end

function mod.IsSecretRoom(room, includeUltraSecret)
	local secretTypes = {
		[RoomType.ROOM_SECRET] = true,
		[RoomType.ROOM_SUPERSECRET] = true,
		[RoomType.ROOM_ULTRASECRET] = includeUltraSecret,
	}
	return secretTypes[room:GetType()]
end

-----------------
-- << LEVEL >> --
-----------------
function mod.RevealLastBossRoom(level) -- Should be similar to the Sol item
	local roomDesc = level:GetRooms():Get(level:GetLastBossRoomListIndex())
	
	roomDesc.DisplayFlags = roomDesc.DisplayFlags | 4 -- Reveals the icon only
	level:UpdateVisibility()
end

function mod.ShowRoomType(level, roomTypes, flag)
    local rooms = level:GetRooms()
	local roomTable = type(roomTypes) == "table" and roomTypes or {roomTypes}

    for roomId = 0, rooms.Size - 1 do
        local roomDesc = rooms:Get(roomId)
        local roomData = roomDesc.Data

        for _, roomType in ipairs(roomTable) do
            if roomData.Type == roomType then
                roomDesc.DisplayFlags = roomDesc.DisplayFlags | (flag or 1 | 4)
                break
            end
        end
    end
    level:UpdateVisibility()
end

function mod.IsStartingRoom(level)
	return level:GetCurrentRoomIndex() == level:GetStartingRoomIndex()
end

-----------------------
-- << ITEM CONFIG >> --
-----------------------
function mod.GetMaxCollectibleId()
	return #Isaac.GetItemConfig():GetCollectibles() - 1
end

function mod.GetRandomTaggedItem(tags, seed, rng)
	rng = rng or RNG(math.max(seed or Random(), 1))
	
	local configItemList = {}
	for _, configItem in pairs(Isaac.GetItemConfig():GetTaggedItems(tags)) do
		table.insert(configItemList, configItem)
	end
	return mod.GetRandomListValue(configItemList, seed, rng)
end

-----------------------
-- << ROOM CONFIG >> --
-----------------------
function mod.GetRandomRoomFromOptionalStage(seed, reduceWeight, stage1, stage2, roomType, roomShape, minVariant, maxVariant, minDifficulty, maxDifficulty, doors, roomSubType, mode) -- Use this until it actually exists in Repentogon
	local roomConfig = RoomConfigHolder.GetRandomRoom(seed, reduceWeight, stage1, roomType, roomShape, minVariant, maxVariant, minDifficulty, maxDifficulty, doors, roomSubType, mode)
	
	if not roomConfig then
		roomConfig = RoomConfigHolder.GetRandomRoom(seed, reduceWeight, stage2, roomType, roomShape, minVariant, maxVariant, minDifficulty, maxDifficulty, doors, roomSubType, mode)
	end
	return roomConfig
end

----------------------------
-- << TEMPORARY EFFECT >> --
----------------------------
function mod.SetCollectibleEffect(effects, collectible, count, cooldown, addCostume)
	effects:AddCollectibleEffect(collectible, addCostume)
	
	local effect = effects:GetCollectibleEffect(collectible)
	if effect then
		effect.Count = count or 1
		effect.Cooldown = cooldown or effect.Item.MaxCooldown
	end
end

function mod.SetTrinketEffect(effects, trinket, count, cooldown, addCostume)
	effects:AddTrinketEffect(trinket, addCostume)
	
	local effect = effects:GetTrinketEffect(trinket)
	if effect then
		effect.Count = count or 1
		effect.Cooldown = cooldown or effect.Item.MaxCooldown
	end
end

function mod.SetNullEffect(effects, nullItem, count, cooldown, addCostume)
	effects:AddNullEffect(nullItem, addCostume)
	
	local effect = effects:GetNullEffect(nullItem)
	if effect then
		effect.Count = count or 1
		effect.Cooldown = cooldown or effect.Item.MaxCooldown
	end
end

----------------
-- << GAME >> --
----------------
function mod.Fart(position, radius, source, scale, subtype, color, func)
	local hasGiganteBean = PlayerManager.AnyoneHasTrinket(TrinketType.TRINKET_GIGANTE_BEAN)
	
	radius = (radius or 85) * (hasGiganteBean and 2 or 1)
	scale = (scale or 1) * (hasGiganteBean and 2 or 1)
	
	local effect = mod.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FART, subtype or 0, position):ToEffect()
	
	effect.SpriteScale = Vector.One * scale
	effect.Color = color or Color.Default
	
	if scale > 1.8 then
		sfx:Stop(SoundEffect.SOUND_FART)
		sfx:Play(SoundEffect.SOUND_FART, 1, 0, false, 1)
		sfx:Play(SoundEffect.SOUND_FART, 1.2, 20, false, 0.5)
		game:ShakeScreen(3)
	end
	if source and source:ToPlayer() then
		local moveVec = source:GetMovementVector()
		local hasBirdsEye = source:HasCollectible(CollectibleType.COLLECTIBLE_BIRDS_EYE)
		local hasGhostPepper = source:HasCollectible(CollectibleType.COLLECTIBLE_GHOST_PEPPER)
		
		moveVec = moveVec:Length() == 0 and Vector(0, -1) or -moveVec
		
		if hasBirdsEye and (not hasGhostPepper or Random() % 2 == 0) then
			source:ShootRedCandle(moveVec)
		elseif hasGhostPepper then
			source:ShootBlueCandle(moveVec)
		end
	end
	for _, entity in pairs(Isaac.FindInRadius(position, radius, EntityPartition.ENEMY)) do
		if mod.IsActiveVulnerableEnemy(entity) and func then func(entity) end
	end
end

function mod.AreaDamage(func, position, radius, amount, flags, source, countdown, extraGore)
	local entityDamaged = false
	
	for _, entity in pairs(Isaac.GetRoomEntities()) do
		if entity and func and func(entity) then
			if entity.Position:Distance(position) <= entity.Size + radius then
				if entity:TakeDamage(amount, flags or 0, source or EntityRef(nil), countdown or 0) then
					if extraGore then entity:AddEntityFlags(EntityFlag.FLAG_EXTRA_GORE) end
					entityDamaged = true
				end
			end
		end
	end
	return entityDamaged
end

function mod.SpawnMomsHand(amount, duration, seed, rng)
	rng = rng or RNG(math.max(seed or Random(), 1))
	duration = duration or 150
	
	local entityList = {}
	for _, entity in pairs(Isaac.GetRoomEntities()) do
		if entity and mod.IsActiveVulnerableEnemy(entity) then
			table.insert(entityList, entity)
		end
	end
	for effectId = 1, math.min(amount or 1, #entityList) do
		local enemy = table.remove(entityList, rng:RandomInt(#entityList) + 1)
		
		if enemy then
			local effectPos = enemy.Position + Vector(0, 5)
			local effect = mod.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.MOMS_HAND, 0, effectPos):ToEffect()
			
			effect.Target = enemy
			effect:SetTimeout(duration)
			effect:Update()
			enemy:SetPauseTime(duration)
		end
	end
end

-----------------
-- << OTHER >> --
-----------------
function mod.IsSpikeDamage(flag, source) -- Based on Flat File and more!
	local spikyEnemies = {
		[EntityType.ENTITY_POKY] = true,
		[EntityType.ENTITY_WALL_HUGGER] = true,
		[EntityType.ENTITY_GRUDGE] = true,
		[EntityType.ENTITY_SPIKEBALL] = true,
		[EntityType.ENTITY_BALL_AND_CHAIN] = true,
	}
	if source and (spikyEnemies[source.Type] 
	or (source.Type == EntityType.ENTITY_SINGE and source.Variant == 1) 
	or (source.Type == EntityType.ENTITY_NULL and source.Variant == GridEntityType.GRID_ROCK_SPIKED)) 
	or flag & (DamageFlag.DAMAGE_CURSED_DOOR | DamageFlag.DAMAGE_SPIKES | DamageFlag.DAMAGE_CHEST) > 0 
	then
		return true
	end
	return false
end