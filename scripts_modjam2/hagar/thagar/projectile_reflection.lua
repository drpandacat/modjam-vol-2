local mod = HAGAR_MOD

local VENGEFUL_MONSTER_COLOR = Color()
VENGEFUL_MONSTER_COLOR:SetColorize(2, 0.8, 2, 1)

---@param projectile EntityProjectile
---@param player EntityPlayer
---@param data table
---@return boolean
local function TryReflectProjectile(projectile, player, data)
    if projectile:HasProjectileFlags(ProjectileFlags.CANT_HIT_PLAYER) then
        return false
    end
    projectile:AddProjectileFlags(ProjectileFlags.CANT_HIT_PLAYER | ProjectileFlags.HIT_ENEMIES)
    projectile.Velocity = -projectile.Velocity
    projectile.Color = Color.Lerp(projectile.Color, VENGEFUL_MONSTER_COLOR, 0.8)
    for _, effectType in ipairs(data.HagarZamzamBuffs) do
        Isaac.RunCallbackWithParam(mod.Enums.Callbacks.ZAMZAM_BULLET_REFLECTED, effectType, projectile, player)
    end
    return true
end

---@param projectile EntityProjectile
---@param collider Entity
local function ProjectileCollision(_, projectile, collider)
    local player = collider:ToPlayer()
    if not player then
        return
    end
    local data = player:GetData()
    if not data.HagarZamzamBuffs then
        return
    end
    if TryReflectProjectile(projectile, player, data) then
        return true
    end
end
mod:AddPriorityCallback(ModCallbacks.MC_PRE_PROJECTILE_COLLISION, CallbackPriority.LATE, ProjectileCollision)

---@param player EntityPlayer
local function PostPeffectUpdate(_, player)
    local data = player:GetData()
    if not data.HagarZamzamBuffs then
        return
    end

    local radius = 25 * player.SpriteScale.Y

    for _, ent in ipairs(Isaac.FindInRadius(player.Position, radius, EntityPartition.BULLET)) do
        local projectile = ent:ToProjectile()
        ---@cast projectile EntityProjectile
        TryReflectProjectile(projectile, player, data)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, PostPeffectUpdate)