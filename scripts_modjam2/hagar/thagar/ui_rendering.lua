local mod = HAGAR_MOD

HAGAR_MOD.RenderCache = {
    ZamzamBuffer = {},
}

local FULLBRIGHT_COLOUR = Color(1,1,1, 1, 1,1,1)
local BASE_COLOUR = Color()

local BASE_START_OFFSET = Vector(32,4)
local BASE_STACK_OFFSET = Vector(0, 4)
local BASE_TOP_OFFSET = Vector(0,2)

local SINE_FREQUENCY_MULT = 0.15
local SINE_HEART_DELTA = 0.75
local SINE_AMPLITUDE_BASE = Vector(0.4,0)

---@param player EntityPlayer
---@param slot ActiveSlot
---@param offset Vector
---@param alpha number
---@param scale number
local function PostItemRender(_, player, slot, offset, alpha, scale)
    local item = player:GetActiveItem(slot)
    if item ~= mod.Enums.Collectibles.ZAMZAM then
        return
    end
    local ptrHash = GetPtrHash(player)
    mod.RenderCache.ZamzamBuffer[ptrHash] = mod.RenderCache.ZamzamBuffer[ptrHash] or mod.Zamzam.Buffer(player)
    local buffer = mod.RenderCache.ZamzamBuffer[ptrHash]
    if #buffer == 0 then
        return
    end

    local startOffset = offset + BASE_START_OFFSET*scale
    local stackOffset = BASE_STACK_OFFSET*scale
    local topOffset = BASE_TOP_OFFSET*scale
    local scaleVector = Vector(scale, scale)

    local sineAmplitude = SINE_AMPLITUDE_BASE*scale
    local frameCount = mod.Game:GetFrameCount()

    for i = #buffer, 2, -1 do
        local key = buffer[i]
        local heartData = mod.THagarHeartTypes[key]
        if not heartData then
            goto continue
        end

        local sprite = heartData.HeartSprite
        sprite:SetFrame(heartData.HeartFrame)
        sprite.Color.A = alpha
        sprite.Scale = scaleVector

        local sine = math.sin((frameCount*SINE_FREQUENCY_MULT) + (SINE_HEART_DELTA*i))
        local sineOffset = sineAmplitude*sine*i

        local heartRenderPos = startOffset + (stackOffset*i) + sineOffset
        sprite:Render(heartRenderPos)
        ::continue::
    end

    local mainHeart = buffer[1]
    local heartData = mod.THagarHeartTypes[mainHeart]
    if not heartData then
        return
    end
    local sprite = heartData.HeartSprite
    sprite:SetFrame(heartData.HeartFrame)
    sprite.Scale = scaleVector
    local heartRenderPos = startOffset + topOffset
    sprite.Color = FULLBRIGHT_COLOUR
    sprite:Render(heartRenderPos + Vector(0,1)*scale)
    sprite:Render(heartRenderPos + Vector(0,-1)*scale)
    sprite:Render(heartRenderPos + Vector(1,0)*scale)
    sprite:Render(heartRenderPos + Vector(-1,0)*scale)
    sprite.Color = BASE_COLOUR
    sprite.Color.A = alpha
    sprite:Render(heartRenderPos)

    local wellSprite = heartData.WellSprite
    wellSprite.Color.A = alpha
    wellSprite.Scale = scaleVector
    wellSprite:SetFrame(heartData.WellFrame)
    wellSprite:Render(offset)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYERHUD_RENDER_ACTIVE_ITEM, PostItemRender)

---Copied it all from Wikipedia, so it might look a bit nightmarish
---https://en.wikipedia.org/wiki/HSL_and_HSV#To_RGB
---@param frame integer
---@return number[]
local function RainbowColorFromFrame(frame)
    frame = (frame*4)%360

    local lightness = 0.6
    local saturation = 0.5
    local frame_trimmed = frame / 60
    local chroma = (1 - math.abs(2*lightness - 1))*saturation
    local x = chroma * (1 - math.abs((frame_trimmed%2) - 1))

    local r1, g1, b1

    if frame_trimmed < 1 then
        r1 = chroma
        g1 = x
        b1 = 0
    elseif frame_trimmed < 2 then
        r1 = x
        g1 = chroma
        b1 = 0
    elseif frame_trimmed < 3 then
        r1 = 0
        g1 = chroma
        b1 = x
    elseif frame_trimmed < 4 then
        r1 = 0
        g1 = x
        b1 = chroma
    elseif frame_trimmed < 5 then
        r1 = x
        g1 = 0
        b1 = chroma
    else
        r1 = chroma
        g1 = 0
        b1 = x
    end

    local m = lightness - (chroma/2)

    return {r1+m, g1+m, b1+m}
end

local healthTypeSprite = Sprite()
healthTypeSprite:Load("gfx/ui/thagar_health_type_beacon.anm2", true)
healthTypeSprite:Play("LeftOff")

---@param offset Vector
---@param heartsSprite Sprite
---@param position Vector
---@param scale number
---@param player EntityPlayer
local function PostHealthRender(_, offset, heartsSprite, position, scale, player)
    if player:GetPlayerType() ~= mod.Enums.Character.T_HAGAR
    or mod.Game:GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_UNKNOWN ~= 0 then
        return
    end

    local types = player:GetData().HagarLastFrameHealthTypes or mod.Lib.CurrentHealthTypes(player)

    local type1 = types[1]
    local type2 = types[2]
    local type3 = types[3]

    healthTypeSprite.Scale = Vector(scale, scale)

    if type1 then
        healthTypeSprite:Play("LeftOn")
        local color
        if not type3 then
            color = mod.THagarHealthColors[type1] or {1,1,1}
        else
            color = RainbowColorFromFrame(player.FrameCount)
        end
        healthTypeSprite.Color:SetTint(color[1], color[2], color[3], 1)
    else
        healthTypeSprite:Play("LeftOff")
    end
    healthTypeSprite:Render(position + Vector(15, 13)*scale)

    if type2 then
        healthTypeSprite:Play("RightOn")
        local color
        if not type3 then
            color = mod.THagarHealthColors[type2] or {1,1,1}
        else
            color = RainbowColorFromFrame(player.FrameCount+15)
        end
        healthTypeSprite.Color:SetTint(color[1], color[2], color[3], 1)
    else
        healthTypeSprite:Play("RightOff")
    end
    healthTypeSprite:Render(position + Vector(22, 13)*scale)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYERHUD_RENDER_HEARTS, PostHealthRender)

local function OnGameExit()
    mod.RenderCache = {
        ZamzamBuffer = {},
    }
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, OnGameExit)