RandomMod = RegisterMod("QuestionMarks", 1) ---@type ModReference

RandomMod.PLAYER_RANDOM = Isaac.GetPlayerTypeByName("Random?", false) ---@type PlayerType
--RandomMod.PLAYER_RANDOM_B = Isaac.GetPlayerTypeByName("Random?", true) ---@type PlayerType

--RandomMod.ACHIEVEMENT_RANDOM_B = Isaac.GetAchievementIdByName("Tainted Random?") ---@type Achievement

RandomMod.COSTUME_OPTIONS = Isaac.GetCostumeIdByPath("gfx/characters/costume_options.anm2")
RandomMod.COSTUME_OPTION_TRINITY = Isaac.GetCostumeIdByPath("gfx/characters/costume_option_trinity.anm2")

include("scripts_modjam2.random.menu")
include("scripts_modjam2.random.random")

if(EID) then
    local iconSprite = Sprite("gfx/mj_eid_icons.anm2", true)
    EID:addIcon("Player"..tostring(RandomMod.PLAYER_RANDOM), "Players", 0, 16, 16, 0, 0, iconSprite)

    EID.descriptions["en_us"].CharacterInfo[RandomMod.PLAYER_RANDOM] = {
        "Random",
        "Starts with 3 coins, 1 bomb or 1 key#Starts with an additional random heart#Every floor, gains the effect of {{Collectible249}} {{ColorSilver}}There's Options{{CR}}, {{Collectible414}} {{ColorYellow}}More Options{{CR}}, or {{Collectible670}} {{ColorGray}}Options?{{CR}} for the duration of the floor"
    }
    EID:addBirthright(
        RandomMod.PLAYER_RANDOM,
        "Every floor, gain the effect of {{Collectible249}} {{ColorSilver}}There's Options{{CR}}, {{Collectible414}} {{ColorYellow}}More Options{{CR}}, and {{Collectible670}} {{ColorGray}}Options?{{CR}} at the same time for the duration of the floor"
    )
end

return RandomMod