local mod = HAGAR_MOD

local MAX_TIMER_FRAME = 7
local MAX_BUBBLE_FRAME = 30

local timerSprite = Sprite()
local bubbleSprite = Sprite()

timerSprite:Load("gfx/characters/zamzam_invuln_timer.anm2", true)
timerSprite:Play("Idle")

bubbleSprite:Load("gfx/characters/zamzam_invuln_bubble.anm2", true)
bubbleSprite:Play("Idle")

---@param player EntityPlayer
local function PostPlayerRender(_, player)
    local effects = player:GetEffects()
    if not effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS) then
        return
    end

    local data = player:GetData()
    if not data.HagarZamzamColor then
        return
    end

    bubbleSprite.Color = data.HagarZamzamColor
    timerSprite.Color = data.HagarZamzamColor

    local renderPos = Isaac.WorldToScreen(player.Position)

    local duration = effects:GetCollectibleEffect(CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS).Cooldown

    local secondsLeft = math.floor(duration/30)
    secondsLeft = math.min(secondsLeft, MAX_TIMER_FRAME)
    timerSprite:SetFrame(secondsLeft)
    bubbleSprite:SetFrame(player.FrameCount%MAX_BUBBLE_FRAME)


    local scale = player.SpriteScale
    timerSprite.Scale = scale
    bubbleSprite.Scale = scale

    bubbleSprite:Render(renderPos)
    if not (timerSprite:GetFrame() == 0)
    or not (player.FrameCount%4 < 2) then
        timerSprite:Render(renderPos)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, PostPlayerRender)