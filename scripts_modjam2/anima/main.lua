---@class AnimaMod : ModReference
AnimaCharacter = RegisterMod("Anima", 1)

AnimaCharacter.Game = Game()
AnimaCharacter.SFXManager = SFXManager()
AnimaCharacter.ItemConfig = Isaac.GetItemConfig()
AnimaCharacter.PlayerManager = PlayerManager

AnimaCharacter.SaveManager = MODJAM_VOL_2.Meta.SaveMan

local dataHolder = require("scripts_modjam2.anima.getData")
AnimaCharacter.GetData = dataHolder.GetData


include("scripts_modjam2.anima.anima")
include("scripts_modjam2.anima.taintedAnima")
include("scripts_modjam2.anima.taintedunlock")

--mod compat
include("scripts_modjam2.anima.modCompat.eid")
include("scripts_modjam2.anima.modCompat.theFuture")
include("scripts_modjam2.anima.modCompat.uniqueMiniIsaacs")
include("scripts_modjam2.anima.modCompat.customCoopGhosts")

local mod = AnimaCharacter

mod:AddCallback(ModCallbacks.MC_POST_MODS_LOADED, function()
    mod:AddTheFutureCompat()
    mod:AddUniqueMiniIsaacsCompat()
    mod:AddCustomCoopGhostsCompat()
end)

mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, entity)
    local ptrHash = GetPtrHash(entity)
    dataHolder.Data[ptrHash] = nil
end)

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
    dataHolder.Data = {}
end)

--in case if mod will be embedded into a pack
return AnimaCharacter
