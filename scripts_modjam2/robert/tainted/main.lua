local t = {}
local GAME = Game()
local SFX = SFXManager()

---@param player EntityPlayer
---@param id CollectibleType
---@param force? boolean
function t:SetPocket(player, id, force)
    if not force and player:GetActiveItem(ActiveSlot.SLOT_POCKET) == ROBERT_MOD.CollectibleType.CLOCKED_OUT then return end
    player:SetPocketActiveItem(CollectibleType.COLLECTIBLE_NULL)
    player:SetPocketActiveItem(id)
end

t.Clear = true

---@param player EntityPlayer
ROBERT_MOD:AddCallback(ModCallbacks.MC_PLAYER_INIT_POST_LEVEL_INIT_STATS, function (_, player)
    t.Clear = true
    t:SetPocket(player, ROBERT_MOD.CollectibleType.CLOCK_OUT)
end, ROBERT_MOD.PlayerType.ROBERT_B)

function t:EvaluateIsRoomCleared()
    if not PlayerManager.AnyoneIsPlayerType(ROBERT_MOD.PlayerType.ROBERT_B) then return end

    local room = GAME:GetRoom()
    local clear = room:IsClear() and not room:IsAmbushActive()

    if clear and not t.Clear then
        for _, player in ipairs(PlayerManager.GetPlayers()) do
            if player:GetPlayerType() == ROBERT_MOD.PlayerType.ROBERT_B then
                t:SetPocket(player, ROBERT_MOD.CollectibleType.CLOCK_OUT)
            end
        end
    elseif not clear and t.Clear then
        for _, player in ipairs(PlayerManager.GetPlayers()) do
            if player:GetPlayerType() == ROBERT_MOD.PlayerType.ROBERT_B then
                t:SetPocket(player, ROBERT_MOD.CollectibleType.CLOCK_IN)
            end
        end
    end

    t.Clear = clear
end

ROBERT_MOD:AddCallback(ModCallbacks.MC_POST_UPDATE, function ()
    t:EvaluateIsRoomCleared()

    if GAME:GetRoom():GetType() == RoomType.ROOM_BOSS then
        t:ClearDeadlineAnxiety()
        for _, v in ipairs(PlayerManager.GetPlayers()) do
            if v:GetPlayerType() == ROBERT_MOD.PlayerType.ROBERT_B then
                t:SetPocket(v, ROBERT_MOD.CollectibleType.CLOCKED_OUT)
            end
        end
    end

    if not t.Clear then
        local player = ROBERT_MOD:GetFirstRobert()
        if player:GetPlayerType() ~= ROBERT_MOD.PlayerType.ROBERT_B then return end
        local fx = player:GetEffects()
        if fx:GetNullEffectNum(ROBERT_MOD.NullItemID.DEADLINE_TRACKER) > 0 then
            fx:RemoveNullEffect(ROBERT_MOD.NullItemID.DEADLINE_TRACKER, 2)
            local num = fx:GetNullEffectNum(ROBERT_MOD.NullItemID.DEADLINE_TRACKER)

            if num // 2 % (num < 60 * 3 and 5 or 30) == 0 then
                SFX:Play(SoundEffect.SOUND_TOOTH_AND_NAIL_TICK, 0.5, nil, nil, 1.5)
            end

            if num // 2 % 30 == 0 then
                for _, v in ipairs(PlayerManager.GetPlayers()) do
                    if v:GetPlayerType() == ROBERT_MOD.PlayerType.ROBERT_B
                    and v:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
                        local vfxnottobeconfusedwithvisualeffects = v:GetEffects()
                        vfxnottobeconfusedwithvisualeffects:RemoveNullEffect(ROBERT_MOD.NullItemID.DEADLINE_ANXIETY, -1)
                        vfxnottobeconfusedwithvisualeffects:AddNullEffect(ROBERT_MOD.NullItemID.DEADLINE_ANXIETY, nil, math.max(0, 11 - math.ceil(num / 60)))
                    end
                end
            end

            if num <= 0 then
                SFX:Play(SoundEffect.SOUND_WAR_BOMB_TICK)
                ROBERT_MOD.PostponeUntilUpdate(
                function ()
                    local bossIndex = GAME:GetLevel():QueryRoomTypeIndex(RoomType.ROOM_BOSS, false, RNG())
                    GAME:StartRoomTransition(bossIndex, Direction.NO_DIRECTION, RoomTransitionAnim.TELEPORT, Isaac.GetPlayer())
                end)
                for _, v in ipairs(PlayerManager.GetPlayers()) do
                    if v:GetPlayerType() == ROBERT_MOD.PlayerType.ROBERT_B then
                        t:SetPocket(v, ROBERT_MOD.CollectibleType.CLOCKED_OUT)
                    end
                end
            end
        end
    end
end)
ROBERT_MOD:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, t.EvaluateIsRoomCleared)

function t:ClearDeadlineAnxiety()
    for _, v in ipairs(PlayerManager.GetPlayers()) do
        v:GetEffects():RemoveNullEffect(ROBERT_MOD.NullItemID.DEADLINE_ANXIETY, -1)
    end
end

---@param player EntityPlayer
ROBERT_MOD:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, _, player)
    local fx = player:GetEffects()
    fx:RemoveNullEffect(ROBERT_MOD.NullItemID.DEADLINE_TRACKER, -1)
    fx:AddNullEffect(ROBERT_MOD.NullItemID.DEADLINE_TRACKER, nil, fx:GetNullEffectNum(ROBERT_MOD.NullItemID.MAX_DEADLINE) - 1)
    t:ClearDeadlineAnxiety()
end, ROBERT_MOD.CollectibleType.CLOCK_IN)

-- ---@param player EntityPlayer
-- ROBERT_MOD:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, _, player)
--     SFX:Play(SoundEffect.SOUND_THUMBS_DOWN)
--     return true
-- end, ROBERT_MOD.CollectibleType.CLOCKED_OUT)

---@param player EntityPlayer
ROBERT_MOD:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, _, player)
    -- if player:GetEffects():HasCollectibleEffect(ROBERT_MOD.CollectibleType.CLOCK_OUT) then return end
    player:GetEffects():RemoveNullEffect(ROBERT_MOD.NullItemID.DEADLINE_TRACKER, -1)
    local bossIndex = GAME:GetLevel():QueryRoomTypeIndex(RoomType.ROOM_BOSS, false, RNG())
    GAME:StartRoomTransition(bossIndex, Direction.NO_DIRECTION, RoomTransitionAnim.TELEPORT, Isaac.GetPlayer())

    t:SetPocket(player, ROBERT_MOD.CollectibleType.CLOCKED_OUT)
    SFX:Play(SoundEffect.SOUND_PAPER_OUT)
    t:ClearDeadlineAnxiety()
end, ROBERT_MOD.CollectibleType.CLOCK_OUT)

---@param player EntityPlayer
ROBERT_MOD:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, _, player)
    SFX:Play(SoundEffect.SOUND_PAPER_IN)
    return true
end, ROBERT_MOD.CollectibleType.CLOCK_IN)

ROBERT_MOD:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function ()
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        local fx = player:GetEffects()
        fx:RemoveCollectibleEffect(ROBERT_MOD.CollectibleType.CLOCK_IN, -1)
        fx:RemoveCollectibleEffect(ROBERT_MOD.CollectibleType.CLOCK_OUT, -1)
        if player:GetPlayerType() == ROBERT_MOD.PlayerType.ROBERT_B then
            t:SetPocket(player, ROBERT_MOD.CollectibleType.CLOCK_OUT, true)
        end
    end
end)

---@param entity Entity
---@param amt number
---@param flags DamageFlag
ROBERT_MOD:AddPriorityCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CallbackPriority.LATE, function (_, entity, amt, flags)
    if amt <= 0 or flags & DamageFlag.DAMAGE_NO_PENALTIES ~= 0 then return end

    local player = entity:ToPlayer()
    local fx = player:GetEffects()

    return {
        Damage = amt + fx:GetCollectibleEffectNum(ROBERT_MOD.CollectibleType.CLOCK_IN)
    }
end, EntityType.ENTITY_PLAYER)

---@param player EntityPlayer 
ROBERT_MOD:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (_, player)
    local fx = player:GetEffects()
    local num = fx:GetCollectibleEffectNum(ROBERT_MOD.CollectibleType.CLOCK_IN)

    if player.FrameCount % 20 == 0
    and player:GetPlayerType() == ROBERT_MOD.PlayerType.ROBERT_B
    and player.Velocity:Length() > 0.1 then
        local rng = player:GetDropRNG()

        if rng:RandomFloat() < 0.05 then
            local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ANGEL, 0, player.Position, Vector.Zero, nil)
            local sprite = effect:GetSprite()
            sprite.FlipX = rng:RandomFloat() < 0.5
            effect.SpriteOffset = Vector(0, -10)
            sprite:Load("gfx/effect_robert_papers.anm2", true)
            sprite:Play("Idle", true)
            sprite:SetFrame(rng:RandomInt(1, sprite:GetCurrentAnimationData():GetLength()))
            sprite:Stop()
            effect:AddEntityFlags(EntityFlag.FLAG_RENDER_FLOOR)
            effect:Update()
        end
    end

    if num == 0 then return end

    if player.FrameCount % math.max(10, 60 - (num - 1) * 20) == 0 then
        local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TEAR_POOF_A, 10, player.Position, Vector.Zero, nil):ToEffect()
        effect.Rotation = 0
        effect.SpriteOffset = Vector(0, player.SpriteScale.Y * -20) + player:GetFlyingOffset()
        effect.DepthOffset = -20
        effect:FollowParent(player)
        effect.SpriteScale = player.SpriteScale
        effect.FlipX = math.random() > 0.5
    end
end)