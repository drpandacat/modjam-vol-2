if not REPENTOGON or not REPENTANCE_PLUS then return end
MODJAM_VOL_2 = RegisterMod("Modjam Vol. 2", 1)

MODJAM_VOL_2.Meta = {}
local t = MODJAM_VOL_2.Meta

t.SaveMan = include("scripts_modjam2.save_manager")
t.SaveMan.Init(MODJAM_VOL_2)

t.ACHIEVEMENT_BONUS = Isaac.GetAchievementIdByName("Mod Jam Bonus Characters")

t.KONAMI = {
    Keyboard.KEY_UP,
    Keyboard.KEY_UP,
    Keyboard.KEY_DOWN,
    Keyboard.KEY_DOWN,
    Keyboard.KEY_LEFT,
    Keyboard.KEY_RIGHT,
    Keyboard.KEY_LEFT,
    Keyboard.KEY_RIGHT,
    Keyboard.KEY_B,
    Keyboard.KEY_A,
}

t.KonamiIndex = 1

MODJAM_VOL_2:AddCallback(ModCallbacks.MC_MAIN_MENU_RENDER, function ()
    if not MenuManager.IsActive() then return end

    for _, v in ipairs(t.KONAMI) do
        if Input.IsButtonTriggered(v, 0) then
            if v == t.KONAMI[t.KonamiIndex] then
                t.KonamiIndex = t.KonamiIndex + 1
                break
            else
                t.KonamiIndex = 1
            end
        end
    end

    if t.KonamiIndex > #t.KONAMI then
        local data = Isaac.GetPersistentGameData()

        t.KonamiIndex = 1

        if data:Unlocked(t.ACHIEVEMENT_BONUS) then
            Isaac.ExecuteCommand("lockachievement " .. t.ACHIEVEMENT_BONUS)
        else
            data:TryUnlock(t.ACHIEVEMENT_BONUS)
        end
        ImGui.PushNotification("Re-enter save file to update characters", ImGuiNotificationType.INFO)
        -- MenuManager.SetActiveMenu(MainMenuType.SAVES)
    end
end)

MODJAM_VOL_2:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD, function ()
    t.KonamiIndex = 1
end)

MODJAM_VOL_2.Beelze = include("scripts_modjam2.beelze.main")
MODJAM_VOL_2.Robert = include("scripts_modjam2.robert.main")
MODJAM_VOL_2.Hagar = include("scripts_modjam2.hagar.main")
MODJAM_VOL_2.Churchill = include("scripts_modjam2.churchill.main")
MODJAM_VOL_2.Hart = include("scripts_modjam2.hart.main")
MODJAM_VOL_2.Anima = include("scripts_modjam2.anima.main")
MODJAM_VOL_2.Infernus = include("scripts_modjam2.infernus.main")
MODJAM_VOL_2.Gloopy20 = include("scripts_modjam2.gloopy20.main")
MODJAM_VOL_2.Fleeboo = include("scripts_modjam2.fleeboo.main")
MODJAM_VOL_2.Random = include("scripts_modjam2.random.main")

