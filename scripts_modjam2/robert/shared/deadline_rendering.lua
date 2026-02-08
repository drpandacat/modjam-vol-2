local mod = ROBERT_MOD

local DEADLINE_TRACKER = ROBERT_MOD.NullItemID.DEADLINE_TRACKER

local TIMER_DISABLED_HOUR = 99

local currentMinutes = 0
local currentHours = TIMER_DISABLED_HOUR

local game = Game()
local hud = game:GetHUD()

local backSprite = Sprite()
local textFont = Font()
local frontSprite = Sprite()

local WHITE_KCOLOR = KColor(1, 1, 1, 1)
local RED_KCOLOR = KColor(1, 0, 0, 1)
local FROZEN_KCOLOR = KColor(0.5, 0.7, 1, 1)
local ASCENT_KCOLOR = KColor(1, 0.5, 0.2, 1)
local GREED_KCOLOR = KColor(1, 0.8, 0.3, 1)

local shouldRenderText = true
local currentTextColor = WHITE_KCOLOR

backSprite:Load("gfx/ui/clockenheimer.anm2", true)
backSprite:Play("Idle")

textFont:Load("font/pftempestasevencondensed.fnt")

frontSprite:Load("gfx/ui/clockenheimer.anm2", true)
frontSprite:Play("Glowconstant")

frontSprite.Color = Color(1,1,1,1)
backSprite.Color = Color(1,1,1,1)

local RENDER_POS = Vector(175, 40)

local function RenderTimerText()
    local tainted = PlayerManager.AnyoneIsPlayerType(ROBERT_MOD.PlayerType.ROBERT_B)
    if not (shouldRenderText or (tainted and currentHours > 0))
    or game:GetFrameCount() < 1 then
        return
    end

    local leftText, rightText

    if tainted then
        if currentHours > 0 then
            local minutes = currentHours // 60
            local seconds = currentHours % 60

            leftText = (minutes < 10 and "0" .. minutes or minutes)
            rightText = (seconds < 10 and "0" .. seconds or seconds)
        else
            leftText = "00"
            rightText = "DIE"
        end
    else
        leftText = tostring(math.min(currentHours, 99))
        if currentHours <= 9 then
            if game:IsGreedMode() then
                leftText = "$" .. leftText --Saving the alternate char in case I want to swap it back. ¢
            else
                leftText = "0" .. leftText
            end
        end

        rightText = tostring(currentMinutes)
        if currentMinutes <= 9 then
            rightText = "0" .. rightText
        end
        if currentHours == 0
        and currentMinutes > 0
        then
            rightText = "DIE"
        end
    end

    textFont:DrawString(leftText, 153, 26, currentTextColor, 20)
    textFont:DrawString(":", 174, 25, currentTextColor)
    textFont:DrawString(rightText, 178, 26, currentTextColor)
end

local function PostRender()
    if not ROBERT_MOD:AnyoneIsRobert()
    or not hud:IsVisible() then
        return
    end

    backSprite:Render(RENDER_POS)
    if backSprite:GetAnimation() == "Disabled" then
        return
    end
    RenderTimerText()
    frontSprite:Render(RENDER_POS)
end
mod:AddCallback(ModCallbacks.MC_HUD_RENDER, PostRender)

local function UpdateRenderTransparency()
    if Minimap.GetState() == MinimapState.NORMAL then
        backSprite.Color.A = 0.3
        frontSprite.Color.A = 0.3
        currentTextColor.Alpha = 0.5
    else
        backSprite.Color.A = 1
        frontSprite.Color.A = 1
        currentTextColor.Alpha = 1
    end
end

local function PostUpdate()
    if not ROBERT_MOD:AnyoneIsRobert() then
        return
    end

    local level = game:GetLevel()

    if mod.IsStageBlacklisted()
    and not level:IsAscent() then
        backSprite:Play("Disabled", true)
        UpdateRenderTransparency()
        return
    end
    if backSprite:GetAnimation() == "Disabled" then
        backSprite:Play("Idle", true)
    end

    local roomTimer = 0
    local stage = level:GetStage()
    local isGreedMode = game:IsGreedMode()
    local isAscent = level:IsAscent()

    if isGreedMode then
        roomTimer = game:GetGreedWavesNum() - level.GreedModeWave - 2 --Offset so it hits 0 at first boss.
        roomTimer = math.max(roomTimer, 0)
    elseif isAscent then
        roomTimer = stage
        local levelType = level:GetStageType()
        if levelType == StageType.STAGETYPE_REPENTANCE then
            roomTimer = roomTimer+1
        end
    else
        roomTimer = ROBERT_MOD:GetFirstRobert():GetEffects():GetNullEffectNum(DEADLINE_TRACKER)
    end

    if roomTimer ~= currentHours then
        if currentHours - roomTimer == 1
        or roomTimer == 0 then
            backSprite:Play("RoomFlicker", true)
            currentMinutes = 60
            currentTextColor = RED_KCOLOR
        else
            backSprite:Play("Enable", true)
            shouldRenderText = false
            currentTextColor = WHITE_KCOLOR
        end
    end
    currentHours = roomTimer

    backSprite:Update()

    if currentMinutes > 0 then
        currentMinutes = math.max(0,currentMinutes-(PlayerManager.AnyoneIsPlayerType(ROBERT_MOD.PlayerType.ROBERT_B) and 2 or 3))
    end

    if backSprite:IsEventTriggered("NumbersOff") then
        shouldRenderText = false
    elseif backSprite:IsEventTriggered("NumbersOn") then
        shouldRenderText = true
    end

    if backSprite:IsFinished("RoomFlicker") then
        backSprite:Play("Idle", true)
        shouldRenderText = true
    elseif backSprite:IsFinished("Enable") then
        backSprite:Play("Idle", true)
        shouldRenderText = true
    elseif backSprite:IsFinished("Idle") then
        currentTextColor = WHITE_KCOLOR
        shouldRenderText = true
    end

    -- if PlayerManager.AnyoneIsPlayerType(ROBERT_MOD.PlayerType.ROBERT_B) then
        -- currentTextColor = RED_KCOLOR
    -- end

    if isAscent then
        currentTextColor = ASCENT_KCOLOR
    elseif isGreedMode then
        currentTextColor = GREED_KCOLOR
    elseif mod.IsRoomTimerImmune() then
        currentTextColor = FROZEN_KCOLOR
    end

    UpdateRenderTransparency()
end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, PostUpdate)

local function PostGameStarted()
    currentHours = TIMER_DISABLED_HOUR
    currentMinutes = 0

    currentTextColor = WHITE_KCOLOR
    backSprite:Play("Idle", true)
    shouldRenderText = true
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, PostGameStarted)

--Since it took a while to update when starting a new floor
local function PostNewLevel()
    if not game:GetLevel():IsAscent()
    and mod.IsStageBlacklisted() then
        backSprite:Play("Disabled", true)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, PostNewLevel)