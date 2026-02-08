function DeadlockMod:LoadScripts(includestart, t)
    for k, v in ipairs(t) do
        if includestart then v = includestart .. "." .. v end

        include(v)
    end
end

include("scripts_modjam2.infernus.libs.throwableItemLib").Init()
include("scripts_modjam2.infernus.libs.jumpLib").Init()

DeadlockMod:LoadScripts("scripts_modjam2.infernus.enums", {
    "soundID",
    "playerType",
    "nullID",
    "tearVariant",
    "collectibleType",
    "effectVariant",
})

DeadlockMod:LoadScripts("scripts_modjam2.infernus.libs", {
    "lib",
    "status_effect_library",
})

DeadlockMod:LoadScripts("scripts_modjam2.infernus.features.characters.infernus", {
    "abilitiesManager",
})
DeadlockMod:LoadScripts("scripts_modjam2.infernus.features.externalMods", {
    "EID",
    "theFuture",
})

DeadlockMod:LoadScripts("scripts_modjam2.infernus.features.characters.infernus_b", {
    "abilitiesManager",
    "characterUnlock",
    "infernus_b",

})

return DeadlockMod