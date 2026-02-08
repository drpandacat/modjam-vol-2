local mod = HAGAR_MOD

---@param player EntityPlayer
local function HeartActivate(_, player)
    return 450
end
mod:AddCallback(mod.Enums.Callbacks.ZAMZAM_ACTIVATE_HEART, HeartActivate, mod.Enums.StoredHeartKeys.SOUL)