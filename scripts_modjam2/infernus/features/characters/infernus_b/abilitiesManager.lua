local napalm = include("scripts_modjam2.infernus.features.characters.infernus_b.napalm")
local dash = include("scripts_modjam2.infernus.features.characters.infernus_b.flameDash")
local afterburn = include("scripts_modjam2.infernus.features.characters.infernus_b.afterburn")
local explosion = include("scripts_modjam2.infernus.features.characters.infernus_b.concussiveCombustion")

--in seconds
local NAPALM_CD = 25
local LVL2_NAPALM_CD_REDUCTION = 6
local DASH_CD = 38
local LVL3_DASH_CD_REDUCTION = 15
--afterburn is a passive
local ULT_CD = 140
local LVL3_ULT_CD_REDUCTION = 20

---@param player EntityPlayer
local function handleAbilities(_, player)
    if player:GetPlayerType() ~= DeadlockMod.playerType.INFERNUS_B then return end

    local data = player:GetData()

    local effects = player:GetEffects()

    data.abilityPoints = effects:GetNullEffectNum(DeadlockMod.NullID.ABILITY_POINT)

    --we set this once!
    if not data.abilityData then
        local effectsNum1 = effects:GetNullEffectNum(DeadlockMod.NullID.InfernusAbilities.NAPALM)
        local effectsNum2 = effects:GetNullEffectNum(DeadlockMod.NullID.InfernusAbilities.FLAME_DASH)
        local effectsNum3 = effects:GetNullEffectNum(DeadlockMod.NullID.InfernusAbilities.AFTERBURN)
        local effectsNum4 = effects:GetNullEffectNum(DeadlockMod.NullID.InfernusAbilities.CONCUSSIVE_COMBUSTION)

        data.abilityData = {
            {
                key = Keyboard.KEY_1,
                path = "gfx/ui/ability_napalm.anm2",
                level = effectsNum1,
                cooldown = NAPALM_CD * 60,
                sprite = nil,

                upgrade = function(self)
                    self.level = self.level + 1
                    effects:AddNullEffect(DeadlockMod.NullID.InfernusAbilities.NAPALM)

                    if self.level == 2 then
                        self.cooldown = self.cooldown - (LVL2_NAPALM_CD_REDUCTION * 60)
                    end
                end,

                cast = function(self, player)
                    napalm:OnCast(player)
                end,
            },

            {
                key = Keyboard.KEY_2,
                path = "gfx/ui/ability_flame_dash.anm2",
                level = effectsNum2,
                cooldown = DASH_CD * 60,
                sprite = nil,

                upgrade = function(self)
                    self.level = self.level + 1
                    effects:AddNullEffect(DeadlockMod.NullID.InfernusAbilities.FLAME_DASH)

                    if self.level == 3 then
                        self.cooldown = self.cooldown - (LVL3_DASH_CD_REDUCTION * 60)
                    end
                end,

                cast = function(self, player)
                    dash:OnCast(player)
                end,
            },

            {
                key = Keyboard.KEY_3,
                path = "gfx/ui/ability_afterburn.anm2",
                level = effectsNum3,
                cooldown = 0,
                sprite = nil,

                upgrade = function(self)
                    self.level = self.level + 1
                    effects:AddNullEffect(DeadlockMod.NullID.InfernusAbilities.AFTERBURN)
                end,

                cast = function(self, player)
                    --DeadlockMod.sfx:Play(DeadlockMod.SoundID.InfernusAbilities.AFTERBURN.PROC)
                end,
            },

            {
                key = Keyboard.KEY_4,
                path = "gfx/ui/ability_concussive_combustion.anm2",
                level = effectsNum4,
                cooldown = ULT_CD * 60,
                sprite = nil,

                upgrade = function(self)
                    self.level = self.level + 1

                    if self.level == 3 then
                        self.cooldown = self.cooldown - (LVL3_ULT_CD_REDUCTION * 60)
                    end

                    effects:AddNullEffect(DeadlockMod.NullID.InfernusAbilities.CONCUSSIVE_COMBUSTION)
                end,

                cast = function(self, player)
                    explosion:OnCast(self, player)
                end,
            },
        }
    end

    data.abilityState = data.abilityState or {} --separate table for realtime cooldowns.

    for i, ability in ipairs(data.abilityData) do
        data.abilityState[i] = data.abilityState[i] or {
            timePassed = ability.cooldown,
        }
    end

    local tabHeld = Input.IsButtonPressed(Keyboard.KEY_TAB, player.ControllerIndex)

    for i, ability in ipairs(data.abilityData) do
        local state = data.abilityState[i]

        --Input block
        if Input.IsButtonTriggered(ability.key, player.ControllerIndex) then
            if tabHeld and ability.level < 3 then
                local apRemoveAmount
                if ability.level == 0 then
                    apRemoveAmount = 1
                elseif ability.level == 1 then
                    apRemoveAmount = 2
                elseif ability.level == 2 then
                    apRemoveAmount = 5
                end

                if effects:GetNullEffectNum(DeadlockMod.NullID.ABILITY_POINT) < apRemoveAmount then return end

                effects:RemoveNullEffect(DeadlockMod.NullID.ABILITY_POINT, apRemoveAmount)

                ability:upgrade()
                DeadlockMod.sfx:Play(DeadlockMod.SoundID.AbilityUpgrade)
            elseif ability.level > 0 and not tabHeld then
                if state.timePassed >= ability.cooldown then
                    ability:cast(player)
                    state.timePassed = 0
                else
                    DeadlockMod.sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ)
                end
            end
        end

        if not DeadlockMod.game:GetRoom():IsClear() then
            state.timePassed = math.min(ability.cooldown, state.timePassed + 1)
        end
    end
end
DeadlockMod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, handleAbilities, 0)


--========This place is in charge of rendering things===========

local ABILITY_ALPHA_LERP_SPEED = 0.18

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function renderAbilities()
    local player = PlayerManager.FirstPlayerByType(DeadlockMod.playerType.INFERNUS_B)
    if not player or not player:GetData().abilityData then return end

    local data = player:GetData()
    local effects = player:GetEffects()
    local abilityData = data.abilityData
    local minimapState = Minimap.GetState()

    data.abilityAlpha = data.abilityAlpha or 0
    data.abilityFlashTimer = data.abilityFlashTimer or 0

    if data.abilityFlashTimer > 0 then
        data.abilityFlashTimer = data.abilityFlashTimer - 1
        data.abilityAlpha = lerp(data.abilityAlpha, 1, ABILITY_ALPHA_LERP_SPEED)
    else
        local targetAlpha = 0.0
        if minimapState == MinimapState.EXPANDED then
            targetAlpha = 0.9
        elseif minimapState == MinimapState.EXPANDED_OPAQUE then
            targetAlpha = 0.6
        end

        data.abilityAlpha = lerp(data.abilityAlpha, targetAlpha, ABILITY_ALPHA_LERP_SPEED)
    end

    if data.abilityAlpha <= 0 then
        return
    end

    local screenWidth = Isaac.GetScreenWidth()
    local screenHeight = Isaac.GetScreenHeight()

    local iconSpacing = 45
    local bottomOffset = 32

    local totalWidth = iconSpacing * (#abilityData - 1)
    local startX = (screenWidth / 2) - (totalWidth / 2)
    local yPos = screenHeight - bottomOffset

    for i, ability in ipairs(abilityData) do
        local state = data.abilityState[i]
        local progress = state.timePassed / ability.cooldown --float from 0 (just used) to 1 (ready)

        --loading correct anims
        local sprite = ability.sprite
        if not sprite then
            ability.sprite = Sprite()
            ability.sprite:Load(ability.path, true)
        end

        sprite = ability.sprite
        sprite:Play(tostring(ability.level), true)

        --change color based on cd
        if progress < 1 then
            sprite.Color = Color(0.5, 0.5, 0.5, data.abilityAlpha)
        else
            sprite.Color = Color(1, 1, 1, data.abilityAlpha)
        end

        local xPos = startX + (i - 1) * iconSpacing
        sprite:Render(Vector(xPos, yPos), Vector.Zero, Vector.Zero)

        --text cd
        local remainingFrames = ability.cooldown - state.timePassed
        if remainingFrames > 0 then
            local seconds = math.ceil(remainingFrames / 60)

            Isaac.RenderText(tostring(seconds), xPos + 10, yPos + 8, 1, 1, 1, data.abilityAlpha)
        end
    end

    --Ap point rendering
    local boons
    if not boons then
        boons = Sprite()
        boons:Load("gfx/ui/boons.anm2", true)
        boons:Play("boon")
    end

    local boonsXOffset = startX - 50
    local boonsYOffset = yPos - 5

    boons.Color = Color(1, 1, 1, data.abilityAlpha)
    boons:Render(Vector(boonsXOffset - 10, boonsYOffset + 7), Vector.Zero, Vector.Zero)
    Isaac.RenderText(": " .. tostring(effects:GetNullEffectNum(DeadlockMod.NullID.ABILITY_POINT)), boonsXOffset, boonsYOffset, 1, 1, 1, data.abilityAlpha)
end
DeadlockMod:AddCallback(ModCallbacks.MC_POST_HUD_RENDER, renderAbilities)

--======This place is all bout giving out ability points======

---@param player EntityPlayer
local function grantBoons(player, amount)
    if player:GetPlayerType() ~= DeadlockMod.playerType.INFERNUS_B then return end

    Isaac.CreateTimer(function()
        Isaac.CreateTimer(function()
            local effects = player:GetEffects()
            effects:AddNullEffect(DeadlockMod.NullID.ABILITY_POINT, true, amount)

            DeadlockMod.sfx:Play(DeadlockMod.SoundID.Patron.BOON_ACQUIRE)
            player:SetColor(Color(1, 0, 1, 1), 30, 1, true, true)

            local data = player:GetData()
            data.abilityFlashTimer = 50
        end, 20, 0, true)
    end, 1, 0, true)
end

---@param player EntityPlayer
local function giveOutAbilityPoints(_, player, fromPlayerUpdate, postLevelInitFinished)
    if not postLevelInitFinished then return end

    local effects = player:GetEffects()

    grantBoons(player, 2)
end
DeadlockMod:AddCallback(ModCallbacks.MC_POST_PLAYER_NEW_LEVEL, giveOutAbilityPoints)

local function startingAbilityPoints(_, player)
    grantBoons(player, 1)
end
DeadlockMod:AddCallback(ModCallbacks.MC_PLAYER_INIT_POST_LEVEL_INIT_STATS, startingAbilityPoints)

---@param player EntityPlayer
local function preUseGenesis(_, CollectibleType, rng, player, useFlags, slot)
    if not player:GetData().abilityData then return end

    local effectsCount = player:GetEffects():GetNullEffectNum(DeadlockMod.NullID.ABILITY_POINT)
    local apCount = 0
    for i, ability in ipairs(player:GetData().abilityData) do
        if ability.level == 1 then
            apCount = apCount + 1
        elseif ability.level == 2 then
            apCount = apCount + 2
        elseif ability.level == 3 then
            apCount = apCount + 5
        end
    end

    apCount = apCount + effectsCount

    Isaac.CreateTimer(function() --weird shit but it is what it is
        if apCount > 1 then      -- the 1 is because of that 1 ap point we give in init stats, if we would only refund 1 ap point, then this is taken care of
            grantBoons(player, apCount)
        end
    end, 30, 0, true)
end
DeadlockMod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, preUseGenesis, CollectibleType.COLLECTIBLE_GENESIS)

---@param player EntityPlayer
local function birthright(_, type, charge, firstTime, slot, varData, player)
    if player:GetPlayerType() ~= DeadlockMod.playerType.INFERNUS_B or not firstTime then return end

    local effects = player:GetEffects()
    grantBoons(player, 31)
end
DeadlockMod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, birthright, CollectibleType.COLLECTIBLE_BIRTHRIGHT)
