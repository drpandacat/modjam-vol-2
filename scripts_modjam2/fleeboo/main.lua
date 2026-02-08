local Mod = RegisterMod("fleeboh", 1)

--#region Fleeboh

Mod.Fleeboh = {
    ID = Isaac.GetPlayerTypeByName("Fleeboh"),
    DAMAGE = 5, 
    SPEED = 2,
    SHOTSPEED = -3,
    TEARHEIGHT = 0,
    TEARFALLINGSPEED = 0,
    LUCK = 3,
    FLYING = false,                                  
    TEARFLAG = 0,
    TEARCOLOR = Color(0.0, 1.0, 0.0, 1.0, 0, 0, 0)
}

function Mod.Fleeboh:onCache(player, cacheFlag) 
    if player:GetPlayerType() == Mod.Fleeboh.ID then 
        if cacheFlag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage + Mod.Fleeboh.DAMAGE
        end
        if cacheFlag == CacheFlag.CACHE_SHOTSPEED then
            player.ShotSpeed = player.ShotSpeed + Mod.Fleeboh.SHOTSPEED
        end
        if cacheFlag == CacheFlag.CACHE_RANGE then
            player.TearHeight = player.TearHeight - Mod.Fleeboh.TEARHEIGHT
            player.TearFallingSpeed = player.TearFallingSpeed + Mod.Fleeboh.TEARFALLINGSPEED
        end
        if cacheFlag == CacheFlag.CACHE_SPEED then
            player.MoveSpeed = player.MoveSpeed + Mod.Fleeboh.SPEED
        end
        if cacheFlag == CacheFlag.CACHE_LUCK then
            player.Luck = player.Luck + Mod.Fleeboh.LUCK
        end
        if cacheFlag == CacheFlag.CACHE_FLYING and Mod.Fleeboh.FLYING then
            player.CanFly = true
        end
        if cacheFlag == CacheFlag.CACHE_TEARFLAG then
            player.TearFlags = player.TearFlags | Mod.Fleeboh.TEARFLAG
        end
        if cacheFlag == CacheFlag.CACHE_TEARCOLOR then
            player.TearColor = Mod.Fleeboh.TEARCOLOR
        end
    end
end
 
Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, Mod.Fleeboh.onCache)
--#endregion

--#region Tainted Fleeboh

Mod.TaintedFleeboh = {
    ID = Isaac.GetPlayerTypeByName("Fleebee", true),
    DAMAGE = 4, 
    SPEED = 2,
    SHOTSPEED = -3,
    TEARHEIGHT = 0,
    TEARFALLINGSPEED = 0,
    LUCK = 3,
    FLYING = false,                                  
    TEARFLAG = 0,
    TEARCOLOR = Color(0.0, 0.5, 0.0, 1.0, 0, 0, 0),
    TELEPORT_CHANCE = 0.5
}
Mod.TaintedFleeboh.COLOR_BLACK = Color(0, 0, 0)
Mod.TaintedFleeboh.COLOR_WHITE = Color(0, 0, 0, 1, 1, 1, 1)
Mod.TaintedFleeboh.FRAME_TO_COLOR = {
    Mod.TaintedFleeboh.COLOR_BLACK,
    Mod.TaintedFleeboh.COLOR_BLACK,
    Mod.TaintedFleeboh.COLOR_WHITE,
    Mod.TaintedFleeboh.COLOR_BLACK,
    Mod.TaintedFleeboh.COLOR_WHITE,
    Mod.TaintedFleeboh.COLOR_BLACK,
    Mod.TaintedFleeboh.COLOR_WHITE,
    Mod.TaintedFleeboh.COLOR_WHITE,
    Mod.TaintedFleeboh.COLOR_BLACK,
    Mod.TaintedFleeboh.COLOR_WHITE,
    Mod.TaintedFleeboh.COLOR_BLACK,
    Mod.TaintedFleeboh.COLOR_WHITE,
    Mod.TaintedFleeboh.COLOR_BLACK,
}
Mod.TaintedFleeboh.FRAME_TO_SCALE = {
    Vector(1, 1),
    Vector(0.85, 1.25),
    Vector(0.7, 1.5),
    Vector(1, 1),
    Vector(1.7, 0.6),
    Vector(0.5, 2),
    Vector(0.25, 4),
    Vector(0.25, 4),
    Vector(0.5, 2),
    Vector(1.7, 0.6),
    Vector(1, 1),
    Vector(0.7, 1.5),
    Vector(0.85, 1.25)
}
Mod.TaintedFleeboh.FRAME_TO_OFFSET = {
    Vector(0, 0),
    Vector(0, -1),
    Vector(0, 0),
    Vector(0, -1),
    Vector(0, -2),
    Vector(0, -16),
    Vector(0, -86),
    Vector(0, -86),
    Vector(0, -16),
    Vector(0, -2),
    Vector(0, -1),
    Vector(0, 0),
    Vector(0, -1),
}
Mod.TaintedFleeboh.NUM_RELOCATE_TRIES = 100
Mod.TaintedFleeboh.TP_FRAME = 7
Mod.TaintedFleeboh.MIN_DIST = 40 * 3
Mod.TaintedFleeboh.JUMP_INTERVAL = 30 -- 30 = 1 second, 60 = 2 seconds, 15 = 0.5 seconds
Mod.TaintedFleeboh.JUMP_CHANCE = 0.1 -- 1 = 100%, 0 = 0%, 0.5 = 50%

---@param entity Entity
function Mod.TaintedFleeboh:GetTeleportData(entity)
    local data = entity:GetData()
    data.FLEEBOO_TELEPORT = data.FLEEBOO_TELEPORT or {}
    ---@class TeleportData
    ---@field Frame integer
    return data.FLEEBOO_TELEPORT
end

function Mod.TaintedFleeboh:onCache(player, cacheFlag) 
    if player:GetPlayerType() == Mod.TaintedFleeboh.ID then 
        if cacheFlag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage + Mod.TaintedFleeboh.DAMAGE
        end
        if cacheFlag == CacheFlag.CACHE_SHOTSPEED then
            player.ShotSpeed = player.ShotSpeed + Mod.TaintedFleeboh.SHOTSPEED
        end
        if cacheFlag == CacheFlag.CACHE_RANGE then
            player.TearHeight = player.TearHeight - Mod.Fleeboh.TEARHEIGHT
            player.TearFallingSpeed = player.TearFallingSpeed + Mod.TaintedFleeboh.TEARFALLINGSPEED
        end
        if cacheFlag == CacheFlag.CACHE_SPEED then
            player.MoveSpeed = player.MoveSpeed + Mod.TaintedFleeboh.SPEED
        end
        if cacheFlag == CacheFlag.CACHE_LUCK then
            player.Luck = player.Luck + Mod.TaintedFleeboh.LUCK
        end
        if cacheFlag == CacheFlag.CACHE_FLYING and Mod.TaintedFleeboh.FLYING then
            player.CanFly = true
        end
        if cacheFlag == CacheFlag.CACHE_TEARFLAG then
            player.TearFlags = player.TearFlags | Mod.TaintedFleeboh.TEARFLAG
        end
        if cacheFlag == CacheFlag.CACHE_TEARCOLOR then
            player.TearColor = Mod.TaintedFleeboh.TEARCOLOR
        end
    end
end
 
Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, Mod.TaintedFleeboh.onCache)

---@param entity Entity
function Mod.TaintedFleeboh:PostEntityTakeDmg(entity)
    if entity.FrameCount <= 1
    or entity.Type == EntityType.ENTITY_PLAYER
    or entity:HasMortalDamage() then return end

    local num = 0

    for _, player in ipairs(PlayerManager.GetPlayers()) do
        if player:GetPlayerType() == Mod.TaintedFleeboh.ID then
            num = num + 1
        end
    end

    if num == 0 then return end

    local rolled
    local rng = entity:GetDropRNG()

    for _ = 1, num do
        rolled = rng:RandomFloat() < Mod.TaintedFleeboh.TELEPORT_CHANCE
        if rolled then break end
    end

    if not rolled then return end

    local data = Mod.TaintedFleeboh:GetTeleportData(entity)
    data.Frame = entity.FrameCount
    SFXManager():Play(SoundEffect.SOUND_HELL_PORTAL2)
end
Mod:AddCallback(ModCallbacks.MC_POST_ENTITY_TAKE_DMG, Mod.TaintedFleeboh.PostEntityTakeDmg)

---@param npc EntityNPC
function Mod.TaintedFleeboh:PreNPCRender(npc)
    local data = Mod.TaintedFleeboh:GetTeleportData(npc)
    if not data.Frame then return end

    local frame = npc.FrameCount - data.Frame + 1

    if Mod.TaintedFleeboh.FRAME_TO_COLOR[frame] and Mod.TaintedFleeboh.FRAME_TO_SCALE[frame] and Mod.TaintedFleeboh.FRAME_TO_OFFSET[frame] then
        local sprite = npc:GetSprite()
        sprite.Scale = Mod.TaintedFleeboh.FRAME_TO_SCALE[frame]
        sprite.Color = Mod.TaintedFleeboh.FRAME_TO_COLOR[frame]
        sprite.Offset = Mod.TaintedFleeboh.FRAME_TO_OFFSET[frame]
        sprite:Render(Isaac.WorldToScreen(npc.Position))
        sprite.PlaybackSpeed = 0
        return true
    else
        local sprite = npc:GetSprite()
        sprite.Color = Color.Default
        sprite.Scale = Vector.One
        sprite.Offset = Vector.Zero
        sprite.PlaybackSpeed = 1
        data.Frame = nil
    end
end
Mod:AddPriorityCallback(ModCallbacks.MC_PRE_NPC_RENDER, CallbackPriority.LATE, Mod.TaintedFleeboh.PreNPCRender)

---@param npc EntityNPC
function Mod.TaintedFleeboh:PostNPCUpdate(npc)
    local data = Mod.TaintedFleeboh:GetTeleportData(npc)

    if data.Frame then
        npc.Velocity = Vector.Zero
        if npc.FrameCount - data.Frame == Mod.TaintedFleeboh.TP_FRAME then
            local pos = npc.Position
            local room = Game():GetRoom()
            for _ = 1, Mod.TaintedFleeboh.NUM_RELOCATE_TRIES do
                pos = room:FindFreePickupSpawnPosition(room:GetRandomPosition(0), 0)
                if pos:Distance(Game():GetNearestPlayer(pos).Position) > Mod.TaintedFleeboh.MIN_DIST then
                    break
                end
            end
            npc.Position = pos
            npc.TargetPosition = npc.Position
            npc.Velocity = Vector.Zero
            SFXManager():Play(SoundEffect.SOUND_HELL_PORTAL1)
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, Mod.TaintedFleeboh.PostNPCUpdate)

---@param player EntityPlayer
function Mod.TaintedFleeboh:PostPEffectUpdate(player)
    if player.FrameCount % Mod.TaintedFleeboh.JUMP_INTERVAL == 0 then
        if player:GetCollectibleRNG(Mod.EvilHowToJump.ID):RandomFloat() < Mod.TaintedFleeboh.JUMP_CHANCE
        and player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_HOW_TO_JUMP) == 0 then
            player:UseActiveItem(CollectibleType.COLLECTIBLE_HOW_TO_JUMP, UseFlag.USE_NOANIM)
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Mod.TaintedFleeboh.PostPEffectUpdate, Mod.TaintedFleeboh.ID)
--#endregion

--#region Evil How to Jump

Mod.EvilHowToJump = {
    ID = Isaac.GetItemIdByName("Evil How to Jump"),
    TELEPORT_CHANCE = 0.15,
    GIANTBOOK = Isaac.GetGiantBookIdByName("Evil How to Jump"),
}

---@param rng RNG
---@param player EntityPlayer
---@param flags UseFlag
function Mod.EvilHowToJump:OnUse(_, rng, player, flags)
    if player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_HOW_TO_JUMP) > 0 then
        return {
            Discharge = true
        }
    end

    if flags & UseFlag.USE_NOHUD == 0 then
        ItemOverlay.Show(Mod.EvilHowToJump.GIANTBOOK, nil, player)
    end

    if rng:RandomFloat() < Mod.EvilHowToJump.TELEPORT_CHANCE then
        player:UseActiveItem(CollectibleType.COLLECTIBLE_TELEPORT, UseFlag.USE_NOANIM)
    else
        player:UseActiveItem(CollectibleType.COLLECTIBLE_HOW_TO_JUMP, UseFlag.USE_NOANIM)
    end
end
Mod:AddCallback(ModCallbacks.MC_USE_ITEM, Mod.EvilHowToJump.OnUse, Mod.EvilHowToJump.ID)
--#endregion

---@param player EntityPlayer
Mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (_, player)
    local pt = player:GetPlayerType()
    if pt ~= Mod.Fleeboh.ID and pt ~= Mod.TaintedFleeboh.ID then return end
    local sprite = player:GetSprite()
    if sprite:GetFilename() ~= "gfx/001.000_Player.anm2" then return end
    sprite:Load("gfx/player_fleeboo", true)
end)

return Mod