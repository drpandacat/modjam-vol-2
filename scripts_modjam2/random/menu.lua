local sfx = SFXManager()

local howLongHasbeenInCharacter = 0

local unlockSprite = Sprite("gfx/ui/completion_widget.anm2", true)
unlockSprite:Play("Idle", true)
local unlockKeyToFrame = {
    Beast = "DadsNote",
    Mother = "Knife",
    Hush = "Hush",
    UltraGreed = "Greed",
    MegaSatan = "MegaSatan",
    Lamb = "Negative",
    BlueBaby = "Polaroid",
    BossRush = "Star",
    Satan = "UpsideDownCross",
    Isaac = "Cross",
    MomsHeart = "Heart",
    Delirium = "Paper",
}

local function menuupdate(_)
    if not Isaac.GetPersistentGameData():Unlocked(MODJAM_VOL_2.Meta.ACHIEVEMENT_BONUS) then return end
    local selid = CharacterMenu:GetSelectedCharacterID()

    if(MenuManager:GetActiveMenu()~=MainMenuType.CHARACTER) then
        howLongHasbeenInCharacter = 0
        MenuManager.SetInputMask(MenuManager.GetInputMask() | ButtonActionBitwise.ACTION_MENUCONFIRM)
    else
        howLongHasbeenInCharacter = howLongHasbeenInCharacter+1

        if(selid==0) then
            MenuManager.SetInputMask(MenuManager.GetInputMask() & (~ButtonActionBitwise.ACTION_MENUCONFIRM))
            --CharacterMenu.SetActiveStatus(CharacterMenuStatus.DEFAULT)
        else
            MenuManager.SetInputMask(MenuManager.GetInputMask() | ButtonActionBitwise.ACTION_MENUCONFIRM)
        end
    end

    if(selid==0) then
        local cancelStartRun = false

        --local tainted = (CharacterMenu.GetSelectedCharacterMenu()==1)
        local plId = RandomMod.PLAYER_RANDOM --(tainted and RandomMod.PLAYER_RANDOM_B or RandomMod.PLAYER_RANDOM)

        local conf = EntityConfig.GetPlayer(plId)
        if(not conf) then return end
        local sp = conf:GetModdedMenuBackgroundSprite()
        local portraitSp = conf:GetModdedMenuPortraitSprite()
        if(not sp or not portraitSp) then return end

        local pos = Isaac.WorldToMenuPosition(MainMenuType.CHARACTER, Vector.Zero)-Vector(39,15)
        local pageSp = CharacterMenu.GetBGSprite()

        local paperlayer = pageSp:GetLayer("Paper")
        if(paperlayer) then
            local frame = pageSp:GetLayerFrameData(paperlayer:GetLayerID())
            if(frame) then
                sp.Scale = frame:GetScale()
                portraitSp.Scale = frame:GetScale()
                sp.Offset = frame:GetPos()-frame:GetPivot()-Vector(240*(sp.Scale.X-1), 0)
                portraitSp.Offset = frame:GetPos()-frame:GetPivot()+Vector(0, 100*(sp.Scale.Y-1))
            else
                sp.Scale = Vector(1,1)
                portraitSp.Scale = Vector(1,1)
                sp.Offset = Vector.Zero
                portraitSp.Offset = Vector.Zero
            end
        end

        --[[
        if(tainted) then
            local unlocked = Isaac.GetPersistentGameData():Unlocked(RandomMod.ACHIEVEMENT_RANDOM_B)
            if(not unlocked) then
                cancelStartRun = true
            end

            for _, layer in ipairs(sp:GetAllLayers()) do
                if(layer:GetName()=="Unlocked By") then layer:SetVisible(not unlocked)
                else layer:SetVisible(unlocked) end
            end
        end
        --]]
        sp:Play("Random?", true)
        sp:Render(pos)

        local unlocks = Isaac.GetCompletionMarks(plId)
        for key, val in pairs(unlocks) do
            if(unlockKeyToFrame[key]) then
                local layer = unlockSprite:GetLayer(unlockKeyToFrame[key])
                if(layer) then
                    unlockSprite:SetLayerFrame(layer:GetLayerID(), val--[[+((key=="Delirium" and tainted) and 5 or 0)]])
                end
            end
        end

        local unlockPos = Isaac.WorldToMenuPosition(MainMenuType.CHARACTER, Vector.Zero)+Vector(41,35)
        unlockSprite:Render(unlockPos)

        if(Input.IsActionTriggered(ButtonAction.ACTION_MENUCONFIRM, 0) and howLongHasbeenInCharacter>1) then
            if(cancelStartRun) then
                sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ)
            else
                Isaac.StartNewGame(plId, Challenge.CHALLENGE_NULL, CharacterMenu.GetDifficulty())
            end
        end
    end
end
RandomMod:AddCallback(ModCallbacks.MC_MAIN_MENU_RENDER, menuupdate)