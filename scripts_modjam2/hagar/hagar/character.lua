local mod = HAGAR_MOD

local character = mod.Enums.Character.HAGAR
local characterStat = mod.Enums.CharacterStats
local PULSE_COLOR = Color(1, 1, 1, 1, 0.6, 0.3, 1)
local VENGEFUL_MONSTER_COLOR = Color()
VENGEFUL_MONSTER_COLOR:SetColorize(2, 0.8, 2, 1)

-- Increased damage taken
---@param entity Entity
---@param amount number
---@param flags integer
---@param source EntityRef
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (_, entity, amount, flags, source)
    local player = entity:ToPlayer()
    if not player then return end
    if player:GetPlayerType() ~= character then return end

    local sourceEnt = source.Entity
    if not sourceEnt then return end
    local sourceEntSpawner = sourceEnt.SpawnerEntity

    if sourceEnt:ToNPC() or sourceEnt:ToProjectile() or (sourceEntSpawner and sourceEntSpawner:ToNPC()) then
        local dmgMult = player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_WAFER) and 1 or 2
        return {Damage = amount * dmgMult}
    end
end, EntityType.ENTITY_PLAYER)

-- Increased monster HP
---@param npc EntityNPC
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, function (_, npc)
    if mod.Lib.GetMonsterHealthMultiplier() <= 1 then return end
    if not PlayerManager.AnyoneIsPlayerType(character) then return end
    if not npc:IsActiveEnemy() then return end
    if mod.Enums.Blacklists.MonsterHPUp:IsBlacklisted(npc) then return end

    npc.MaxHitPoints = mod.Lib.ScaleUpMonsterHealth(npc.MaxHitPoints, npc:IsBoss())
    npc.HitPoints = npc.MaxHitPoints
    npc:SetColor(PULSE_COLOR, 45, 1, true, false)
end)

-- Some additional effects relating to powered up monsters

-- Check if any character is Hagar and El Roi is active or not
---@return boolean?
local function ElRoiEffectActive()
    if not PlayerManager.AnyoneIsPlayerType(character) then return true end --Added true to return, since otherwise the purple would apply to other characters.
    local anyoneHasElRoiEffect = false
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        local fx = player:GetEffects()
        if fx:GetCollectibleEffectNum(mod.Enums.Collectibles.EL_ROI) > 0 then
            anyoneHasElRoiEffect = true
            break
        end
    end
    return anyoneHasElRoiEffect
end

mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function (_, proj)
    if proj.FrameCount > 1 then return end
    local spawner = proj.SpawnerEntity
    if not spawner then return end
    if not spawner:ToNPC() then return end

    local anyoneHasElRoiEffect = ElRoiEffectActive()
    if anyoneHasElRoiEffect then return end
    proj.Color = Color.Lerp(proj.Color, VENGEFUL_MONSTER_COLOR, 0.8)
end)

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function (_, effect)
    local anyoneHasElRoiEffect = ElRoiEffectActive()
    if anyoneHasElRoiEffect then return end
    effect.Color = Color.Lerp(effect.Color, VENGEFUL_MONSTER_COLOR, 0.8)
end, EffectVariant.SPAWN_PENTAGRAM)

-- Heart force collision (hell)
-- A lot of this is based on code for Fiend Folio's Extra Vessel/Heart of China items. Credit goes to them
---@param pickup EntityPickup
---@param collider Entity
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, function (_, pickup, collider)
    local player = collider:ToPlayer()
    if not player then return end
    if player:GetPlayerType() ~= character then return end
    if not mod.Enums.CharacterStats.HEART_OVERHEAL[pickup.SubType] then return end

    local fx = player:GetEffects()
    local cap = mod.Lib.GetHagarRedHeartCap(player)
    local heartCounterNum = fx:GetNullEffectNum(mod.Enums.NullItems.HAGAR_HEART_COUNTER)
    if heartCounterNum >= cap then return end

    if not player:IsExtraAnimationFinished() then return end
    if pickup.FrameCount <= pickup:GetDropDelay() then return end
    local sprite = pickup:GetSprite()
    if sprite:IsPlaying("Collect") or pickup.Touched then return end

    local heartCollected = false
    if pickup:IsShopItem() then
        if pickup.Price == PickupPrice.PRICE_FREE or (pickup.Price > 0 and player:GetNumCoins() >= pickup.Price) then
            local heldSprite = Sprite(sprite:GetFilename(), true)
            heldSprite:SetFrame(sprite:GetAnimation(), sprite:GetFrame())
            player:AnimatePickup(heldSprite)
            if pickup.Price ~= PickupPrice.PRICE_FREE then
                player:AddCoins(-1 * pickup.Price)
            end
            -- todo: handle Restock. bruh.
            pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			pickup:Remove()
            heartCollected = true
        end
    else
        sprite:Play("Collect", true)
        pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        pickup:Die()
        heartCollected = true
    end

    if heartCollected then
        local toAdd = mod.Enums.CharacterStats.HEART_OVERHEAL[pickup.SubType]
        if player:HasCollectible(CollectibleType.COLLECTIBLE_CANDY_HEART) then
            for i = 1, toAdd do
                player:AddCandyHeartBonus()
            end
        end
        if player:HasCollectible(CollectibleType.COLLECTIBLE_MAGGYS_BOW) then
            toAdd = toAdd * 2
        end
        fx:AddNullEffect(mod.Enums.NullItems.HAGAR_HEART_COUNTER, true, toAdd)
        if heartCounterNum + toAdd > cap then
            fx:RemoveNullEffect(mod.Enums.NullItems.HAGAR_HEART_COUNTER, fx:GetNullEffectNum(mod.Enums.NullItems.HAGAR_HEART_COUNTER) - cap)
        end
        pickup:TriggerTheresOptionsPickup()
        mod.SFX:Play(SoundEffect.SOUND_BOSS2_BUBBLES)

        mod.Game:GetLevel():SetHeartPicked()
        mod.Game:ClearStagesWithoutHeartsPicked()
        mod.Game:SetStateFlag(GameStateFlag.STATE_HEART_BOMB_COIN_PICKED, true)
        return true
    end
end, PickupVariant.PICKUP_HEART)

-- More soul heart drops over red hearts
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_SELECTION, function (_, pickup, variant, sub, rvariant, rsub, rng)
    local isPickupReplaceable = variant == PickupVariant.PICKUP_HEART and (sub == HeartSubType.HEART_FULL or sub == HeartSubType.HEART_HALF)
    local isRequestedPickupReplaceable = rvariant == 0 or (rvariant == PickupVariant.PICKUP_HEART and rsub == 0)
    if not isPickupReplaceable or not isRequestedPickupReplaceable then return end
    if not PlayerManager.AnyoneIsPlayerType(character) then return end

    if rng:RandomFloat() < characterStat.MORE_SOUL_HEART_CHANCE then
        local newSub
        if sub == HeartSubType.HEART_FULL then
            newSub = HeartSubType.HEART_SOUL
        elseif sub == HeartSubType.HEART_HALF then
            if not Isaac.GetPersistentGameData():Unlocked(Achievement.EVERYTHING_IS_TERRIBLE) then return end
            newSub = HeartSubType.HEART_HALF_SOUL
        end
        return {PickupVariant.PICKUP_HEART, newSub}
    end
end)

-- There's Options effect (as long as El Roi hasn't been used)
local optionsConfig = Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
    local room = mod.Game:GetRoom()
    local roomType = room:GetType()
    if roomType == RoomType.ROOM_BOSS or roomType == RoomType.ROOM_BOSSRUSH then
        for _, player in ipairs(PlayerManager.GetPlayers()) do
            if player:GetPlayerType() == character then
                player:AddInnateCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS)
                if not player:HasCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS, false, true) then
                    player:RemoveCostume(optionsConfig)
                end
            end
        end
    else
        for _, player in ipairs(PlayerManager.GetPlayers()) do
            if player:GetPlayerType() == character then
                local innateOptionsCount = player:GetCollectibleNum(CollectibleType.COLLECTIBLE_THERES_OPTIONS) - player:GetCollectibleNum(CollectibleType.COLLECTIBLE_THERES_OPTIONS, true, true)
                if innateOptionsCount > 0 then
                    player:AddInnateCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS, -1)
                end
            end
        end
    end
end)

-- Stat modifiers
-- (Starts with 3.5 damage but also has a 1.5x damage multiplier)
---@param player EntityPlayer
---@param cacheFlag CacheFlag
mod:AddPriorityCallback(ModCallbacks.MC_EVALUATE_CACHE, CallbackPriority.LATE, function (_, player, cacheFlag)
    if player:GetPlayerType() ~= character then return end
    player.Damage = player.Damage * characterStat.DMG_MULTIPLIER
end, CacheFlag.CACHE_DAMAGE)

-- Heart HUD
local heartSprite = Sprite("gfx/ui/hudpickups.anm2", true)
heartSprite:SetFrame("Idle", 15)
mod:AddCallback(ModCallbacks.MC_HUD_RENDER, function ()
    if RoomTransition.IsRenderingBossIntro() then return end
    if not PlayerManager.AnyoneIsPlayerType(character) then return end
    local player = PlayerManager.FirstPlayerByType(character)
    if not player then return end

    local renderPos = Vector(Options.HUDOffset * 20, Options.HUDOffset * 12)
    local offsetHeart, offsetText = Vector(30, 34), Vector(46, 34)
    local renderPosHeart, renderPosText = renderPos + offsetHeart, renderPos + offsetText
    heartSprite:Render(renderPosHeart)
    local fx = player:GetEffects()
    local hudString = string.format("%d / %d", fx:GetNullEffectNum(mod.Enums.NullItems.HAGAR_HEART_COUNTER), mod.Lib.GetHagarRedHeartCap(player))
    mod.Font:DrawString(hudString, renderPosText.X, renderPosText.Y, KColor(1, 1, 1, 1))
end)

-- debug
local debug = false
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function (_, player)
    if not debug then return end

    if player:GetPlayerType() ~= character then return end
    local fx = player:GetEffects()
    local debugString = string.format("%d / %d", fx:GetNullEffectNum(mod.Enums.NullItems.HAGAR_HEART_COUNTER), mod.Lib.GetHagarRedHeartCap(player))
    local pos = Isaac.WorldToScreen(player.Position - Vector(0, 80))
    Isaac.RenderText(debugString, pos.X, pos.Y, 1, 0.2, 0.2, 1)
end)