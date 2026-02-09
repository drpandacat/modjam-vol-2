HAGAR_MOD.Enums = {}

HAGAR_MOD.Enums.Character = {
    HAGAR = Isaac.GetPlayerTypeByName("Hagar"),
    T_HAGAR = Isaac.GetPlayerTypeByName("Hagar", true),
}

HAGAR_MOD.Enums.CharacterStats = {
    DMG_MULTIPLIER = 1.5,
    MORE_SOUL_HEART_CHANCE = 0.15,

    HEART_OVERHEAL = {
        [HeartSubType.HEART_FULL] = 2,
        [HeartSubType.HEART_HALF] = 1,
        [HeartSubType.HEART_DOUBLEPACK] = 4,
        [HeartSubType.HEART_SCARED] = 2,
    },
    HEART_CAP = 6,
    HEART_CAP_BIRTHRIGHT = 12,

    INCREASED_EL_ROI_COST = {
        [RoomType.ROOM_BOSS] = true,
        [RoomType.ROOM_MINIBOSS] = true,
        [RoomType.ROOM_BOSSRUSH] = true,
    }
}

HAGAR_MOD.Enums.Blacklists = {}

HAGAR_MOD.Enums.Blacklists.MonsterHPUp = {
    [EntityType.ENTITY_STONEHEAD] = true,
    [EntityType.ENTITY_POKY] = true,
    [EntityType.ENTITY_MASK] = true,
    [EntityType.ENTITY_ETERNALFLY] = true,
    [EntityType.ENTITY_STONE_EYE] = true,
    [EntityType.ENTITY_CONSTANT_STONE_SHOOTER] = true,
    [EntityType.ENTITY_BRIMSTONE_HEAD] = true,
    [EntityType.ENTITY_DEATHS_HEAD] = true,
    [EntityType.ENTITY_WALL_HUGGER] = true,
    [EntityType.ENTITY_GAPING_MAW] = true,
    [EntityType.ENTITY_BROKEN_GAPING_MAW] = true,
    [EntityType.ENTITY_POOP] = true,
    [EntityType.ENTITY_PITFALL] = true,
    [EntityType.ENTITY_MOVABLE_TNT] = true,
    [EntityType.ENTITY_ULTRA_DOOR] = true,
    [EntityType.ENTITY_STONEY] = true,
    [EntityType.ENTITY_QUAKE_GRIMACE] = true,
    [EntityType.ENTITY_BOMB_GRIMACE] = true,
    [EntityType.ENTITY_SPIKEBALL] = true,
    [EntityType.ENTITY_MOCKULUS] = true,
    [EntityType.ENTITY_GRUDGE] = true,
    [EntityType.ENTITY_DUSTY_DEATHS_HEAD] = true,
    [EntityType.ENTITY_BALL_AND_CHAIN] = true,
    [EntityType.ENTITY_GIDEON] = true,
    [EntityType.ENTITY_SIREN_HELPER] = true,
    [EntityType.ENTITY_DARK_ESAU] = true,
    [EntityType.ENTITY_FROZEN_ENEMY] = true,
    [EntityType.ENTITY_MINECART] = true,
    [EntityType.ENTITY_GENERIC_PROP] = true,
    [EntityType.ENTITY_HORNFEL_DOOR] = true,
    --
    [EntityType.ENTITY_MRMAW] = {[10] = true},
    [EntityType.ENTITY_PEEP] = {[10] = true},
    [EntityType.ENTITY_SWINGER] = {[10] = true},
    [EntityType.ENTITY_HOMUNCULUS] = {[10] = true},
    [EntityType.ENTITY_BEGOTTEN] = {[10] = true},
    [EntityType.ENTITY_MR_MINE] = {[10] = true},
    [EntityType.ENTITY_EVIS] = {[10] = true},
    [EntityType.ENTITY_GEMINI] = {[20] = true},
    [EntityType.ENTITY_VISAGE] = {[10] = true},
    [EntityType.ENTITY_FLY_BOMB] = {[1] = true},
    [EntityType.ENTITY_PEEPER_FATTY] = {[10] = true},
    [EntityType.ENTITY_SIREN] = {[1] = true, [10] = true},
    [EntityType.ENTITY_MOTHER] = {[30] = true, [100] = true},
    [EntityType.ENTITY_SINGE] = {[1] = true},
}

---@param npc EntityNPC
function HAGAR_MOD.Enums.Blacklists.MonsterHPUp.IsBlacklisted(self, npc)
    local typeBlacklist = self[npc.Type]
    local variantBlacklist
    if typeBlacklist and type(typeBlacklist) == "table" then
        variantBlacklist = typeBlacklist[npc.Variant]
    end
    return (typeBlacklist and type(typeBlacklist) == "boolean") or (variantBlacklist and type(variantBlacklist) == "boolean")
end

HAGAR_MOD.Enums.Collectibles = {
    EL_ROI = Isaac.GetItemIdByName("El Roi"),
    ZAMZAM = Isaac.GetItemIdByName("Zamzam"),
}

HAGAR_MOD.Enums.NullItems = {
    HAGAR_HEART_COUNTER = Isaac.GetNullItemIdByName("(Hagar Null) Hagar Red Heart Counter"),
    HAGAR_BIRTHRIGHT_EFFECT = Isaac.GetNullItemIdByName("(Hagar Null) Hagar Birthright Effect"),
    THAGAR_ZAMZAM_BONUS = Isaac.GetNullItemIdByName("(THagar Null) Zamzam Tears Bonus"),
}

HAGAR_MOD.Enums.Achievements = {
    THAGAR_UNLOCK = Isaac.GetAchievementIdByName("THagarUnlock")
}

HAGAR_MOD.Enums.StoredHeartKeys = {
    RED = "HagarRed",
    SOUL = "HagarSoul",
    BLACK = "HagarBlack",
    ETERNAL = "HagarEternal",
    BONE = "HagarBone",
    ROTTEN = "HagarRotten",
    GOLDEN = "HagarGolden",

    CON = "HagarCon",

    FF_IMMORAL = "HagarFFImmoral",
    FF_MORBID = "HagarFFMorbid",
    EP_BROKEN = "HagarEpiphBroken",
    EP_SANCTIFIED = "HagarEpiphSanctified",
    RM_SUN = "HagarRestoredSun",
    RM_ILLUSION = "HagarRestoredIllusion",
    RM_IMMORTAL = "HagarRestoredImmortal",
}

HAGAR_MOD.Enums.ModdedHeartTypes = {
    FF_IMMORAL = "HagarFFImmoral",
    FF_MORBID = "HagarFFMorbid",
    EP_BROKEN = "HagarEpiphBroken",
    EP_SANCTIFIED = "HagarEpiphSanctified",
    RM_SUN = "HagarRestoredSun",
    RM_ILLUSION = "HagarRestoredIllusion",
    RM_IMMORTAL = "HagarRestoredImmortal",
}

HAGAR_MOD.Enums.Callbacks = {
    ZAMZAM_ACTIVATE_HEART = "HagarZamzamActivateHeart",
    ZAMZAM_ENEMY_COLLISION = "HagarZamzamEnemyCollision",
    ZAMZAM_BULLET_REFLECTED = "HagarZamzamBulletReflected",
    CHECK_OWNED_HEALTH_TYPES = "HagarCheckOwnedHealthTypes",
    CHECK_HEART_HEALTH_TYPE = "HagarCheckHeartHealthType",
    GET_HEART_KEY = "HagarGetHeartKey",
    REMOVE_EXCESS_HEART_TYPE = "HagarRemoveExcessHeartType",
    HEART_TYPE_TO_HEART_KEY = "HagarHeartTypeToHeartKey",
}
