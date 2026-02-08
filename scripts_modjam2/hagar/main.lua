HAGAR_MOD = RegisterMod("Hagar (B95 CharacterJam)", 1)

HAGAR_MOD.Game = Game()
HAGAR_MOD.SFX = SFXManager()
HAGAR_MOD.Font = Font()

HAGAR_MOD.SaveManager = MODJAM_VOL_2.Meta.SaveMan

HAGAR_MOD:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function ()
    if not HAGAR_MOD.Font:IsLoaded() then
        HAGAR_MOD.Font:Load("font/pftempestasevencondensed.fnt")
    end
end)

for _, script in ipairs({
    "enums",
    "lib",
    "hagar.character",
    "hagar.el_roi",
    "EID",

    "thagar.health_buffer",
    "thagar.unlock_method",
    "thagar.heart_absorbtion",
    "thagar.healthbar_correcting",
    "thagar.health_on_kill",
    "thagar.active_item",
    "thagar.projectile_reflection",
    "thagar.health_sprite_info",
    "thagar.ui_rendering",
    "thagar.invuln_rendering",
    "thagar.conpat",
    "thagar.mod_compat",

    "thagar.heart_effects.red",
    "thagar.heart_effects.soul",
    "thagar.heart_effects.black",
    "thagar.heart_effects.eternal",
    "thagar.heart_effects.golden",
    "thagar.heart_effects.bone",
    "thagar.heart_effects.rotten",
}) do
    include("scripts_modjam2.hagar." .. script)
end

return HAGAR_MOD