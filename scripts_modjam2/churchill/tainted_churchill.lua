local JAM_NULL_ID = Isaac.GetNullItemIdByName("Tainted Churchill Jam")
local ROTATION_NULL_ID = Isaac.GetNullItemIdByName("Tainted Churchill Rotation Speed Up")

local GEAR_PIECE_ID = Isaac.GetEntityVariantByName("Churchill Gear Piece")

local sfx = SFXManager()
local game = Game()

local GEAR_COUNT = 3
local STUN_DURATION = 50 --in frames because the field is really sensitive for some reason 

local NUMBER_OF_INCREMENTS = 360
local LEEWAY = 30 --in degrees, both sides SET TO 180 for funnies
local ROTATION_SPEED = 2 --degrees per frame, added 60 times a second

local INIT_TEARS_MULT = 0.25

local HANDS_SPRITE_OFFSET = -29 --so its not just at the feet

local bigHandSprite = Sprite()
bigHandSprite:Load("gfx/effects/tainted_churchill_clock.anm2")
bigHandSprite:Play("BigHand")

local smallHandSprite = Sprite()
smallHandSprite:Load("gfx/effects/tainted_churchill_clock.anm2")
smallHandSprite:Play("SmallHand")

local function AngleDifference(a, b)
    local diff = (a - b) % 360
    if diff > 180 then diff = diff - 360 end
    return math.abs(diff)
end

---@param player EntityPlayer
local function jamPlayer(player) --this needs leaver prevention logic. Ideally, instead of keeping entities upon leaving (tho that would be awesome), make it so if you are jammed but no gears are in the room, spawns 3 gears.
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then player:SetCanShoot(true) return end --unable to jam if birthright (might cause issues with rotation speed)

    local effects = player:GetEffects()
    effects:RemoveNullEffect(ROTATION_NULL_ID, -1)

    player.ControlsCooldown = STUN_DURATION

    sfx:Play(ChurchillMod.SFX_JAM, 1, 2, false, math.random()*0.4+0.6) --dont go mad

    player:GetData().PathFinderGaper = player:GetData().PathFinderGaper or game:Spawn(EntityType.ENTITY_GAPER, 0, player.Position, Vector.Zero, player, 0, 1):ToNPC()

    local room = game:GetRoom()

    for i = 1, GEAR_COUNT, 1 do

        if not player:GetData().PathFinderGaper then return end
        player:GetData().PathFinderGaper.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

        local tryCount = 0

        ::again::
        local endPos = room:FindFreePickupSpawnPosition(room:GetRandomPosition(40))

        if not player:GetData().PathFinderGaper:GetPathfinder():HasPathToPos(endPos, false) then
            endPos = room:FindFreePickupSpawnPosition(room:GetRandomPosition(40))
            
            tryCount = tryCount + 1
            -- print(tryCount)
            if tryCount <= 10 then
                goto again
            else
                endPos = room:FindFreePickupSpawnPosition(player.Position)
                tryCount = 0
            end
        end
        player:GetData().PathFinderGaper:Remove()

        local gearPiece = game:Spawn(EntityType.ENTITY_PICKUP, GEAR_PIECE_ID, player.Position, Vector.Zero, player, 0, 1):ToPickup() --game:Spawn(EntityType.ENTITY_EFFECT, GEAR_PIECE_ID, pos, Vector.Zero, player, 0, 1):ToEffect()
        if not gearPiece then return end

        gearPiece:GetData().endPos = endPos

        local dist = player.Position:Distance(endPos)

        local baseHeight = 8
        local bonusHeight = math.min(dist / 80, 4)

        local config = {
            Height = baseHeight + bonusHeight,
            Tags = {
                "gearPiece"
            },
        }

        
        JumpLib:Jump(gearPiece, config)
    end

    effects:AddNullEffect(JAM_NULL_ID) --this has to be after spawning the gears.
end

---@param pickup EntityEffect
local function gearPieceInit(_, pickup)
    local sprite = pickup:GetSprite()

    local path = "gfx/entities/gear" .. math.random(3) .. "_" .. math.random(4) .. ".png"

    for _, layer in ipairs(sprite:GetAllLayers()) do
        sprite:ReplaceSpritesheet(layer:GetLayerID(), path, true)
    end

    sprite:Play("Idle")
end
ChurchillMod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, gearPieceInit, GEAR_PIECE_ID)

---@param pickup EntityEffect
local function gearPieceUpdate(_, pickup)
    local data = pickup:GetData()
    
    if data.endPos and pickup.Position:Distance(data.endPos) > 2 and not data.Pickable then
        local dist = pickup.Position:Distance(data.endPos)
        local dir = (data.endPos - pickup.Position):Normalized()

        pickup.Velocity = dir * dist/10
        --effect:AddVelocity(dir*0.005)
        pickup.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
    else
        pickup.Velocity = Vector.Zero
        data.Pickable = true
    end

    for _, player in ipairs(PlayerManager:GetPlayers()) do
        local effects = player:GetEffects()
        if player.Position:Distance(pickup.Position) <= player.Size + pickup.Size and effects:HasNullEffect(JAM_NULL_ID) and data.Pickable then
            if not pickup:GetSprite():IsPlaying("Collect") then
                sfx:Play(SoundEffect.SOUND_PENNYPICKUP)
                pickup:GetSprite():Play("Collect")
            end
        end
    end

    if pickup:GetSprite():IsFinished("Collect") then
        pickup:Remove()
    end
end
ChurchillMod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, gearPieceUpdate, GEAR_PIECE_ID)

--REMEMBER TO REMOVE COMMENTS LEFT FOR EZ DEBUGGING
---@param player EntityPlayer
local function minigame(_, player)
    if player:GetPlayerType() ~= ChurchillMod.PLAYER_CHURCHILL_B then return end

    local data = player:GetData()
    local effects = player:GetEffects()
    local gearCount = #Isaac.FindByType(EntityType.ENTITY_PICKUP, GEAR_PIECE_ID)
    if effects:HasNullEffect(JAM_NULL_ID) and gearCount <= 0 then
        effects:RemoveNullEffect(JAM_NULL_ID, -1)
    end
    if effects:HasNullEffect(JAM_NULL_ID) then player:SetCanShoot(false) return end

    player:SetCanShoot(true)

    bigHandSprite.Rotation = bigHandSprite.Rotation + (ROTATION_SPEED * (1 + 0.12*effects:GetNullEffectNum(ROTATION_NULL_ID))) --mult starts at 1, 0.12 more per item

    local room = game:GetRoom()
    data.alpha = data.alpha or 1

    if room:IsClear() then
        data.alpha = data.alpha - 0.01
        data.alpha = math.max(0, data.alpha)

        bigHandSprite.Color = Color(1, 1, 1, data.alpha)
        smallHandSprite.Color = Color(1, 1, 1, data.alpha)
        return
    else
        data.alpha = data.alpha + 0.02
        data.alpha = math.min(data.alpha, 1)

        bigHandSprite.Color = Color(1, 1, 1, data.alpha)
        smallHandSprite.Color = Color(1, 1, 1, data.alpha)
    end

    data.TargetRotation = data.TargetRotation or (360/NUMBER_OF_INCREMENTS) * math.random(NUMBER_OF_INCREMENTS)

    smallHandSprite.Rotation = data.TargetRotation

    if Input.IsActionTriggered(ButtonAction.ACTION_RESTART, player.ControllerIndex) then

        local diff = AngleDifference(bigHandSprite.Rotation, data.TargetRotation)

        if diff <= LEEWAY then
            sfx:Play(ChurchillMod.SFX_TIMING)
            data.TargetRotation = nil
            effects:AddNullEffect(ROTATION_NULL_ID)
        else
            jamPlayer(player)
        end
    end
end
ChurchillMod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, minigame)

local vect = Vector(0, HANDS_SPRITE_OFFSET)
---@param player EntityPlayer
local function allRenders(_, player, offset)
    if player:GetPlayerType() ~= ChurchillMod.PLAYER_CHURCHILL_B then return end

    bigHandSprite:Render(Isaac.WorldToScreen(player.Position + vect))
    smallHandSprite:Render(Isaac.WorldToScreen(player.Position + vect))
end
ChurchillMod:AddCallback(ModCallbacks.MC_PRE_RENDER_PLAYER_HEAD, allRenders)

---@param player EntityPlayer
local function taintedChurchillTearsMult(_, player)
    if player:GetPlayerType() ~= ChurchillMod.PLAYER_CHURCHILL_B then return end

    player.MaxFireDelay = ChurchillMod:toFireDelay(ChurchillMod:toTps(player.MaxFireDelay)*INIT_TEARS_MULT)
end
ChurchillMod:AddPriorityCallback(ModCallbacks.MC_EVALUATE_CACHE, CallbackPriority.LATE, taintedChurchillTearsMult, CacheFlag.CACHE_FIREDELAY)

if TheFuture then
    TheFuture.ModdedTaintedCharacterDialogue["Churchill"] = {
        "Geez!",
        "If I really grind your gears so much...",
        "you can just tell me!",
    }
end