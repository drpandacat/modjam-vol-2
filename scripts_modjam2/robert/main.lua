ROBERT_MOD = RegisterMod("Robert Jamguy", 1)

ROBERT_MOD.Achievement = {
    ROBERT_UNLOCK = Isaac.GetAchievementIdByName("RobertUnlock"),
    ROBERT_B_UNLOCK = Isaac.GetAchievementIdByName("RobertBUnlock"),
}

ROBERT_MOD.PlayerType = {
    ROBERT = Isaac.GetPlayerTypeByName("Robert"),
    ROBERT_B = Isaac.GetPlayerTypeByName("Robert", true),
}

ROBERT_MOD.NullItemID = {
    DEADLINE_TRACKER = Isaac.GetNullItemIdByName("Robert Deadline Tracker"),
    BOSS_BONUS_TRACKER = Isaac.GetNullItemIdByName("Robert Boss Bonus Tracker"),
    MAX_DEADLINE = Isaac.GetNullItemIdByName("Robert Max Deadline"),
    DEADLINE_ANXIETY = Isaac.GetNullItemIdByName("Robert Deadline Anxiety")
}

ROBERT_MOD.CollectibleType = {
    CLOCK_IN = Isaac.GetItemIdByName("Clock In"),
    CLOCK_OUT = Isaac.GetItemIdByName("Clock Out"),
    CLOCKED_OUT = Isaac.GetItemIdByName("Clocked Out!"),
}

ROBERT_MOD.EffectVariant = {
    BIRTHRIGHT_DOOR = Isaac.GetEntityVariantByName("Robert Birthright Door"),
}

ROBERT_MOD.Card = {
    EXIT_KEYCARD = Isaac.GetCardIdByName("RobertKeycard")
}

for _, filename in ipairs({
    "shared.utils",
    "shared.unlock_method",
    "shared.birthright",
    "shared.exit_card",
    "shared.exit_card_resprite",
    "shared.conpat",
    "shared.deadline_rendering",
    "shared.mod_compat",

    "normal.mapping_and_no_return",
    "normal.boss_speedrun_bonus",
    "normal.expanded_floorgen",
    "normal.deadline",
    "normal.curse_protection",
    "normal.easier_quests",
    "normal.ascent_treasure_banisher",
    "normal.first_floor_treasure_blocker",

    "greed.old_greed_mode_handling",
    "greed.no_return",
    "greed.less_waves",
    "greed.floor_generation",

    "tainted.main",
    "tainted.unlock"
}) do
    include("scripts_modjam2.robert." .. filename)
end

return ROBERT_MOD