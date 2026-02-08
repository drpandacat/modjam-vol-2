local mod = HAGAR_MOD

---@param target EntityNPC
---@param player EntityPlayer
local function PostEnemyCollide(_, target, player)
    player:UseActiveItem(CollectibleType.COLLECTIBLE_CRACK_THE_SKY, UseFlag.USE_NOANIM)
end
mod:AddCallback(mod.Enums.Callbacks.ZAMZAM_ENEMY_COLLISION, PostEnemyCollide, mod.Enums.StoredHeartKeys.ETERNAL)