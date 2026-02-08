local utils = include "scripts_modjam2.anima.utils"
local constants = include "scripts_modjam2.anima.constants"
---@class AnimaMod
local mod = AnimaCharacter
local game = mod.Game

local DEBUG = false
local imgui = ImGui

local animaID = constants.Players.Anima
local tAnimaID = constants.Players.TaintedAnima

-- Anima functions
mod.Anima = {}

---@enum eAnimaPersonas
mod.Anima.AnimaPersonas = {
    NONE = -1,           -- nothing
    ISAAC = 0,           -- 50/50 chance to add cycle option for item pedestal
    MAGDALENE = 1,       -- speed down and tears up. 1/3 chance to spawn additional heart pickup after cleaning room
    CAIN = 2,            -- luck up, +innate lucky foot for slots increased chances
    JUDAS = 3,           -- damage up, increased deal chance and less chance penalty decrease
    EVE = 4,             -- damage and speed up. Has a chance to spawn dead bird on enemy kill
    SAMSON = 5,          -- speed up. Bloody Lust effect and increased damage cooldown
    LAZARUS = 6,         -- lazarus rags like revive with damage/speed up and flight
    AZAZEL = 7,          -- unused
    EDEN = 8,            -- innate chaos and gulped "no" trinket. Gain stats on item pickup while this persona is active
    LILITH = 9,          -- familiar multiplier up. Triggers Box of Friends on boss room/challenge room start. Gain Brother Bobby if player doesn't have familiars
    APOLLYON = 10,       -- gain permanent stat modifier on item pickup
    BETHANY = 11,        -- forces angel deals. Has a chance to spawn random wisp on enemy kill
    JACOB_AND_ESAU = 12, -- spawns twin/decoy with random items, can't pickup items, has limit of 3 soul health containers

    NUM_PERSONA = 13,
}

---@enum PersonaActiveStatus
mod.Anima.PersonaActiveStatus = {
    NORMAL = 0,
    DISSOCIATIVE = 1,
    DISSOCIATIVE_USED = 2,
}

---@class AnimaPersonaConfig
---@field ID eAnimaPersonas @id of persona
---@field CostumeID NullItemID | integer @costume that will be attached to the persona
---@field Name? string @string for debugging
---@field CacheFlags? CacheFlag
---@field InnateItem? CollectibleType @Innate item for persona, also used for continue restore
---@field WispID? CollectibleType | integer @Wisp for Book of Virtues interaction
---@field Description? string

---@type AnimaPersonaConfig[]
mod.Anima.AnimaPersonaConfig = {
    {
        ID = mod.Anima.AnimaPersonas.ISAAC,
        CostumeID = NullItemID.ID_NULL,
        Name = "Isaac",
        CacheFlags = CacheFlag.CACHE_FIREDELAY,
        WispID = CollectibleType.COLLECTIBLE_D6,
        Description = "Tears up. More options?",
    },
    {
        ID = mod.Anima.AnimaPersonas.MAGDALENE,
        CostumeID = NullItemID.ID_MAGDALENE,
        Name = "Magdalene",
        CacheFlags = CacheFlag.CACHE_FIREDELAY | CacheFlag.CACHE_SPEED,
        WispID = CollectibleType.COLLECTIBLE_YUM_HEART,
        Description = "Tears up + speed down. More hearts",
    },
    {
        ID = mod.Anima.AnimaPersonas.CAIN,
        CostumeID = NullItemID.ID_CAIN,
        Name = "Cain",
        CacheFlags = CacheFlag.CACHE_LUCK,
        InnateItem = CollectibleType.COLLECTIBLE_LUCKY_FOOT,
        WispID = 65538,
        Description = "Luck + fortune up",
    },
    {
        ID = mod.Anima.AnimaPersonas.JUDAS,
        CostumeID = NullItemID.ID_JUDAS,
        Name = "Judas",
        CacheFlags = CacheFlag.CACHE_DAMAGE,
        WispID = CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL,
        Description = "Damage up. The call of darkness resonates",
    },
    {
        ID = mod.Anima.AnimaPersonas.EVE,
        CostumeID = NullItemID.ID_EVE,
        Name = "Eve",
        CacheFlags = CacheFlag.CACHE_FAMILIARS | CacheFlag.CACHE_SPEED | CacheFlag.CACHE_DAMAGE,
        WispID = CollectibleType.COLLECTIBLE_RAZOR_BLADE,
        Description = "Speed + DMG up. A flock of birds",
    },
    {
        ID = mod.Anima.AnimaPersonas.SAMSON,
        CostumeID = NullItemID.ID_SAMSON,
        Name = "Samson",
        CacheFlags = CacheFlag.CACHE_SPEED | CacheFlag.CACHE_DAMAGE,
        WispID = CollectibleType.COLLECTIBLE_BLOOD_RIGHTS,
        Description = "DMG + speed + rage up",
    },
    {
        ID = mod.Anima.AnimaPersonas.LAZARUS,
        CostumeID = NullItemID.ID_LAZARUS,
        Name = "Lazarus",
        CacheFlags = CacheFlag.CACHE_FLYING,
        Description = "Eternal life?",
    },
    {
        ID = mod.Anima.AnimaPersonas.AZAZEL,
        CostumeID = NullItemID.ID_AZAZEL,
        Name = "Azazel",
    },
    {
        ID = mod.Anima.AnimaPersonas.EDEN,
        CostumeID = NullItemID.ID_EDEN,
        Name = "Eden",
        CacheFlags = CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_FIREDELAY | CacheFlag.CACHE_SHOTSPEED | CacheFlag.CACHE_RANGE | CacheFlag.CACHE_SPEED | CacheFlag.CACHE_LUCK,
        InnateItem = CollectibleType.COLLECTIBLE_CHAOS,
        WispID = CollectibleType.COLLECTIBLE_UNDEFINED,
        Description = "Embrace chaos",
    },
    {
        ID = mod.Anima.AnimaPersonas.LILITH,
        CostumeID = NullItemID.ID_LILITH,
        Name = "Lilith",
        CacheFlags = CacheFlag.CACHE_FAMILIARS,
        WispID = CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS,
        Description = "Me and my friends",
    },
    {
        ID = mod.Anima.AnimaPersonas.APOLLYON,
        CostumeID = NullItemID.ID_APOLLYON,
        Name = "Apollyon",
        WispID = CollectibleType.COLLECTIBLE_VOID,
        Description = "Consume your destiny",
    },
    {
        ID = mod.Anima.AnimaPersonas.BETHANY,
        CostumeID = NullItemID.ID_BETHANY,
        Name = "Bethany",
        WispID = CollectibleType.COLLECTIBLE_NULL,
        Description = "A divine spiritual path",
    },
    {
        ID = mod.Anima.AnimaPersonas.JACOB_AND_ESAU,
        CostumeID = NullItemID.ID_JACOB,
        Name = "Jacob & Esau",
        WispID = CollectibleType.COLLECTIBLE_ESAU_JR,
        Description = "Imaginary friend",
    },
}

--for Apollyon persona on item pickup
mod.Anima.StatModifiers = {
    {
        Set = function(player, increment)
            player:SetDamageModifier(player:GetDamageModifier() + increment)
        end,
    },
    {
        Set = function(player, increment)
            player:SetFireDelayModifier(player:GetFireDelayModifier() + increment)
        end,
    },
    {
        Set = function(player, increment)
            player:SetLuckModifier(player:GetLuckModifier() + increment)
        end,
    },
    {
        Set = function(player, increment)
            player:SetShotSpeedModifier(player:GetShotSpeedModifier() + increment)
        end,
    },
    {
        Set = function(player, increment)
            player:SetSpeedModifier(player:GetSpeedModifier() + increment)
        end,
    },
    {
        Set = function(player, increment)
            player:SetTearRangeModifier(player:GetTearRangeModifier() + increment)
        end,
    },
}

--temp stats up while Eden Persona is active
---@type {Cache: CacheFlag, StatUp : number}[]>
mod.Anima.EdenCacheUpgrade = {
    {
        Cache = CacheFlag.CACHE_DAMAGE,
        StatUp = .45,
    },
    {
        Cache = CacheFlag.CACHE_FIREDELAY,
        StatUp = .66,
    },
    {
        Cache = CacheFlag.CACHE_SHOTSPEED,
        StatUp = .55,
    },
    {
        Cache = CacheFlag.CACHE_RANGE,
        StatUp = 30,
    },
    {
        Cache = CacheFlag.CACHE_SPEED,
        StatUp = .20,
    },
    {
        Cache = CacheFlag.CACHE_LUCK,
        StatUp = .10,
    },

}

--#region Character and Item

--I added it much lately during development
---@param player EntityPlayer
---@return AnimaStorage
function mod.Anima.GetAnimaStorage(player)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    return pData.AnimaCurrentStorage
end

---@param player EntityPlayer
function mod.Anima.InvalidatePlayersFamiliars(player)
    for i, ent in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR)) do
        local fam = ent:ToFamiliar() --[[@as EntityFamiliar]]

        if GetPtrHash(fam.Player) == GetPtrHash(player) then
            fam:InvalidateCachedMultiplier()
        end
    end
end

---@param player EntityPlayer
---@return CacheFlag
function mod.Anima.IncreaseEdenPersonaStat(player)
    local storage, rng = mod.Anima.GetAnimaStorage(player), player:GetCollectibleRNG(constants.Items.Persona)

    local cacheFlag = 0

    rng:Next()
    local roll = rng:RandomInt(1, 6)

    storage.EdenPersonaStats[roll] = storage.EdenPersonaStats[roll] + mod.Anima.EdenCacheUpgrade[roll].StatUp
    cacheFlag = cacheFlag | mod.Anima.EdenCacheUpgrade[roll].Cache

    return cacheFlag
end

--Cleans specific personas effects/items/costumes on persona change/removal
---@param player EntityPlayer
---@param evaluateItems boolean
function mod.Anima.HandlePersonaRemoval(player, evaluateItems)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local animaStorage = pData.AnimaCurrentStorage
    local config = mod.Anima.AnimaPersonaConfig[animaStorage.CurrentPersona + 1]
    local effects = player:GetEffects()

    local cacheFlags = config and config.CacheFlags or 0
    if animaStorage.CurrentPersona == mod.Anima.AnimaPersonas.CAIN then

    elseif animaStorage.CurrentPersona == mod.Anima.AnimaPersonas.JUDAS then
        player:TryRemoveSmeltedTrinket(TrinketType.TRINKET_NUMBER_MAGNET)
    elseif animaStorage.CurrentPersona == mod.Anima.AnimaPersonas.EVE then
        effects:RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_DEAD_BIRD, -1)

        if not player:HasCollectible(CollectibleType.COLLECTIBLE_DEAD_BIRD) then
            player:TryRemoveCollectibleCostume(CollectibleType.COLLECTIBLE_DEAD_BIRD)
        end
    elseif animaStorage.CurrentPersona == mod.Anima.AnimaPersonas.SAMSON then

    elseif animaStorage.CurrentPersona == mod.Anima.AnimaPersonas.LAZARUS then
        effects:RemoveNullEffect(constants.NullItems.PersonaLazarusRevival, -1)
        effects:RemoveNullEffect(constants.NullItems.PersonaLazarusPostRevive, -1)
    elseif animaStorage.CurrentPersona == mod.Anima.AnimaPersonas.EDEN then
        player:TryRemoveSmeltedTrinket(TrinketType.TRINKET_NO)
    elseif animaStorage.CurrentPersona == mod.Anima.AnimaPersonas.LILITH then
        mod.Anima.InvalidatePlayersFamiliars(player)
    elseif animaStorage.CurrentPersona == mod.Anima.AnimaPersonas.JACOB_AND_ESAU then
        for _, decoy in pairs(utils:GetPlayersByType(constants.Players.Anima_Decoy)) do
            if GetPtrHash(decoy.Parent) == GetPtrHash(player) then
                decoy:Kill()

                animaStorage.LostDecoyPlayer = true
                break
            end
        end
    end

    if animaStorage.CurrentCostumeID ~= NullItemID.ID_NULL then
        player:TryRemoveNullCostume(animaStorage.CurrentCostumeID)
    end

    if animaStorage.PersonaInnateItem ~= CollectibleType.COLLECTIBLE_NULL then
        player:AddInnateCollectible(animaStorage.PersonaInnateItem, -1)
        animaStorage.PersonaInnateItem = CollectibleType.COLLECTIBLE_NULL
    end

    local wisps = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.WISP)

    if #wisps > 0 then
        for i, ent in ipairs(wisps) do
            local wisp = ent:ToFamiliar() --[[@as EntityFamiliar]]
            local famData = mod.SaveManager.GetRunSave(wisp) ---@type AnimaFamiliarData

            if wisp.Player and GetPtrHash(wisp.Player) == GetPtrHash(player) then
                if famData and famData.IsPersonaWisp then
                    wisp:Kill()
                end
            end
        end
    end

    if cacheFlags > 0 then
        player:AddCacheFlags(cacheFlags, evaluateItems)
    end
end

---@param player EntityPlayer
---@param changedPersona eAnimaPersonas
function mod.Anima.ChangePersona(player, changedPersona)
    assert((changedPersona >= 0 and changedPersona <= mod.Anima.AnimaPersonas.NUM_PERSONA - 1), "Invalid Anima Persona!: " .. tostring(changedPersona))
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local animaStorage = pData.AnimaCurrentStorage

    local config = mod.Anima.AnimaPersonaConfig[changedPersona + 1]
    local newPersona, newCostume, newInnateItem, wispID, personaDescription = config.ID, config.CostumeID, config.InnateItem, config.WispID or CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES, config.Description

    local color = Color.Default
    color:SetOffset(1, 1, 1)

    local cacheFlags = config.CacheFlags or 0
    if newPersona ~= animaStorage.CurrentPersona then
        if animaStorage.CurrentPersona ~= mod.Anima.AnimaPersonas.NONE then
            mod.Anima.HandlePersonaRemoval(player, false)

            if animaStorage.HadPersonaBefore then
                animaStorage.HadPersonaBefore = false
            end
        end

        if newPersona == mod.Anima.AnimaPersonas.CAIN then

        elseif newPersona == mod.Anima.AnimaPersonas.JUDAS then
            player:AddSmeltedTrinket(TrinketType.TRINKET_NUMBER_MAGNET)
        elseif newPersona == mod.Anima.AnimaPersonas.EVE then
            player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_DEAD_BIRD, false)
        elseif newPersona == mod.Anima.AnimaPersonas.SAMSON then

        elseif newPersona == mod.Anima.AnimaPersonas.LAZARUS then
            if not animaStorage.LazarusUsedRevive then
                player:GetEffects():AddNullEffect(constants.NullItems.PersonaLazarusRevival, false)
            end
        elseif newPersona == mod.Anima.AnimaPersonas.EDEN then
            player:AddSmeltedTrinket(TrinketType.TRINKET_NO)
        elseif newPersona == mod.Anima.AnimaPersonas.LILITH then
            local hasFam = false
            for _, fams in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR)) do
                if fams.Variant ~= FamiliarVariant.BLUE_SPIDER
                and fams.Variant ~= FamiliarVariant.BLUE_FLY then
                    local famPlayer = fams:ToFamiliar().Player
                    if famPlayer and GetPtrHash(famPlayer) == GetPtrHash(player) then
                        hasFam = true
                        break
                    end
                end
            end

            if not hasFam then
                player:AddInnateCollectible(CollectibleType.COLLECTIBLE_DEMON_BABY)
                animaStorage.PersonaInnateItem = CollectibleType.COLLECTIBLE_DEMON_BABY
            end

            mod.Anima.InvalidatePlayersFamiliars(player)
        elseif newPersona == mod.Anima.AnimaPersonas.BETHANY then
            if not mod.PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_DUALITY) then
                game:GetLevel():InitializeDevilAngelRoom(true, false)
            end
        elseif newPersona == mod.Anima.AnimaPersonas.JACOB_AND_ESAU then
            if not animaStorage.LostDecoyPlayer then
                local decoy = mod.PlayerManager.SpawnCoPlayer2(constants.Players.Anima_Decoy)
                decoy:SetControllerIndex(player.Index)
                decoy.Parent = player

                local playerPos = player.Position
                decoy.Position = Vector(playerPos.X + 5, playerPos.Y)
                decoy:InitPostLevelInitStats()

                local itemHistory = player:GetHistory():GetCollectiblesHistory()

                local rng = RNG(decoy.InitSeed, 22)
                for _, itemEntry in pairs(itemHistory) do
                    if not itemEntry:IsTrinket() and mod.ItemConfig:GetCollectible(itemEntry:GetItemID()).Type ~= ItemType.ITEM_ACTIVE then
                        local poolType = itemEntry:GetItemPoolType() == ItemPoolType.POOL_NULL and ItemPoolType.POOL_TREASURE or itemEntry:GetItemPoolType()
                        local seed = rng:Next()

                        local poolItem = game:GetItemPool():GetCollectible(poolType, true, seed, nil, GetCollectibleFlag.BAN_ACTIVES)

                        if DEBUG then
                            print("Adding item for decoy:", mod.ItemConfig:GetCollectible(poolItem).Name)
                        end

                        decoy:AddCollectible(poolItem)
                    end
                end

                if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
                    for i = 1, 3 do
                        decoy:AddWisp(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES, decoy.Position, true)
                    end
                end
            end
        end

        player:SetColor(color, 15, 999, true, false)
        mod.SFXManager:Play(SoundEffect.SOUND_BLACK_POOF, 1, nil, false, .75)

        if newCostume ~= NullItemID.ID_NULL then
            player:AddNullCostume(newCostume)
        end

        if newInnateItem then
            player:AddInnateCollectible(newInnateItem)
            player:RemoveCostume(mod.ItemConfig:GetCollectible(newInnateItem))
            animaStorage.PersonaInnateItem = newInnateItem
        end

        if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
            --handle unique interactions :v
            if wispID == CollectibleType.COLLECTIBLE_NULL then
                if newPersona == mod.Anima.AnimaPersonas.BETHANY then
                    for i = 1, 3 do
                        local wisp = player:AddWisp(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES, player.Position, true)

                        local famData = mod.SaveManager.GetRunSave(wisp) ---@type AnimaFamiliarData
                        famData.IsPersonaWisp = true
                    end
                end
            else
                local wisp = player:AddWisp(wispID, player.Position, true)

                local famData = mod.SaveManager.GetRunSave(wisp) ---@type AnimaFamiliarData
                famData.IsPersonaWisp = true
            end
        end

        --Messed with indexing, so +1 here (again)
        if personaDescription and not animaStorage.SeenDescriptions[newPersona + 1] then
            game:GetHUD():ShowItemText(config.Name, personaDescription)

            animaStorage.SeenDescriptions[newPersona + 1] = true
        end
    end

    animaStorage.CurrentPersona = newPersona
    animaStorage.CurrentCostumeID = newCostume

    if cacheFlags > 0 then
        player:AddCacheFlags(cacheFlags, true) ---@diagnostic disable-line: param-type-mismatch
    else
        player:EvaluateItems()
    end

    if DEBUG then
        imgui.UpdateData("AnimaDebugMenuCharacters", ImGuiData.Value, newPersona + 1)
    end
end

---@param player EntityPlayer
---@param skipVisual? boolean
function mod.Anima.RemovePersona(player, skipVisual)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local pTempData = mod:GetData(player)
    local effects = player:GetEffects()
    local animaStorage = pData.AnimaCurrentStorage

    if not skipVisual then
        local color = Color.Default
        color:SetOffset(1, 1, 1)

        player:SetColor(color, 15, 999, true, false)

        player:AnimateSad()
    end

    mod.Anima.HandlePersonaRemoval(player, false)

    if animaStorage.CurrentPersona == mod.Anima.AnimaPersonas.EDEN then
        animaStorage.EdenPersonaStats = { 0, 0, 0, 0, 0, 0 }
    end

    if animaStorage.CurrentCostumeID ~= NullItemID.ID_NULL then
        player:TryRemoveNullCostume(animaStorage.CurrentCostumeID)
    end

    animaStorage.CurrentPersona = mod.Anima.AnimaPersonas.NONE
    animaStorage.CurrentCostumeID = NullItemID.ID_NULL

    pTempData.IsHoldingPersona = false

    player:EvaluateItems()

    if DEBUG then
        imgui.UpdateData("AnimaDebugMenuCharacters", ImGuiData.Value, mod.Anima.AnimaPersonas.NONE)
    end
end

---@param player EntityPlayer
function mod.Anima.RemovePersonaFromPool(player)
    local storage = mod.Anima.GetAnimaStorage(player)
    local pTempData = mod:GetData(player)

    for i, v in ipairs(storage.AnimaPersonas) do
        if v == storage.CurrentPersona then
            table.remove(storage.AnimaPersonas, i)
            break
        end
    end

    mod.Anima.RemovePersona(player)

    if storage.PersonaActiveStatus == mod.Anima.PersonaActiveStatus.NORMAL then
        storage.PersonaActiveStatus = mod.Anima.PersonaActiveStatus.DISSOCIATIVE
        pTempData.AnimaSelectedPersonaIndex = 1
    end

    storage.HadPersonaBefore = false
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local pTempData = mod:GetData(player)
    if not (player:GetPlayerType() == animaID or player:GetPlayerType() == tAnimaID) then return end

    if pTempData.IsHoldingPersona then
        local numPersonas = #pData.AnimaCurrentStorage.AnimaPersonas
        if Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then
            pTempData.AnimaSelectedPersonaIndex = (pTempData.AnimaSelectedPersonaIndex % numPersonas) + 1
        end
    end

    if DEBUG then
        if Input.IsButtonTriggered(Keyboard.KEY_9, player.ControllerIndex) then
            mod.Anima.ChangePersona(player, 1)
        end

        if Input.IsButtonTriggered(Keyboard.KEY_0, player.ControllerIndex) then
            mod.Anima.RemovePersona(player)
        end
    end
end)

---@param ent Entity
---@param flags DamageFlag
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_TAKE_DMG, function(_, ent, _, flags)
    local player = ent:ToPlayer() --[[@as EntityPlayer]]
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local pTempData = mod:GetData(player)

    local storage = pData.AnimaCurrentStorage

    local effects = player:GetEffects()

    if player:GetPlayerType() ~= constants.Players.Anima and player:GetPlayerType() ~= constants.Players.TaintedAnima then
        return
    end

    if storage.CurrentPersona == mod.Anima.AnimaPersonas.SAMSON then
        player:SetBloodLustCounter(player:GetBloodLustCounter() + 1)
        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE, true)
        player:SetMinDamageCooldown(player:GetDamageCooldown() + 60)
    end

    if player:GetPlayerType() == constants.Players.TaintedAnima then return end
    local excludedDamageFlags = DamageFlag.DAMAGE_RED_HEARTS | DamageFlag.DAMAGE_NO_PENALTIES

    if storage.CurrentPersona ~= mod.Anima.AnimaPersonas.NONE and not utils:HasBit(excludedDamageFlags, flags) then
        local rng = player:GetCollectibleRNG(666)
        local maxRollNum = (storage.HadPersonaBefore and 2) or 9
        local maxBirthrightRollNum = (storage.HadPersonaBefore and 4) or 17

        local roll = rng:RandomInt((player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT, false) and maxBirthrightRollNum) or maxRollNum)
        if roll == 0 then
            mod.Anima.RemovePersonaFromPool(player)
        end
    end
end, EntityType.ENTITY_PLAYER)

---@param ent Entity
---@param flags DamageFlag
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, _, flags, _, damageCountdown)
    local player = ent:ToPlayer() --[[@as EntityPlayer]]
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData

    local storage = pData.AnimaCurrentStorage

    if player:GetPlayerType() ~= constants.Players.Anima then
        return
    end

    if storage.CurrentPersona == mod.Anima.AnimaPersonas.SAMSON then
        --player:SetMinDamageCooldown(90)
    end
end, EntityType.ENTITY_PLAYER)

local personaIcons = Sprite()
personaIcons:Load("gfx/ui/anima personas.anm2")

personaIcons:Play("Open")
personaIcons:LoadGraphics()

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function(_, player)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local pTempData = mod:GetData(player)
    local level = game:GetLevel()

    if not pTempData.IsHoldingPersona then
        return
    end

    local pool = pData.AnimaCurrentStorage.AnimaPersonas


    local centerPos = Isaac.WorldToRenderPosition(player.Position + Vector(0, -65 * player.SpriteScale.Y)) + game:GetRoom():GetRenderScrollOffset()
    local n = #pool
    local spacing = 30

    if n < 1 then return end

    local totalWidth = (n - 1) * spacing
    local startX = centerPos.X - totalWidth / 2

    for i = 1, n do
        local pos = Vector(startX + (i - 1) * spacing, centerPos.Y)

        local iconLayer = personaIcons:GetLayer(0) --[[@as LayerState]]
        local isSelectedPersona = i == pTempData.AnimaSelectedPersonaIndex

        local anim = not isSelectedPersona and "Closed" or "Open"
        local colorAlpha = not isSelectedPersona and .5 or 1
        local size = not isSelectedPersona and .5 or 1
        local frame = utils:HasBit(level:GetCurses(), LevelCurse.CURSE_OF_BLIND) and 13 or pool[i]

        personaIcons:SetFrame(anim, frame)

        iconLayer:SetSize(Vector(size, size))
        iconLayer:SetColor(Color(1, 1, 1, colorAlpha))


        personaIcons:RenderLayer(0, pos)
        --Isaac.RenderScaledText(tostring(i), pos.X, pos.Y, .5, .5, 1, 1, 1, 1)
    end
end)

---@param player EntityPlayer
---@param rng RNG?
function mod.Anima.InitPersonasPool(player, rng)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData

    pData.AnimaCurrentStorage.AnimaPersonas = {}

    local ids = {}
    for _, persona in ipairs(mod.Anima.AnimaPersonaConfig) do
        if DEBUG then
            --print("shoving personas id:", persona.Name, persona.ID)
        end

        if persona.ID ~= mod.Anima.AnimaPersonas.AZAZEL then --to-do: I messed up with the table structure
            ids[#ids + 1] = persona.ID
        end
    end

    if not rng then
        rng = RNG(game:GetSeeds():GetStageSeed(utils:GetAdjustedLevelStage()), 67)
    end

    utils:ShuffleTable(ids, rng)

    if player:GetPlayerType() == animaID or player:GetPlayerType() == tAnimaID then
        local limit = (player:GetPlayerType() == animaID and player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT, false)) and 5 or 3
        for i = 1, math.min(limit, #ids) do
            if DEBUG then
                print("adding persiona to pool:", ids[i])
            end

            pData.AnimaCurrentStorage.AnimaPersonas[# pData.AnimaCurrentStorage.AnimaPersonas + 1] = ids[i]
        end
    end
end

---@param player EntityPlayer
function mod.Anima.InitAnimaStorage(player)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData

    if pData.AnimaCurrentStorage and pData.AnimaCurrentStorage.CurrentPersona ~= mod.Anima.AnimaPersonas.NONE then
        mod.Anima.HandlePersonaRemoval(player, false)
    end

    ---@diagnostic disable-next-line: missing-fields
    pData.AnimaCurrentStorage = { CurrentPersona = mod.Anima.AnimaPersonas.NONE, CurrentCostumeID = NullItemID.ID_NULL, PersonaActiveStatus = mod.Anima.PersonaActiveStatus.NORMAL, PersonaInnateItem = CollectibleType.COLLECTIBLE_NULL, HadPersonaBefore = false, LostDecoyPlayer = false, EdenPersonaStats = { 0, 0, 0, 0, 0, 0 }, LazarusUsedRevive = false, SeenDescriptions = { false, false, false, false, false, false, false, false, false, false, false, false } }

    if not pData.AnimaCurrentStorage.AnimaPersonas then
        Isaac.CreateTimer(function()
            mod.Anima.InitPersonasPool(player) --i hope it will not break the mod
        end, 1, 1, false)
    end

    player:EvaluateItems()
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PLAYER_INIT_POST_LEVEL_INIT_STATS, function(_, player)
    mod.Anima.InitAnimaStorage(player)
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local pTempData = mod:GetData(player)

    if not pData.AnimaCurrentStorage then
        mod.Anima.InitAnimaStorage(player)
    end

    if pData.AnimaCurrentStorage.PersonaInnateItem and pData.AnimaCurrentStorage.PersonaInnateItem ~= CollectibleType.COLLECTIBLE_NULL then
        player:AddInnateCollectible(pData.AnimaCurrentStorage.PersonaInnateItem)
        player:RemoveCostume(mod.ItemConfig:GetCollectible(pData.AnimaCurrentStorage.PersonaInnateItem))
    end

    pTempData.AnimaSelectedPersonaIndex = 1
    pTempData.IsHoldingPersona = false
    pTempData.AnimaExtraTempData = { EveKillBirds = 0 }
end)

---@param player EntityPlayer
---@param isPostLevelFinished boolean
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_NEW_LEVEL, function(_, player, _, isPostLevelFinished)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local storage = pData.AnimaCurrentStorage
    local effects = player:GetEffects()
    if isPostLevelFinished then
        mod.Anima.InitPersonasPool(player)

        if storage.CurrentPersona == mod.Anima.AnimaPersonas.EVE then
            effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_DEAD_BIRD, false)
            player:AddCacheFlags(CacheFlag.CACHE_FAMILIARS, true)
        elseif storage.CurrentPersona == mod.Anima.AnimaPersonas.LAZARUS then
            effects:RemoveNullEffect(constants.NullItems.PersonaLazarusRevival, -1)
            effects:RemoveNullEffect(constants.NullItems.PersonaLazarusPostRevive, -1)

            effects:AddNullEffect(constants.NullItems.PersonaLazarusRevival)
        elseif storage.CurrentPersona == mod.Anima.AnimaPersonas.BETHANY then
            if not mod.PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_DUALITY) then
                game:GetLevel():InitializeDevilAngelRoom(true, false)
            end
        end

        --to-do: maybe add j&e persona decoy respawn after previous died?

        storage.PersonaActiveStatus = mod.Anima.PersonaActiveStatus.NORMAL

        if storage.CurrentPersona ~= mod.Anima.AnimaPersonas.NONE then
            storage.HadPersonaBefore = true
        end

        storage.LostDecoyPlayer = false
        storage.LazarusUsedRevive = false
    end
end)

---@param player EntityPlayer
---@param useFlags UseFlag
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, _, player, useFlags)
    if utils:HasBit(useFlags, UseFlag.USE_CARBATTERY) then
        return
    end

    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local pTempData = mod:GetData(player)

    local storage = pData.AnimaCurrentStorage
    local personaPool = storage.AnimaPersonas

    if storage.PersonaActiveStatus == mod.Anima.PersonaActiveStatus.DISSOCIATIVE_USED or #personaPool == 0 then
        mod.SFXManager:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ)
        return
    end

    if pTempData.IsHoldingPersona then
        mod.Anima.ChangePersona(player, personaPool[pTempData.AnimaSelectedPersonaIndex])

        pTempData.IsHoldingPersona = false

        if storage.PersonaActiveStatus == mod.Anima.PersonaActiveStatus.DISSOCIATIVE then
            storage.PersonaActiveStatus = mod.Anima.PersonaActiveStatus.DISSOCIATIVE_USED
        end

        return { Discharge = true }
    else
        pTempData.IsHoldingPersona = true
    end

    return { Discharge = false }
end, constants.Items.Persona)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PLAYER_GET_ACTIVE_MAX_CHARGE, function(_, _, player)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData

    local storage = pData.AnimaCurrentStorage

    if storage.CurrentPersona ~= mod.Anima.AnimaPersonas.NONE then
        return 0
    end
end, constants.Items.Persona)

---@param player EntityPlayer
---@param activeSlot ActiveSlot
mod:AddCallback(ModCallbacks.MC_PRE_PLAYERHUD_RENDER_ACTIVE_ITEM, function(_, player, activeSlot)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData

    local storage = pData.AnimaCurrentStorage

    if player:GetActiveItem(activeSlot) ~= constants.Items.Persona then
        return
    end

    local offsetX = 0
    if storage.PersonaActiveStatus > 0 then
        offsetX = 64
    elseif storage.CurrentPersona ~= mod.Anima.AnimaPersonas.NONE then
        offsetX = 32
    end

    return { CropOffset = Vector(offsetX, 0) }
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, function(_, collectible, charge, firstTime, slot, vardata, player)
    if player:GetPlayerType() ~= constants.Players.Anima and player:GetPlayerType() ~= constants.Players.TaintedAnima then
        return
    end

    local storage = mod.Anima.GetAnimaStorage(player)
    local pTempData = mod:GetData(player)

    --[[ local missingPersona = true
    for i = 0, 2 do
        if player:GetActiveItem(i) == constants.Items.Persona then
            missingPersona = false
            break
        end
    end

    if missingPersona then
        if storage.CurrentPersona ~= mod.Anima.AnimaPersonas.NONE then
            mod.Anima.RemovePersona(player)
            if storage.PersonaActiveStatus == mod.Anima.PersonaActiveStatus.NORMAL then
                storage.PersonaActiveStatus = mod.Anima.PersonaActiveStatus.DISSOCIATIVE
                pTempData.AnimaSelectedPersonaIndex = 1
            end
        end
    end ]]

    --personas stats addition
    if firstTime then
        if storage.CurrentPersona == mod.Anima.AnimaPersonas.EDEN then
            local collectConfig = mod.ItemConfig:GetCollectible(collectible)
            local itemQuality = collectConfig.Quality
            local cacheFlag = 0
            if itemQuality >= 1 then
                for i = 1, itemQuality do
                    cacheFlag = mod.Anima.IncreaseEdenPersonaStat(player)
                    player:AddCacheFlags(cacheFlag)
                end

                player:EvaluateItems()
            end
        elseif storage.CurrentPersona == mod.Anima.AnimaPersonas.APOLLYON then
            local stats = mod.Anima.StatModifiers
            utils:ShuffleTable(stats, player:GetCollectibleRNG(constants.Items.Persona))

            stats[1].Set(player, 1)
            stats[2].Set(player, 1)

            player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_FIREDELAY | CacheFlag.CACHE_SHOTSPEED | CacheFlag.CACHE_RANGE | CacheFlag.CACHE_SPEED | CacheFlag.CACHE_LUCK, true)
        end
    end
end)


--[[ local isCurseMistRoom = false

---@param targetRoom integer
---@param dimension Dimension
mod:AddCallback(ModCallbacks.MC_PRE_CHANGE_ROOM, function(_, targetRoom, dimension)
    local level = game:GetLevel()

    isCurseMistRoom = utils:HasBit(level:GetRoomByIdx(targetRoom, dimension).Flags, RoomDescriptor.FLAG_CURSED_MIST)
end)

---@param itemConfig ItemConfigItem
---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_REMOVE_COSTUME, function(_, itemConfig, player)
    if player:GetPlayerType() ~= animaID then
        return
    end

    local storage = mod.Anima.GetAnimaStorage(player)
    local room = game:GetRoom()


    print(itemConfig.Type, itemConfig.ID, player:HasCurseMistEffect())

    if itemConfig.Type == ItemType.ITEM_NULL
    and storage.CurrentCostumeID ~= NullItemID.ID_NULL
    and itemConfig.ID == storage.CurrentCostumeID
    and isCurseMistRoom then
        return true
    end
end) ]]

---@param player EntityPlayer
---@param useFlags UseFlag
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, function(_, _, _, player, useFlags)
    if utils:HasBit(useFlags, UseFlag.USE_CARBATTERY) then
        return
    end

    if player:GetPlayerType() == animaID or player:GetPlayerType() == tAnimaID then
        mod.Anima.RemovePersona(player, true)

        if player:HasCollectible(constants.Items.Persona) then
            player:RemoveCollectible(constants.Items.Persona)
        end
    end
end, CollectibleType.COLLECTIBLE_CLICKER)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_REVIVE, function(_, player)
    local wasAnima = (player:GetPlayerType() == animaID or player:GetPlayerType() == tAnimaID)

    Isaac.CreateTimer(function()
            if wasAnima and (player:GetPlayerType() ~= animaID and player:GetPlayerType() ~= tAnimaID) then
                mod.Anima.RemovePersona(player, true)

                if player:HasCollectible(constants.Items.Persona) then
                    player:RemoveCollectible(constants.Items.Persona)
                end
            end
        end,
        1, 1, false)
end)

--prevent active/pocket item swap while we are selecting persona
---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_POCKET_ITEMS_SWAP, function(_, player)
    local pTempData = mod:GetData(player)

    if pTempData.IsHoldingPersona then
        return true
    end
end)

--#endregion

--#region Personas functionality

---@param pickup EntityPickup
function mod:HandlePickupInit(pickup)
    local level = game:GetLevel()
    local room = game:GetRoom()
    if not room:IsFirstVisit() or not pickup:CanReroll() or level:GetDimension() == Dimension.DEATH_CERTIFICATE or utils:HasBit(mod.ItemConfig:GetCollectible(pickup.SubType).Tags, ItemConfig.TAG_QUEST) then
        return
    end

    local animaPlayers = utils:CombineTables(utils:GetPlayersByType(animaID), utils:GetPlayersByType(tAnimaID))

    if #animaPlayers > 0 then
        for _, anima in pairs(animaPlayers) do
            local pData = mod.SaveManager.GetRunSave(anima) ---@type AnimaPlayerData
            if pData.AnimaCurrentStorage.CurrentPersona == mod.Anima.AnimaPersonas.ISAAC then
                local rng = pickup:GetDropRNG()

                if #pickup:GetCollectibleCycle() == 0 and rng:RandomInt(2) == 0 then
                    pickup:TryInitOptionCycle(1)
                end

                break
            end
        end
    end
end

---@param player EntityPlayer
---@param cacheFlag CacheFlag
function mod:HandleCacheStats(player, cacheFlag)
    if player:GetPlayerType() ~= constants.Players.Anima and player:GetPlayerType() ~= constants.Players.TaintedAnima then
        return
    end

    local effects = player:GetEffects()
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local pTempData = mod:GetData(player)

    local storage = pData.AnimaCurrentStorage

    if utils:HasBit(cacheFlag, CacheFlag.CACHE_SPEED) then
        if not player:HasCurseMistEffect() and not player:HasCollectible(constants.Items.Persona) and not player:HasCollectible(constants.Items.DualRole) then
            player.MoveSpeed = player.MoveSpeed - .5
        end

        if storage.CurrentPersona == mod.Anima.AnimaPersonas.MAGDALENE then
            player.MoveSpeed = player.MoveSpeed - .2
        elseif storage.CurrentPersona == mod.Anima.AnimaPersonas.EVE then
            player.MoveSpeed = player.MoveSpeed + .3
        elseif storage.CurrentPersona == mod.Anima.AnimaPersonas.SAMSON then
            player.MoveSpeed = player.MoveSpeed + .5
        elseif storage.CurrentPersona == mod.Anima.AnimaPersonas.EDEN then
            player.MoveSpeed = player.MoveSpeed + storage.EdenPersonaStats[5]
        end
    end

    if utils:HasBit(cacheFlag, CacheFlag.CACHE_FLYING) then
        if effects:HasNullEffect(constants.NullItems.PersonaLazarusPostRevive) then
            player.CanFly = true
        end
    end

    if utils:HasBit(cacheFlag, CacheFlag.CACHE_FAMILIARS) then

    end

    if utils:HasBit(cacheFlag, CacheFlag.CACHE_LUCK) then
        if storage.CurrentPersona == mod.Anima.AnimaPersonas.CAIN then
            player.Luck = player.Luck + 2
        elseif storage.CurrentPersona == mod.Anima.AnimaPersonas.EDEN then
            player.Luck = player.Luck + storage.EdenPersonaStats[6]
        end
    end

    if utils:HasBit(cacheFlag, CacheFlag.CACHE_RANGE) then
        if storage.CurrentPersona == mod.Anima.AnimaPersonas.EDEN then
            player.TearRange = player.TearRange + storage.EdenPersonaStats[4]
        end
    end

    if utils:HasBit(cacheFlag, CacheFlag.CACHE_SHOTSPEED) then
        if storage.CurrentPersona == mod.Anima.AnimaPersonas.EDEN then
            player.TearRange = player.TearRange + storage.EdenPersonaStats[5]
        end
    end
end

---@param player EntityPlayer
---@param evaluateFlags EvaluateStatStage
---@param currentValue number
function mod:HandleEvaluateStats(player, evaluateFlags, currentValue)
    if player:GetPlayerType() ~= constants.Players.Anima and player:GetPlayerType() ~= constants.Players.TaintedAnima then
        return
    end

    local effects = player:GetEffects()
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local pTempData = mod:GetData(player)

    local storage = pData.AnimaCurrentStorage

    if evaluateFlags == EvaluateStatStage.TEARS_UP then
        if storage.CurrentPersona == mod.Anima.AnimaPersonas.MAGDALENE then
            return currentValue + .22
        end
    end

    if evaluateFlags == EvaluateStatStage.FLAT_TEARS then
        if not player:HasCurseMistEffect() and not player:HasCollectible(constants.Items.Persona) and not player:HasCollectible(constants.Items.DualRole) then
            return currentValue * .5
        end

        if storage.CurrentPersona == mod.Anima.AnimaPersonas.ISAAC then
            return currentValue * 1.15
        elseif storage.CurrentPersona == mod.Anima.AnimaPersonas.EDEN then
            return currentValue + storage.EdenPersonaStats[2]
        end
    end

    if evaluateFlags == EvaluateStatStage.DAMAGE_UP then
        if storage.CurrentPersona == mod.Anima.AnimaPersonas.EVE then
            return currentValue + .51
        elseif storage.CurrentPersona == mod.Anima.AnimaPersonas.SAMSON then
            local bloodyLustCount = player:GetBloodLustCounter()

            if not player:HasCollectible(CollectibleType.COLLECTIBLE_BLOODY_LUST) and bloodyLustCount > 0 then
                local dmgBonus = math.min(bloodyLustCount, 6)
                return dmgBonus * 0.1 * dmgBonus + dmgBonus * 0.4 + currentValue
            end
        elseif storage.CurrentPersona == mod.Anima.AnimaPersonas.EDEN then
            return currentValue + storage.EdenPersonaStats[1]
        end
    end

    if evaluateFlags == EvaluateStatStage.FLAT_DAMAGE then
        if not player:HasCurseMistEffect() and not player:HasCollectible(constants.Items.Persona) and not player:HasCollectible(constants.Items.DualRole) then
            return currentValue * .5
        end

        if effects:HasNullEffect(constants.NullItems.PersonaLazarusPostRevive) then
            return currentValue * 1.35
        end

        if storage.CurrentPersona == mod.Anima.AnimaPersonas.JUDAS then
            return currentValue * 1.2
        elseif storage.CurrentPersona == mod.Anima.AnimaPersonas.SAMSON then
            return currentValue + .5
        end
    end
end

---@param ent Entity
---@param killSource EntityRef
function mod:HandleEnemyKills(ent, killSource)
    if ent.Type < 10 or ent.Type > 999 then
        return
    end

    local player = utils:GetPlayerFromEntityRef(killSource)

    if player then
        local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
        local pTempData = mod:GetData(player)

        local storage = pData.AnimaCurrentStorage
        if storage.CurrentPersona == mod.Anima.AnimaPersonas.EVE then
            if pTempData.AnimaExtraTempData.EveKillBirds < 12 then
                local roll = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_DEAD_BIRD):RandomInt(3)
                if roll == 0 then
                    local bird = Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.DEAD_BIRD, 0, player.Position, Vector.Zero, player):ToFamiliar() --[[@as EntityFamiliar]]

                    pTempData.AnimaExtraTempData.EveKillBirds = math.min(pTempData.AnimaExtraTempData.EveKillBirds + 1, 12)
                end
            end
        elseif storage.CurrentPersona == mod.Anima.AnimaPersonas.BETHANY then
            local itemRNG = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES)
            local roll = itemRNG:RandomInt(3)
            if roll == 0 then
                local wispPick = itemRNG:RandomInt(1, #mod.ItemConfig:GetCollectibles())
                player:AddWisp(wispPick, player.Position, true)
            end
        end
    end
end

---@param player EntityPlayer
local function UseBoxOfFriends(player)
    if not player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) then
        player:UseActiveItem(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS, UseFlag.USE_NOANIM)
    end
end

---@param player EntityPlayer
function mod:HandlePlayerNewRoom(player)
    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local pTempData = mod:GetData(player)
    local storage = pData.AnimaCurrentStorage

    local level = game:GetLevel()
    local room = game:GetRoom()

    local lostPersona = true

    --remove current persona if we can't find item on current floor
    if not player:HasCurseMistEffect() and storage.CurrentPersona ~= mod.Anima.AnimaPersonas.NONE then
        local has = player:HasCollectible(constants.Items.Persona)
        if not has then
            if player:HasCollectible(constants.Items.DualRole) then
                lostPersona = false
            else
                local maxDimension = level:HasMirrorDimension() and 1 or 0
                for i = maxDimension, 0, -1 do
                    for j = GridRooms.ROOM_LIL_PORTAL, 169 do
                        if not (j == GridRooms.ROOM_DEBUG_IDX
                                or j == GridRooms.ROOM_BLUE_ROOM_IDX
                                or j == GridRooms.ROOM_ANGEL_SHOP_IDX
                                or j == GridRooms.ROOM_DEATHMATCH) then
                            local roomDesc = level:GetRoomByIdx(j, i)

                            if roomDesc and roomDesc.Data then
                                local personas = #roomDesc:GetEntitiesSaveState():GetByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, constants.Items.Persona)

                                if personas > 0 then
                                    lostPersona = false
                                    break
                                end
                            end

                            --if we found on mirror dimension
                            if not lostPersona then
                                break
                            end
                        end
                    end
                end
            end
        end
        if lostPersona and (
            not has
            or player:GetPlayerType() == constants.Players.TaintedAnima
        ) then
            mod.Anima.RemovePersonaFromPool(player)
        end
    end

    if storage.CurrentPersona == mod.Anima.AnimaPersonas.EVE then
        player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_DEAD_BIRD, false)
        player:AddCacheFlags(CacheFlag.CACHE_FAMILIARS, true)
    elseif storage.CurrentPersona == mod.Anima.AnimaPersonas.LILITH then
        if (level:GetStage() == LevelStage.STAGE8 and room:GetType() == RoomType.ROOM_DUNGEON or room:GetType() == RoomType.ROOM_BOSS) and not room:IsClear() then
            UseBoxOfFriends(player)
        end
    end

    if player:GetPlayerType() ~= constants.Players.TaintedAnima then
        pTempData.IsHoldingPersona = false
    end
end

---@param pickup EntityPlayer
---@param collider Entity
---@param low boolean
function mod:HandlePickupCollision(pickup, collider, low)
    local player = collider:ToPlayer()
    if not player or player:GetPlayerType() ~= constants.Players.Anima_Decoy then
        return
    end

    if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then
        return { SkipCollisionEffects = true }
    end
end

---@param ent Entity
function mod:HandleEntityRemove(ent)
    local player = ent:ToPlayer()

    if not player or player:GetPlayerType() ~= constants.Players.Anima_Decoy then
        return
    end

    local parent = player.Parent
    if parent and parent:ToPlayer() then
        local parentData = mod.SaveManager.GetRunSave(parent) ---@type AnimaPlayerData
        local animaStorage = parentData.AnimaCurrentStorage

        if not animaStorage.LostDecoyPlayer then
            animaStorage.LostDecoyPlayer = true
        end
    end
end

---@param spawnPos Vector
function mod:HandlePickupDrops(_, spawnPos)
    local room = game:GetRoom()
    local animaPlayers = utils:CombineTables(utils:GetPlayersByType(animaID), utils:GetPlayersByType(tAnimaID))

    if room:GetType() == RoomType.ROOM_BOSS or room:GetType() == RoomType.ROOM_BOSSRUSH then
        return
    end

    if #animaPlayers > 0 then
        for _, anima in pairs(animaPlayers) do
            local pData = mod.SaveManager.GetRunSave(anima) ---@type AnimaPlayerData
            if pData.AnimaCurrentStorage.CurrentPersona == mod.Anima.AnimaPersonas.MAGDALENE then
                local rng = anima:GetCollectibleRNG(constants.Items.Persona)
                local roll = rng:RandomInt(4)
                if roll == 0 then
                    local pos = room:FindFreePickupSpawnPosition(spawnPos)

                    local seed = rng:Next()

                    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, pos, Vector.Zero, nil, 0, seed)
                end

                break
            end
        end
    end
end

---@param fam EntityFamiliar
---@param currentMult number
---@param player EntityPlayer
function mod:HandleFamiliarMultiplier(fam, currentMult, player)
    if player:GetPlayerType() ~= constants.Players.Anima and player:GetPlayerType() ~= constants.Players.TaintedAnima then
        return
    end

    local pData = mod.SaveManager.GetRunSave(player) ---@type AnimaPlayerData
    local animaStorage = pData.AnimaCurrentStorage

    if animaStorage.CurrentPersona == mod.Anima.AnimaPersonas.LILITH then
        return currentMult + 1
    end
end

function mod:HandleDealChances(currentChance)
    local level = game:GetLevel()
    local room, roomDesc = level:GetCurrentRoom(), level:GetCurrentRoomDesc()
    local animaPlayers = utils:CombineTables(utils:GetPlayersByType(animaID), utils:GetPlayersByType(tAnimaID))

    for _, anima in pairs(animaPlayers) do
        local pData = mod.SaveManager.GetRunSave(anima) ---@type AnimaPlayerData
        if pData.AnimaCurrentStorage.CurrentPersona == mod.Anima.AnimaPersonas.JUDAS then
            local chance = currentChance + .66
            if roomDesc.ListIndex == level:GetLastBossRoomListIndex() and room:GetRedHeartDamage() then
                return chance + .35
            end

            if level:GetStateFlag(LevelStateFlag.STATE_REDHEART_DAMAGED) then
                return chance + .25
            end

            return chance
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.HandlePickupInit, PickupVariant.PICKUP_COLLECTIBLE)
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.HandleCacheStats)
mod:AddPriorityCallback(ModCallbacks.MC_EVALUATE_STAT, CallbackPriority.EARLY, mod.HandleEvaluateStats)
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, mod.HandleEnemyKills)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_NEW_ROOM_TEMP_EFFECTS, mod.HandlePlayerNewRoom)
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, mod.HandlePickupCollision)
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, mod.HandleEntityRemove)
mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, mod.HandlePickupDrops)
mod:AddCallback(ModCallbacks.MC_EVALUATE_FAMILIAR_MULTIPLIER, mod.HandleFamiliarMultiplier)
mod:AddCallback(ModCallbacks.MC_PRE_DEVIL_APPLY_ITEMS, mod.HandleDealChances)

--lazarus persona revive
---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_TRIGGER_PLAYER_DEATH, function(_, player)
    if player:GetPlayerType() ~= constants.Players.Anima and player:GetPlayerType() ~= constants.Players.TaintedAnima then
        return
    end

    local storage = mod.Anima.GetAnimaStorage(player)
    local effects = player:GetEffects()

    if effects:HasNullEffect(constants.NullItems.PersonaLazarusRevival) then
        effects:RemoveNullEffect(constants.NullItems.PersonaLazarusRevival, -1)

        effects:AddNullEffect(constants.NullItems.PersonaLazarusPostRevive)

        player:Revive()

        player:SetMinDamageCooldown(120)
        player:AddHearts(1)

        storage.LazarusUsedRevive = true
    end
end)

local function LilithPersonaChallengeWaves()
    local animaPlayers = utils:CombineTables(utils:GetPlayersByType(animaID), utils:GetPlayersByType(tAnimaID))
    if #animaPlayers > 0 then
        for _, anima in pairs(animaPlayers) do
            local pData = mod.SaveManager.GetRunSave(anima) ---@type AnimaPlayerData
            if pData.AnimaCurrentStorage.CurrentPersona == mod.Anima.AnimaPersonas.LILITH then
                UseBoxOfFriends(anima)
            end
        end
    end
end

--lilith persona using box of frineds in challenge waves
mod:AddCallback(ModCallbacks.MC_POST_START_AMBUSH_WAVE, function()
    LilithPersonaChallengeWaves()
end)

mod:AddCallback(ModCallbacks.MC_POST_START_GREED_WAVE, function()
    LilithPersonaChallengeWaves()
end)

--#endregion

--#region ImGui
--comment for public release

---@param elementId string
---@param createFunc function
local function createElement(elementId, createFunc, ...)
    if imgui.ElementExists(elementId) then
        imgui.RemoveElement(elementId)
    end

    createFunc(...)
end

if DEBUG then
    if not imgui.ElementExists("AnimaDebugMenu") then
        imgui.CreateMenu("AnimaDebugMenu", "\u{f005} Anima Debug Menu")
    end

    createElement(
        "AnimaDebugItemSettings",
        imgui.AddElement,
        "AnimaDebugMenu", "AnimaDebugItemSettings", ImGuiElement.MenuItem, "\u{f013} Settings"
    )

    imgui.CreateWindow("AnimaDebugMenuSettings", "Anima Debug Menu")
    imgui.LinkWindowToElement("AnimaDebugMenuSettings", "AnimaDebugItemSettings")

    local charNames = { "None" }
    for k, config in ipairs(mod.Anima.AnimaPersonaConfig) do
        charNames[#charNames + 1] = config.Name
    end

    createElement(
        "AnimaDebugMenuCharacters",
        imgui.AddRadioButtons,
        "AnimaDebugMenuSettings", "AnimaDebugMenuCharacters",
        function(index)
            local player = Isaac.GetPlayer()

            if not player or player:GetPlayerType() ~= animaID then
                return
            end

            if index > 0 then
                mod.Anima.ChangePersona(player, mod.Anima.AnimaPersonaConfig[index].ID)
            else
                mod.Anima.RemovePersona(player)
            end
        end,
        charNames, 0, false
    )
end

--#endregion
