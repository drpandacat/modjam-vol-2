local mod = HAGAR_MOD

---@param target EntityNPC
---@param player EntityPlayer
local function PostEnemyCollide(_, target, player)
    Isaac.Explode(target.Position, player, 40)
end
mod:AddCallback(mod.Enums.Callbacks.ZAMZAM_ENEMY_COLLISION, PostEnemyCollide, mod.Enums.StoredHeartKeys.BLACK)