local Constants = {
    Players = {
        Anima = Isaac.GetPlayerTypeByName("Anima", false),
        Anima_Decoy = Isaac.GetPlayerTypeByName("Anima_Decoy", false),
        TaintedAnima = Isaac.GetPlayerTypeByName("Anima", true),
    },
    Items = {
        Persona = Isaac.GetItemIdByName("Persona"),
        DualRole = Isaac.GetItemIdByName("Dual Role"),
    },
    NullItems = {
        PersonaLazarusRevival = Isaac.GetNullItemIdByName("lazarus persona revival"),
        PersonaLazarusPostRevive = Isaac.GetNullItemIdByName("lazarus persona post revive"),
        CostumeHappyMask = Isaac.GetNullItemIdByName("Tainted Anima Mask Happy"),
        CostumeSadMask = Isaac.GetNullItemIdByName("Tainted Anima Mask Sad"),
        TragedyTMagdalene = Isaac.GetNullItemIdByName("AnimaTragedy T Magdalene"),
    },
}

return Constants
