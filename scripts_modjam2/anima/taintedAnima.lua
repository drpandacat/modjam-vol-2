local utils = require("scripts_modjam2.anima.utils")
local constants = require("scripts_modjam2.anima.constants")
---@class AnimaMod
local mod = AnimaCharacter
local game = mod.Game

local DEBUG = false
local imgui = ImGui

local tAnimaID = constants.Players.TaintedAnima
-- Dual Role Collectible id
local cDualRole = constants.Items.DualRole

-- Tainted Anima functions
mod.TaintedAnima = {}
local TaintedAnima = mod.TaintedAnima

---@enum DualRoleState
mod.TaintedAnima.DualRoleState = {
    TRAGEDY = -1,
    NONE = 0,
    PERSONA = 1,
}

---@enum AnimaTragedies
mod.TaintedAnima.TaintedAnimaTragedies = {
    NONE = -1,
    ISAAC = 0,      -- Newly spawned items cycle between 10 options
    MAGDALENE = 1,  -- Bleed effect
    CAIN = 2,       -- Newly spawned items are salvaged
    JUDAS = 3,      -- Chance for projectiles to be Shady shots
    SAMSON = 4,     -- Activates Berserk! at random
    EDEN = 5,       -- D4 or Reroll stats on damage
    APOLLYON = 6,   -- Spawn additional fly type enemies on enemy kill
    BETHANY = 7,    -- Weaker stats

    NUM_TRAGEDIES = 8,
}

mod.TaintedAnima.TragedyConfig = {
    {
        ID = TaintedAnima.TaintedAnimaTragedies.ISAAC,
        Name = "Isaac",
        Description = "Even more options...",
    },
    {
        ID = TaintedAnima.TaintedAnimaTragedies.MAGDALENE,
        NullEffect = constants.NullItems.TragedyTMagdalene,
        Name = "Magdalene",
        Description = "Anticoagulated",
    },
    {
        ID = TaintedAnima.TaintedAnimaTragedies.CAIN,
        Name = "Cain",
        Description = "Disappearing destiny",
    },
    {
        ID = TaintedAnima.TaintedAnimaTragedies.JUDAS,
        Name = "Judas",
        Description = "Shadow shot",
    },
    {
        ID = TaintedAnima.TaintedAnimaTragedies.SAMSON,
        Name = "Samson",
        Description = "Uncontrolled anger",
    },
    {
        ID = TaintedAnima.TaintedAnimaTragedies.EDEN,
        Name = "Eden",
        Description = "You feel volatile",
    },
    {
        ID = TaintedAnima.TaintedAnimaTragedies.APOLLYON,
        Name = "Apollyon",
        Description = "Pestilence cometh",
    },
    {
        ID = TaintedAnima.TaintedAnimaTragedies.BETHANY,
        Name = "Bethany",
        Description = "Feelings of weakness",
    },
}

for k, v in pairs(TaintedAnima.TaintedAnimaTragedies) do
    if k ~= "NONE" and k ~= "NUM_TRAGEDIES" then
        if mod.Anima.AnimaPersonas[k] and mod.Anima.AnimaPersonaConfig[mod.Anima.AnimaPersonas[k] + 1].CostumeID then
            TaintedAnima.TragedyConfig[v + 1].CostumeID = mod.Anima.AnimaPersonaConfig[mod.Anima.AnimaPersonas[k] + 1].CostumeID
        end
    end
end

mod.TaintedAnima.AlternateMaskCostumes = {
    Persona = {
        [mod.Anima.AnimaPersonas.MAGDALENE] = true,
        [mod.Anima.AnimaPersonas.JUDAS] = true,
        [mod.Anima.AnimaPersonas.SAMSON] = true,
        [mod.Anima.AnimaPersonas.LAZARUS] = true,
        [mod.Anima.AnimaPersonas.LILITH] = true,
        [mod.Anima.AnimaPersonas.BETHANY] = true,
        [mod.Anima.AnimaPersonas.JACOB_AND_ESAU] = true,
    },
    Tragedy = {
        [TaintedAnima.TaintedAnimaTragedies.MAGDALENE] = true,
        [TaintedAnima.TaintedAnimaTragedies.JUDAS] = true,
        [TaintedAnima.TaintedAnimaTragedies.SAMSON] = true,
        [TaintedAnima.TaintedAnimaTragedies.BETHANY] = true,
    },
    Collectible = {
        [CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL] = true,
        [CollectibleType.COLLECTIBLE_MY_LITTLE_UNICORN] = true,
        [CollectibleType.COLLECTIBLE_MUCORMYCOSIS] = true,
        [CollectibleType.COLLECTIBLE_2SPOOKY] = true,
    }
}

---@param player EntityPlayer
function mod.TaintedAnima.InitDualRoleData(player)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData

    if not pData.DualRoleData then
        pData.DualRoleData = {
            CharacterState = mod.TaintedAnima.DualRoleState.NONE,
            CurrentTragedy = mod.TaintedAnima.TaintedAnimaTragedies.NONE,

            EdenStats = {0, 0, 0, 0, 0, 0},
        }
    end
end

---@param player EntityPlayer
---@param forceTragedy AnimaTragedies?
function mod.TaintedAnima.AddTragedy(player, forceTragedy)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local dualRoleData = pData.DualRoleData

    player:TryRemoveNullCostume(constants.NullItems.CostumeHappyMask)

    local rng = player:GetCollectibleRNG(cDualRole)
    local evalItems = false
    local newTragedy = rng:RandomInt(TaintedAnima.TaintedAnimaTragedies.NUM_TRAGEDIES)
    if forceTragedy then newTragedy = forceTragedy end
    local newTragedyConfig = TaintedAnima.TragedyConfig[newTragedy + 1]

    dualRoleData.CurrentTragedy = newTragedy
    local desc = newTragedyConfig.Description
    if newTragedy == TaintedAnima.TaintedAnimaTragedies.EDEN then
        local length = desc:len()
        desc = ""
        for i = 1, length do
            local randomChar = math.random(32, 126)
            while randomChar == 34 or randomChar == 92 do   -- no " or \
                randomChar = math.random(32, 126)
            end
            desc = desc .. string.char(randomChar)
        end
    elseif newTragedy == TaintedAnima.TaintedAnimaTragedies.BETHANY then
        player:AddCustomCacheTag(CustomCacheTag.STAT_MULTIPLIER)
        evalItems = true
    end
    player:AddNullCostume((TaintedAnima.AlternateMaskCostumes.Tragedy[newTragedy]) and newTragedyConfig.CostumeID or constants.NullItems.CostumeSadMask)
    if evalItems then player:EvaluateItems() end

    local color = Color(0, 0, 0, 1)
    player:SetColor(color, 15, 999, true, false)
    mod.SFXManager:Play(SoundEffect.SOUND_BLACK_POOF, 1, nil, false, .75)
    player:AnimateSad()
    game:GetHUD():ShowItemText(newTragedyConfig.Name, desc)
end

---@param player EntityPlayer
function mod.TaintedAnima.HandleTragedyRemoval(player)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local dualRoleData = pData.DualRoleData
    local currentTragedy = dualRoleData.CurrentTragedy
    local currentTragedyConfig = TaintedAnima.TragedyConfig[currentTragedy + 1]

    local evalItems = false

    if currentTragedyConfig then
        if currentTragedyConfig.NullEffect then
            player:GetEffects():RemoveNullEffect(currentTragedyConfig.NullEffect, -1)
        end
        if currentTragedyConfig.CostumeID then player:TryRemoveNullCostume(currentTragedyConfig.CostumeID) end
        player:TryRemoveNullCostume(constants.NullItems.CostumeSadMask)
    end

    if currentTragedy == TaintedAnima.TaintedAnimaTragedies.SAMSON then
        player:GetEffects():RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_BERSERK, -1)
    elseif currentTragedy == TaintedAnima.TaintedAnimaTragedies.EDEN then
        player:AddCacheFlags(CacheFlag.CACHE_SPEED | CacheFlag.CACHE_FIREDELAY | CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_RANGE | CacheFlag.CACHE_SHOTSPEED | CacheFlag.CACHE_LUCK)
        evalItems = true
    elseif currentTragedy == TaintedAnima.TaintedAnimaTragedies.BETHANY then
        player:AddCustomCacheTag(CustomCacheTag.STAT_MULTIPLIER)
        evalItems = true
    end

    if evalItems then player:EvaluateItems() end
end

---@param player EntityPlayer
function mod.TaintedAnima.RemoveTragedy(player)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local dualRoleData = pData.DualRoleData

    TaintedAnima.HandleTragedyRemoval(player)
    dualRoleData.CurrentTragedy = TaintedAnima.TaintedAnimaTragedies.NONE
end

---@param player EntityPlayer
---@param tragedyType AnimaTragedies
function mod.TaintedAnima.HasTragedy(player, tragedyType)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local dualRoleData = pData.DualRoleData
    if not dualRoleData then return end

    return dualRoleData.CharacterState == TaintedAnima.DualRoleState.TRAGEDY and dualRoleData.CurrentTragedy == tragedyType
end

---@param player EntityPlayer
function mod.TaintedAnima.AutoUseDualRole(player)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local pTempData = mod:GetData(player)
    for i = ActiveSlot.SLOT_PRIMARY, ActiveSlot.SLOT_POCKET do
        if not pTempData.IsHoldingPersona and player:GetActiveItem(i) == cDualRole and player:GetActiveCharge(i) >= mod.ItemConfig:GetCollectible(cDualRole).MaxCharges then
            if pData.DualRoleData.CharacterState == TaintedAnima.DualRoleState.PERSONA then
                player:DischargeActiveItem(i)
            end
            player:UseActiveItem(cDualRole, 0, i)
        end
    end
end

-- Player Init
---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
    TaintedAnima.InitDualRoleData(player)
end)


-- Dual Role function

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (_, player)
    if player:GetPlayerType() ~= tAnimaID then return end
    TaintedAnima.AutoUseDualRole(player)
end)

---@param player EntityPlayer
---@param useFlags UseFlag
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, rng, player, useFlags)
    if utils:HasBit(useFlags, UseFlag.USE_CARBATTERY) then
        return
    end

    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local pTempData = mod:GetData(player)

    local storage = pData.AnimaCurrentStorage
    local personaPool = storage.AnimaPersonas

    if pData.DualRoleData.CharacterState == TaintedAnima.DualRoleState.NONE or pData.DualRoleData.CharacterState == TaintedAnima.DualRoleState.TRAGEDY then
        TaintedAnima.RemoveTragedy(player)
        if pTempData.IsHoldingPersona then
            pData.DualRoleData.CharacterState = TaintedAnima.DualRoleState.PERSONA
            mod.Anima.ChangePersona(player, personaPool[pTempData.AnimaSelectedPersonaIndex])

            pTempData.IsHoldingPersona = false
            --player:AddNullCostume(constants.NullItems.CostumeHappyMask)
            mod.Anima.InitPersonasPool(player, rng)
            rng:Next()

            return { Discharge = true, ShowAnim = true }
        else
            pTempData.IsHoldingPersona = true
        end

        return { Discharge = false }
    elseif pData.DualRoleData.CharacterState == TaintedAnima.DualRoleState.PERSONA then
        mod.Anima.RemovePersona(player, true)
        if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and rng:RandomFloat() < 0.5 then
            pData.DualRoleData.CharacterState = TaintedAnima.DualRoleState.NONE
            player:AnimateHappy()
            local color = Color.Default
            color:SetOffset(1, 1, 1)
            player:SetColor(color, 15, 999, true, false)
            game:GetHUD():ShowItemText("No Tragedy", "Stay seated folks!")
        else
            pData.DualRoleData.CharacterState = TaintedAnima.DualRoleState.TRAGEDY
            TaintedAnima.AddTragedy(player)
        end

        return { Discharge = true }
    end
end, cDualRole)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_NEW_ROOM_TEMP_EFFECTS, function (_, player)
    if player:GetPlayerType() == tAnimaID then
        local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
        local pTempData = mod:GetData(player)
        local rng = player:GetCollectibleRNG(cDualRole)
        local storage = pData.AnimaCurrentStorage
        local personaPool = storage.AnimaPersonas

        if pTempData.IsHoldingPersona then
            for i = ActiveSlot.SLOT_PRIMARY, ActiveSlot.SLOT_POCKET do
                if player:GetActiveItem(i) == cDualRole and player:GetActiveCharge(i) >= mod.ItemConfig:GetCollectible(cDualRole).MaxCharges then
                    player:DischargeActiveItem(i)
                    pData.DualRoleData.CharacterState = TaintedAnima.DualRoleState.PERSONA
                    mod.Anima.ChangePersona(player, personaPool[pTempData.AnimaSelectedPersonaIndex])

                    pTempData.IsHoldingPersona = false
                    --player:AddNullCostume(constants.NullItems.CostumeHappyMask)
                    mod.Anima.InitPersonasPool(player, rng)
                    rng:Next()
                end
            end
        end
    end
end)

---@param player EntityPlayer
---@param activeSlot ActiveSlot
mod:AddCallback(ModCallbacks.MC_PRE_PLAYERHUD_RENDER_ACTIVE_ITEM, function(_, player, activeSlot)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData

    local state = pData.DualRoleData.CharacterState

    if player:GetActiveItem(activeSlot) ~= cDualRole then
        return
    end

    local offsetX = (state == TaintedAnima.DualRoleState.TRAGEDY) and 32 or 0

    return { CropOffset = Vector(offsetX, 0) }
end)

-- Handle Costumes
---@param itemConfig ItemConfigItem
---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_ADD_COSTUME, function (_, itemConfig, player)
    if player:GetPlayerType() ~= tAnimaID then return end
    if not itemConfig:IsNull() then return end

    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local storage = pData.AnimaCurrentStorage
    local dualRoleData = pData.DualRoleData
    if not storage or not dualRoleData then return end

    local currentPersona = storage.CurrentPersona
    local currentTragedy = dualRoleData.CurrentTragedy
    if dualRoleData.CharacterState ~= TaintedAnima.DualRoleState.TRAGEDY and not TaintedAnima.AlternateMaskCostumes.Persona[currentPersona] then return end
    if dualRoleData.CharacterState == TaintedAnima.DualRoleState.TRAGEDY and not TaintedAnima.AlternateMaskCostumes.Tragedy[currentTragedy] then return end

    local config = (dualRoleData.CharacterState ~= TaintedAnima.DualRoleState.TRAGEDY) and mod.Anima.AnimaPersonaConfig[currentPersona + 1] or TaintedAnima.TragedyConfig[currentTragedy + 1]
    if itemConfig.ID == config.CostumeID then
        local map = player:GetCostumeLayerMap()
        local costumeSpriteDescs = player:GetCostumeSpriteDescs()
        for _, mapData in ipairs(map) do
            if mapData.costumeIndex ~= -1 then
                local costumeSpriteDesc = costumeSpriteDescs[mapData.costumeIndex + 1]
                if costumeSpriteDesc:GetItemConfig().ID == itemConfig.ID then
                    local sprite = costumeSpriteDesc:GetSprite()
                    local layerID = mapData.layerID
                    local layerState = sprite:GetLayer(layerID)
                    ---@diagnostic disable-next-line: need-check-nil
                    local defaultPath = layerState:GetDefaultSpritesheetPath()
                    local newPath = defaultPath:gsub("costumes", "costumes_anima_b")
                    if dualRoleData.CharacterState == TaintedAnima.DualRoleState.TRAGEDY then
                        newPath = newPath:gsub("%.png", "_tragedy.png")
                    end
                    sprite:ReplaceSpritesheet(layerID, newPath, true)
                    break

                    --local layerName = sprite:GetLayer(mapData.layerID):GetName()
                    --local costumeName = itemConfig.Name ~= "" and Isaac.GetString("Items", itemConfig.Name) or "NullItemID "..itemConfig.ID
                    --local spritePath = sprite:GetFilename()
                    --print(costumeName, layerName, spritePath)
                end
            end
        end
    end
end)

--[[ ---@param itemConfig ItemConfigItem
---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_ADD_COSTUME, function (_, itemConfig, player)
    if player:GetPlayerType() ~= tAnimaID then return end
    if not itemConfig:IsCollectible() then return end
    if not TaintedAnima.AlternateMaskCostumes.Collectible[itemConfig.ID] then return end

    local map = player:GetCostumeLayerMap()
    local costumeSpriteDescs = player:GetCostumeSpriteDescs()
    for _, mapData in ipairs(map) do
        if mapData.costumeIndex ~= -1 then
            local costumeSpriteDesc = costumeSpriteDescs[mapData.costumeIndex + 1]
            if costumeSpriteDesc:GetItemConfig().ID == itemConfig.ID then
                local sprite = costumeSpriteDesc:GetSprite()
                local layerID = mapData.layerID
                local layerState = sprite:GetLayer(layerID)
                ---@diagnostic disable-next-line: need-check-nil
                local defaultPath = layerState:GetDefaultSpritesheetPath()
                local newPath = defaultPath:gsub("costumes", "costumes_anima_b")
                sprite:ReplaceSpritesheet(layerID, newPath, true)
                break

                --local layerName = sprite:GetLayer(mapData.layerID):GetName()
                --local costumeName = itemConfig.Name ~= "" and Isaac.GetString("Items", itemConfig.Name) or "NullItemID "..itemConfig.ID
                --local spritePath = sprite:GetFilename()
                --print(costumeName, layerName, spritePath)
            end
        end
    end
end) ]]

-- Passive Tragedy Effects

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (_, player)
    if player:GetPlayerType() ~= tAnimaID then return end

    local fx = player:GetEffects()
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local dualRoleData = pData.DualRoleData
    
    for _, config in ipairs(TaintedAnima.TragedyConfig) do
        local nullFxID = config.NullEffect
        if TaintedAnima.HasTragedy(player, config.ID) and nullFxID then
            if not fx:HasNullEffect(nullFxID) then
                player:AddNullItemEffect(nullFxID)
            else
                local nullFx = fx:GetNullEffect(nullFxID)
                if nullFx then
                    if nullFxID == constants.NullItems.TragedyTMagdalene then
                        if (player.FrameCount % 15 == 0 or math.random(5) == 1) and player:GetHearts() > 2 then
                            local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_RED, 0, player.Position, Vector.Zero, player):ToEffect()
                            creep.SpriteScale = creep.SpriteScale * 0.75
                            creep.Timeout = 45
                            creep:Update()
                        end
                        if nullFx.Cooldown == 1 and player:GetHearts() > 2 then
                            player:AddHearts(-1)
                        end
                    end
                end
            end
        end
    end

    if TaintedAnima.HasTragedy(player, TaintedAnima.TaintedAnimaTragedies.SAMSON) and not player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_BERSERK) then
        if math.random(900) == 1 then
            player:UseActiveItem(CollectibleType.COLLECTIBLE_BERSERK, UseFlag.USE_NOANIM)
        end
    end
end)

---@param pickup EntityPickup
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, function (_, pickup)
    if pickup.FrameCount ~= 1 then return end

    local room = game:GetRoom()
    local cconfig = mod.ItemConfig:GetCollectible(pickup.SubType)

    local isQuest = cconfig and cconfig:HasTags(ItemConfig.TAG_QUEST)
    local nonRerollable = (pickup.SubType == 0 or pickup.SubType == CollectibleType.COLLECTIBLE_DADS_NOTE)

    local addIsaacTragedy = false
    local addCainTragedy = false

    local pickupData = mod.SaveManager.GetRerollPickupSave(pickup)
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        if player:GetPlayerType() == tAnimaID then
            if not isQuest and not nonRerollable then
                if TaintedAnima.HasTragedy(player, TaintedAnima.TaintedAnimaTragedies.CAIN) then
                    if pickupData.CainTragedyProtection then return end
                    local rng = pickup:GetDropRNG()
                    player:SalvageCollectible(pickup, rng, room:GetItemPool(rng:GetSeed()))
                    break
                elseif TaintedAnima.HasTragedy(player, TaintedAnima.TaintedAnimaTragedies.ISAAC) then
                    if pickupData.IsaacTragedyAffectedCollectible then return end
                    pickup:TryInitOptionCycle(9)
                    addIsaacTragedy = true
                    break
                else
                    addIsaacTragedy = true
                    addCainTragedy = true
                end
            end
        end
    end

    if addIsaacTragedy then
        pickupData.IsaacTragedyAffectedCollectible = true
    end
    if addCainTragedy then
        pickupData.CainTragedyProtection = true
    end
end, PickupVariant.PICKUP_COLLECTIBLE)

---@param projectile EntityProjectile
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, function (_, projectile)
    local player = PlayerManager.FirstPlayerByType(tAnimaID)
    if player then
        if TaintedAnima.HasTragedy(player, TaintedAnima.TaintedAnimaTragedies.JUDAS) then
            local shadyShotExists = false
            for _, p in ipairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE)) do
                p = p:ToProjectile()
                if p:HasProjectileFlags(ProjectileFlags.SIDEWAVE) then
                    shadyShotExists = true
                    break
                end
            end
            if not shadyShotExists then
                projectile:AddProjectileFlags(ProjectileFlags.SIDEWAVE)
                Isaac.CreateTimer(function ()
                    projectile.Color = Color(-1, -1, -1, 1, 1, 0, 0)
                end, 1, 1, false)
            end
        end
    end
end)

---@param ent Entity
---@param flags DamageFlag
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_TAKE_DMG, function(_, ent, _, flags)
    local player = ent:ToPlayer() --[[@as EntityPlayer]]
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local dualRoleData = pData.DualRoleData

    if player:GetPlayerType() ~= tAnimaID then return end

    local excludedDamageFlags = DamageFlag.DAMAGE_RED_HEARTS | DamageFlag.DAMAGE_NO_PENALTIES

    if TaintedAnima.HasTragedy(player, TaintedAnima.TaintedAnimaTragedies.EDEN) and not utils:HasBit(excludedDamageFlags, flags) then
        local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_MISSING_NO)
        if rng:RandomInt(2) == 0 then
            player:UseActiveItem(CollectibleType.COLLECTIBLE_D4, UseFlag.USE_NOANIM)
        else
            dualRoleData.EdenStats[1] = rng:RandomFloat() * 0.3 - 0.15
            dualRoleData.EdenStats[2] = rng:RandomFloat() * 1.5 - 0.75
            dualRoleData.EdenStats[3] = rng:RandomFloat() * 2.0 - 1.0
            dualRoleData.EdenStats[4] = rng:RandomFloat() * 120.0 - 60.0
            dualRoleData.EdenStats[5] = rng:RandomFloat() * 0.5 - 0.25
            dualRoleData.EdenStats[6] = rng:RandomFloat() * 2.0 - 1.0
            player:AddCacheFlags(CacheFlag.CACHE_SPEED | CacheFlag.CACHE_FIREDELAY | CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_RANGE | CacheFlag.CACHE_SHOTSPEED | CacheFlag.CACHE_LUCK, true)
        end
        player:PlayExtraAnimation("Glitch")
        mod.SFXManager:Play(SoundEffect.SOUND_EDEN_GLITCH)
    end
end, EntityType.ENTITY_PLAYER)

---@param ent Entity
---@param killSource EntityRef
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function (_, ent, killSource)
    if ent.Type < 10 or ent.Type > 999 then return end
    if ent.MaxHitPoints < 10 then return end
    local entConfig = EntityConfig.GetEntity(ent.Type, ent.Variant)
    if not entConfig then return end
    if entConfig:HasEntityTags(EntityTag.FLY) or entConfig:HasEntityTags(EntityTag.SPIDER) then return end
    if game:GetRoom():IsClear() then return end

    local player = utils:GetPlayerFromEntityRef(killSource)

    if player then
        local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
        
        if TaintedAnima.HasTragedy(player, TaintedAnima.TaintedAnimaTragedies.APOLLYON) then
            local rng = ent:GetDropRNG()
            local roll = rng:RandomInt(2)
            if roll == 0 then
                local flyAmount = math.ceil((ent.MaxHitPoints / 5) + 1)
                for i = 1, math.min(flyAmount, 10) do
                    local flyType = (rng:RandomInt(5) == 0) and EntityType.ENTITY_ATTACKFLY or EntityType.ENTITY_POOTER
                    Isaac.Spawn(flyType, 0, 0, ent.Position, RandomVector():Resized(math.random(10, 20)), ent)
                end
                ent:MakeBloodPoof(ent.Position, Color(1, 0, 0), ent.Size / 26)
                mod.SFXManager:Play(SoundEffect.SOUND_DEATH_BURST_LARGE)
            end
        end
    end
end)

---@param player EntityPlayer
---@param cacheFlag CacheFlag
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function (_, player, cacheFlag)
    if player:GetPlayerType() ~= tAnimaID then return end
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local dualRoleData = pData.DualRoleData
    if not dualRoleData then return end
    local edenStats = dualRoleData.EdenStats

    if utils:HasBit(cacheFlag, CacheFlag.CACHE_SPEED) then
        if TaintedAnima.HasTragedy(player, TaintedAnima.TaintedAnimaTragedies.EDEN) then
            player.MoveSpeed = player.MoveSpeed + edenStats[1]
        end
    end

    if utils:HasBit(cacheFlag, CacheFlag.CACHE_RANGE) then
        if TaintedAnima.HasTragedy(player, TaintedAnima.TaintedAnimaTragedies.EDEN) then
            player.TearRange = player.TearRange + edenStats[4]
        end
    end

    if utils:HasBit(cacheFlag, CacheFlag.CACHE_SHOTSPEED) then
        if TaintedAnima.HasTragedy(player, TaintedAnima.TaintedAnimaTragedies.EDEN) then
            player.ShotSpeed = player.ShotSpeed + edenStats[5]
        end
    end

    if utils:HasBit(cacheFlag, CacheFlag.CACHE_LUCK) then
        if TaintedAnima.HasTragedy(player, TaintedAnima.TaintedAnimaTragedies.EDEN) then
            player.Luck = player.Luck + edenStats[6]
        end
    end
end)

---@param player EntityPlayer
---@param evaluateFlags EvaluateStatStage
---@param currentValue number
mod:AddCallback(ModCallbacks.MC_EVALUATE_STAT, function (_, player, evaluateFlags, currentValue)
    if player:GetPlayerType() ~= tAnimaID then return end
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local dualRoleData = pData.DualRoleData
    if not dualRoleData then return end
    local edenStats = dualRoleData.EdenStats

    if evaluateFlags == EvaluateStatStage.TEARS_UP then
        if TaintedAnima.HasTragedy(player, TaintedAnima.TaintedAnimaTragedies.EDEN) then
            return currentValue + edenStats[2]
        end
    end

    if evaluateFlags == EvaluateStatStage.DAMAGE_UP then
        if TaintedAnima.HasTragedy(player, TaintedAnima.TaintedAnimaTragedies.EDEN) then
            return currentValue + edenStats[3]
        end
    end
end)

---@param player EntityPlayer
---@param customCache CustomCacheTag | string
---@param value number
mod:AddCallback(ModCallbacks.MC_EVALUATE_CUSTOM_CACHE, function (_, player, customCache, value)
    if player:GetPlayerType() ~= tAnimaID then return end
    if TaintedAnima.HasTragedy(player, TaintedAnima.TaintedAnimaTragedies.BETHANY) then
        return value * 0.75
    end
end, CustomCacheTag.STAT_MULTIPLIER)
