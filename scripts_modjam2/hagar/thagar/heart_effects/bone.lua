local mod = HAGAR_MOD

---@param target EntityNPC
---@param player EntityPlayer
local function PostEnemyCollide(_, target, player)
    target:AddWeakness(EntityRef(player), 150)
    mod.SFX:Play(SoundEffect.SOUND_BONE_BREAK)
end
mod:AddCallback(mod.Enums.Callbacks.ZAMZAM_ENEMY_COLLISION, PostEnemyCollide, mod.Enums.StoredHeartKeys.BONE)