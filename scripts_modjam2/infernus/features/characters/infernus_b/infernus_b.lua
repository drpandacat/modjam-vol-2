--introduce item system from new deadlock mode, and use them as alternative of items?
--copy abilities
local Libs = include("scripts_modjam2.infernus.features.characters.infernus_b.libs")

local mod = DeadlockMod
local itemConfig = Isaac.GetItemConfig()
local modChars = mod.playerType
local modItems = mod.CollectibleType
local modNullItems = mod.NullID

---@param player EntityPlayer
---Mod did not originally account for callbacks running before player init (where data is populated),
---other characters in the pack trigger some of these so yeah we gotta do this - K
local function GetDataSafe(player)
    ---@type InfernusAltData
    local data = player:GetData()
    data.InfernusAbilityIDs = data.InfernusAbilityIDs or {}
    return data
end

local StatsCache = CacheFlag.CACHE_DAMAGE |
    CacheFlag.CACHE_SPEED |
    CacheFlag.CACHE_LUCK |
    CacheFlag.CACHE_FIREDELAY |
    CacheFlag.CACHE_RANGE |
    CacheFlag.CACHE_SHOTSPEED |
    CacheFlag.CACHE_TEARFLAG

---@enum InfernusAbilityId
local InfernusAbilityId = {
    SPEED_UP          = 1,
    DAMAGE_KING       = 2,
    TEARS_UP          = 3,
    RAPID_FIRE        = 4,
    HOMING            = 5,
    SLOWING_BULLETS   = 6,
    HAUNTING_SHOT     = 7,
    GLASS_CANON       = 8,
    TESLA_BULLETS     = 9,
    TOXIC_BULLETS     = 10,
    SAND_TIME         = 11,
    COLOSSUS          = 12,
    UNCLENCHED_THROAT = 13,
}

---@type table<number, string>
local InfernusNames = {
    [InfernusAbilityId.SPEED_UP]          = "SpeedUp",
    [InfernusAbilityId.DAMAGE_KING]       = "Monster Rounds",
    [InfernusAbilityId.TEARS_UP]          = "TearsUp",
    [InfernusAbilityId.RAPID_FIRE]        = "Rapid Rounds",
    [InfernusAbilityId.HOMING]            = "Homing Justice",
    [InfernusAbilityId.SLOWING_BULLETS]   = "Slowing Bullets",
    [InfernusAbilityId.HAUNTING_SHOT]     = "Haunting Shot",
    [InfernusAbilityId.GLASS_CANON]       = "Glass Canon",
    [InfernusAbilityId.TESLA_BULLETS]     = "Tesla Bullets",
    [InfernusAbilityId.TOXIC_BULLETS]     = "Toxic Bullets",
    [InfernusAbilityId.SAND_TIME]         = "Slowing Hex",
    [InfernusAbilityId.COLOSSUS]          = "Colossus",
    [InfernusAbilityId.UNCLENCHED_THROAT] = "Unclenched Throat",
    -- Add matching entries for new IDs
}

-- Stats + optional Function registry
---@class InfernusItemDesc
---@field Description? string
---@field Stats table<string, number>?  -- {speed = 0.3, damage_mult = 1.2, ...}
---@field TearFlags? TearFlags
---@field TriggerFunction? fun(player : EntityPlayer)

---@type table<number, InfernusItemDesc>
local InfernusItems = {
    [InfernusAbilityId.SPEED_UP] = {
        Stats = {
            speed = 0.3,
            damage_mult = 1.2,
        },
        Description = "Grants a swift boost to movement and amplifies your damage output",
    },
    [InfernusAbilityId.DAMAGE_KING] = {
        Stats = {
            damage = 2.0,
            luck = -1.0,
        },
        Description = "Empowers your tears with raw power, but at the cost of fortune",
    },
    [InfernusAbilityId.TEARS_UP] = {
        Stats = {
            maxFireDelay = 2.0,
            range = 1.5,
        },
        Description = "Increases fire rate and extends tear travel distance",
    },
    [InfernusAbilityId.RAPID_FIRE] = {
        Stats = {
            maxFireDelay = 16,
            damage_mult = .25,
        },
        Description = "Tastes like a milk...",
    },
    [InfernusAbilityId.HOMING] = {
        Stats = {
            range = 2.25,
        },
        TearFlags = TearFlags.TEAR_HOMING,
        Description = "Gains homing effect to your tears",
    },
    [InfernusAbilityId.SLOWING_BULLETS] = {
        Description = "Gains slowing effect to your tears",
        TearFlags = TearFlags.TEAR_SLOW,
    },
    [InfernusAbilityId.HAUNTING_SHOT] = {
        Description = "Gains fear effect to your tears",
        TearFlags = TearFlags.TEAR_FEAR,
    },
    [InfernusAbilityId.GLASS_CANON] = {
        TriggerFunction = function(player)
            local health = player:GetHearts()
            player:AddHearts(-health + 1)
            player:AddSoulHearts((-player:GetSoulHearts()))
        end,
        Stats = {
            damage_mult = 2.8,
        },
        Description = "Enlarges your power, but takes most of your spirit",
    },
    [InfernusAbilityId.TESLA_BULLETS] = {

        TearFlags = TearFlags.TEAR_JACOBS,
        Description = "Gains shocking effect to your tears",
    },
    [InfernusAbilityId.TOXIC_BULLETS] = {

        TearFlags = TearFlags.TEAR_POISON,
        Description = "Gains poison effect to your tears",
    },
    [InfernusAbilityId.SAND_TIME] = {
        Description = "Slows every foe in the room",
    },
    [InfernusAbilityId.COLOSSUS] = {
        Description = "Huge Growth",
    },
    [InfernusAbilityId.UNCLENCHED_THROAT] = {
        Description = "Unleash your mighty roar",
    },
}

---@param player EntityPlayer
local function isInfernusAlt(player)
    return player:GetPlayerType() == modChars.INFERNUS_B
end

-- Helper: Get name from ID
---@param abilityId InfernusAbilityId
local function GetInfernusAbilityName(abilityId)
    return InfernusNames[abilityId] or ("Unknown Ability #" .. tostring(abilityId))
end

-- Helper to generate dynamic stats description
---@param abilityId InfernusAbilityId
---@return string
local function GetAbilityStatsDesc(abilityId)
    local stats = InfernusItems[abilityId].Stats or {}
    local parts = {}
    for stat, value in pairs(stats) do
        local displayName = stat:gsub("_mult$", " multiplier"):gsub("^%l", string.upper)
        if stat:match("_mult$") then
            table.insert(parts, displayName .. " x" .. string.format("%.2f", value))
        else
            local sign = value >= 0 and "+" or ""
            table.insert(parts, displayName .. " " .. sign .. string.format("%.2f", value))
        end
    end
    return table.concat(parts, ", ")
end

-- Helper: Check if player has a specific Infernus ability ID
---@param player EntityPlayer
---@param abilityId InfernusAbilityId
local function PlayerHasInfernusAbility(player, abilityId)
    local data = GetDataSafe(player)
    local ids = data.InfernusAbilityIDs
    return Libs:TableHasElement(ids, abilityId)
end

-- Add an ability by ID
---@param player  EntityPlayer
---@param abilityId InfernusAbilityId
local function AddInfernusAbility(player, abilityId)
    local abilityDesc = InfernusItems[abilityId]
    if not InfernusItems[abilityId] then
        --print("Warning: Invalid Infernus Ability ID " .. tostring(abilityId))
        return
    end

    local data = GetDataSafe(player)
    data.InfernusAbilityIDs = data.InfernusAbilityIDs
    if Libs:TableHasElement(data.InfernusAbilityIDs, abilityId) then
        return -- already has it
    end

    data.InfernusAbilityIDs[#data.InfernusAbilityIDs + 1] = abilityId

    -- Force cache re-evaluation for stats
    player:AddCacheFlags(StatsCache, true)

    if abilityDesc.TriggerFunction then
        abilityDesc.TriggerFunction(player)
    end
end

---@param player EntityPlayer
local function CleanInfernusAbilities(player)
    local data = GetDataSafe(player)

    data.InfernusAbilityIDs = {}
    player:AddCacheFlags(StatsCache, true)
end

---@param player EntityPlayer
---@param rng RNG
---@return integer[]
local function GetRandomNewAbilities(player, rng)
    local available = {}
    for abilityId in pairs(InfernusItems) do
        if not PlayerHasInfernusAbility(player, abilityId) then
            table.insert(available, abilityId)
        end
    end

    local selected = {}
    for i = 1, 3 do
        if #available == 0 then break end

        local idx = rng:RandomInt(#available) + 1
        table.insert(selected, available[idx])
        table.remove(available, idx)
    end

    return selected
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
    local pData = GetDataSafe(player)

    --[[
    pData.InfernusAltPoints = 0
    pData.InfernusAltAbilityPoints = { 0, 0, 0, 0 }

    pData.InfernusAltHeatPoints = 0
    ]]
    pData.InfernusAltSelectingAbility = true

    pData.InfernusAbilityIDs = {}
    pData.InfernusAltSelectedIndex = 1
    pData.InfernusRemainingAbilities = 3


    local rng = RNG(mod.game:GetSeeds():GetStageSeed(Libs:GetAdjustedLevelStage()), 21)
    pData.InfernusSelectionOptions = GetRandomNewAbilities(player, rng)
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    if not isInfernusAlt(player) then
        return
    end

    local pData = GetDataSafe(player)



    if pData.InfernusAltSelectingAbility then
        local options = pData.InfernusSelectionOptions
        local numOptions = #options

        local selectedId = options[pData.InfernusAltSelectedIndex]
        if Input.IsActionTriggered(ButtonAction.ACTION_MENURIGHT, player.ControllerIndex) then
            pData.InfernusAltSelectedIndex = pData.InfernusAltSelectedIndex + 1
            if pData.InfernusAltSelectedIndex > numOptions then
                pData.InfernusAltSelectedIndex = 1
            end
        elseif Input.IsActionTriggered(ButtonAction.ACTION_MENULEFT, player.ControllerIndex) then
            pData.InfernusAltSelectedIndex = pData.InfernusAltSelectedIndex - 1
            if pData.InfernusAltSelectedIndex < 1 then
                pData.InfernusAltSelectedIndex = numOptions
            end
        elseif Input.IsActionTriggered(ButtonAction.ACTION_MENUCONFIRM, player.ControllerIndex) then
            local selectedId = options[pData.InfernusAltSelectedIndex]
            AddInfernusAbility(player, selectedId)

            pData.InfernusSelectionOptions = {}

            pData.InfernusAltSelectedIndex = 1
            pData.InfernusRemainingAbilities = pData.InfernusRemainingAbilities - 1

            if pData.InfernusRemainingAbilities > 0 then
                local rng = RNG(mod.game:GetSeeds():GetStageSeed(Libs:GetAdjustedLevelStage() + pData.InfernusRemainingAbilities), 33)
                pData.InfernusSelectionOptions = GetRandomNewAbilities(player, rng)
            end
        end

        if pData.InfernusRemainingAbilities <= 0 then
            pData.InfernusAltSelectingAbility = false
            -- Optional: clear selection data
            pData.InfernusSelectionOptions = {}
        end

        player:SetCanShoot(false)
    else
        player:SetCanShoot(true)
    end

    --[[
    if pData.InfernusAltHeatPoints >= 50 then
        player:Kill()
    end

    pData.InfernusAltHeatPoints = pData.InfernusAltHeatPoints + .1
    ]]
end)

---@param player EntityPlayer
---@param isPostLevelFinished boolean
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_NEW_LEVEL, function(_, player, _, isPostLevelFinished)
    if not isInfernusAlt(player) then
        return
    end

    local pData = GetDataSafe(player)
    if isPostLevelFinished then
        CleanInfernusAbilities(player)
        pData.InfernusSelectionOptions = {}
        pData.InfernusRemainingAbilities = 3
        pData.InfernusAltSelectingAbility = true

        local rng = RNG(mod.game:GetSeeds():GetStageSeed(Libs:GetAdjustedLevelStage()), 21)
        pData.InfernusSelectionOptions = GetRandomNewAbilities(player, rng)
    end
end)

local function GetScreenSize()
    local screenWidth = Isaac.GetScreenWidth()
    local screenHeight = Isaac.GetScreenHeight()

    return Vector(screenWidth, screenHeight)
end

local function GetScreenCenter()
    return GetScreenSize() / 2
end

local abilityFont = Font()
--if not abilityFont:IsLoaded() then
abilityFont:Load("font/terminus8.fnt")
--end

mod:AddCallback(ModCallbacks.MC_HUD_RENDER, function()
    local player = Isaac.GetPlayer() -- Assume primary player for global UI; adjust for multi-player if needed
    if not isInfernusAlt(player) then
        return
    end

    local pData = GetDataSafe(player)
    if not pData.InfernusAltSelectingAbility then
        return
    end

    local options = pData.InfernusSelectionOptions or {}
    local selectedIdx = pData.InfernusAltSelectedIndex


    local selectedId = options[selectedIdx]
    local name = GetInfernusAbilityName(selectedId)
    local baseDesc = InfernusItems[selectedId].Description or "No description available."
    local statsDesc = GetAbilityStatsDesc(selectedId)

    -- Dynamic screen center
    local center = GetScreenCenter()
    local centerX = center.X
    local centerY = center.Y - 20


    local remainingText = "Remaining choices: " .. tostring(pData.InfernusRemainingAbilities)
    local remainingScale = 1.0
    local remainingY = centerY - 55
    local remainingWidth = abilityFont:GetStringWidth(remainingText) * remainingScale
    local remainingX = centerX - remainingWidth / 2
    abilityFont:DrawStringScaled(remainingText, remainingX, remainingY, remainingScale, remainingScale, KColor(1, 0.8, 0.2, 1), 0, false)

    local titleScale = 1.2
    local titleWidth = abilityFont:GetStringWidth(name) * titleScale
    local titleX = centerX - titleWidth / 2
    abilityFont:DrawStringScaled(name, titleX, centerY - 40, titleScale, titleScale, KColor(1, 1, 1, 1), 0, false)


    local descScale = 1.0
    local descBoxWidth = 500
    local descY = centerY - 10
    abilityFont:DrawStringScaled(baseDesc, centerX - descBoxWidth / 2, descY, descScale, descScale, KColor(0.9, 0.9, 0.9, 1), descBoxWidth, true)
    if statsDesc ~= "" then
        local statsY = descY + 60
        local statsLines = {}
        for part in string.gmatch(statsDesc, "[^,]+") do
            local trimmed = part:gsub("^%s+", ""):gsub("%s+$", "")
            if trimmed ~= "" then
                table.insert(statsLines, "+" .. trimmed)
            end
        end

        for idx, line in ipairs(statsLines) do
            local lineScale = 1.0
            local lineWidth = abilityFont:GetStringWidth(line) * lineScale
            local lineX = centerX - lineWidth / 2
            abilityFont:DrawStringScaled(line, lineX, statsY + (idx - 1) * 30, lineScale, lineScale, KColor(0, 1, 0.2, 1), 0, false)
        end
    end
end)

---@param abilityIds InfernusItemDesc
---@param statKey string
local function AccumulateStat(abilityIds, statKey)
    local isMult = statKey:match("_mult$") ~= nil
    local total = isMult and 1.0 or 0.0

    for _, abilityId in ipairs(abilityIds) do
        local item = InfernusItems[abilityId]
        if item and item.Stats and item.Stats[statKey] then
            local value = item.Stats[statKey]
            if isMult then
                total = total * value
            else
                total = total + value
            end
        end
    end
    return total
end

-- Core stats evaluation callback (only touches Stats field)
---@param player EntityPlayer
---@param cacheFlag CacheFlag
local function OnEvaluateCache(_, player, cacheFlag)
    if not isInfernusAlt(player) then
        return
    end

    local data = GetDataSafe(player)
    local abilityIds = data.InfernusAbilityIDs

    if cacheFlag & CacheFlag.CACHE_SPEED > 0 then
        local speedBonus = AccumulateStat(abilityIds, "speed")
        player.MoveSpeed = player.MoveSpeed + speedBonus + .3
    end

    if cacheFlag & CacheFlag.CACHE_DAMAGE > 0 then
        local damageAdd = AccumulateStat(abilityIds, "damage")
        local damageMult = AccumulateStat(abilityIds, "damage_mult")
        player.Damage = (player.Damage + damageAdd) * damageMult
    end

    if cacheFlag & CacheFlag.CACHE_LUCK > 0 then
        local luckBonus = AccumulateStat(abilityIds, "luck")
        player.Luck = player.Luck + luckBonus
    end

    if cacheFlag & CacheFlag.CACHE_RANGE > 0 then
        local rangeBonus = AccumulateStat(abilityIds, "range")
        player.TearRange = player.TearRange + rangeBonus * 40
    end

    if cacheFlag & CacheFlag.CACHE_SHOTSPEED > 0 then
        local shotSpeedBonus = AccumulateStat(abilityIds, "shotSpeed")
        player.ShotSpeed = player.ShotSpeed + shotSpeedBonus
    end

    if cacheFlag & CacheFlag.CACHE_TEARFLAG > 0 then
        local totalTearFlags = 0
        for _, abilityId in ipairs(abilityIds) do
            local item = InfernusItems[abilityId]
            if item and item.TearFlags then
                totalTearFlags = totalTearFlags | item.TearFlags
            end
        end

        player.TearFlags = player.TearFlags | totalTearFlags
    end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, OnEvaluateCache)

---@param player EntityPlayer
---@param statCache EvaluateStatStage
---@param currentValue number
local function OnStatCache(_, player, statCache, currentValue)
    if not isInfernusAlt(player) then
        return
    end

    local data = GetDataSafe(player)
    local abilityIds = data.InfernusAbilityIDs
    if statCache == EvaluateStatStage.FLAT_TEARS then
        local fireDelayBonus = AccumulateStat(abilityIds, "maxFireDelay")
        return currentValue + fireDelayBonus
    end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_STAT, OnStatCache)

--[[ ---@param player  EntityPlayer
---@param abilityId InfernusAbilityId
function TestAddAbility(player, abilityId)
    AddInfernusAbility(player, abilityId)
end ]]

---@param pick EntityPickup
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, function(_, pick)
    local collectType = pick.SubType ---@type CollectibleType
    if PlayerManager.AnyoneIsPlayerType(modChars.INFERNUS_B) and not (itemConfig:GetCollectible(collectType).Tags & ItemConfig.TAG_QUEST > 0) then
        pick:Remove()
    end
end, PickupVariant.PICKUP_COLLECTIBLE)

---@param collect CollectibleType
mod:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, function(_, collect)
    if PlayerManager.AnyoneIsPlayerType(modChars.INFERNUS_B) and not (itemConfig:GetCollectible(collect).Tags & ItemConfig.TAG_QUEST > 0) then
        return false
    end
end)

---@param isContinued boolean
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, isContinued)
    if not isContinued and PlayerManager.AnyoneIsPlayerType(modChars.INFERNUS_B) then
        mod.game:SetStateFlag(GameStateFlag.STATE_BOSSPOOL_SWITCHED, true)
    end
end)

---@param slot LevelGeneratorRoom
---@param roomconfig RoomConfigRoom
---@param seed integer
mod:AddCallback(ModCallbacks.MC_PRE_LEVEL_PLACE_ROOM, function(_, slot, roomconfig, seed)
    if mod.game:IsGreedMode() then
        return
    end

    local level = mod.game:GetLevel()
    if PlayerManager.AnyoneIsPlayerType(modChars.INFERNUS_B) and not level:HasMirrorDimension() then
        local roomType = roomconfig.Type

        if roomType == RoomType.ROOM_SHOP or
        roomType == RoomType.ROOM_TREASURE then
            local currentStageStb = Libs.GetStageID(level:GetStage(), level:GetStageType())
            local newRoom = RoomConfigHolder.GetRandomRoom(seed, true, currentStageStb, RoomType.ROOM_DEFAULT, roomconfig.Shape, 0, nil, nil, nil, roomconfig.Doors)

            if newRoom then
                return newRoom
            end
        end
    end
end)

mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
    if not PlayerManager.AnyoneIsPlayerType(modChars.INFERNUS_B) then
        return
    end

    local room = mod.game:GetRoom()
    local bossId = room:GetBossID() ---@type BossType

    if bossId == BossType.MOM or bossId == BossType.MOM_MAUSOLEUM then
        local pos = room:FindFreePickupSpawnPosition(room:GetCenterPos())

        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TROPHY, 0, pos, Vector.Zero, nil)
        return true
    end
end)

--misc abilities

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_NEW_ROOM_TEMP_EFFECTS, function(_, player)
    if not isInfernusAlt(player) then
        return
    end

    local room = mod.game:GetRoom()

    if not room:IsClear() then
        if PlayerHasInfernusAbility(player, InfernusAbilityId.SAND_TIME) then
            room:SetBrokenWatchState(1)
        end

        if PlayerHasInfernusAbility(player, InfernusAbilityId.COLOSSUS) then
            player:UseCard(Card.CARD_HUGE_GROWTH, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
        end

        if PlayerHasInfernusAbility(player, InfernusAbilityId.UNCLENCHED_THROAT) then
            player:UseActiveItem(CollectibleType.COLLECTIBLE_LARYNX, UseFlag.USE_CUSTOMVARDATA, -1, 2)
        end
    end
end)

---@param pick EntityPickup
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, function(_, pick)
    local infernus = PlayerManager.FirstPlayerByType(modChars.INFERNUS_B)
    if infernus and PlayerHasInfernusAbility(infernus, InfernusAbilityId.GLASS_CANON) then
        pick:Remove()
    end
end, PickupVariant.PICKUP_HEART)
