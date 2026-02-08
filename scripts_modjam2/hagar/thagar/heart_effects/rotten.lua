local mod = HAGAR_MOD

---@param target EntityNPC
---@param player EntityPlayer
local function PostEnemyCollide(_, target, player)
    target:AddPoison(EntityRef(player), 90, player:GetTearPoisonDamage())
end
mod:AddCallback(mod.Enums.Callbacks.ZAMZAM_ENEMY_COLLISION, PostEnemyCollide, mod.Enums.StoredHeartKeys.ROTTEN)