local mod = HAGAR_MOD

local MAX_HEART_SUBTYPE = HeartSubType.HEART_ROTTEN

---@param npc EntityNPC
local function PostNPCKill(_, npc)
    if not PlayerManager.AnyoneIsPlayerType(mod.Enums.Character.T_HAGAR) then
        return
    end
    local rng = RNG(npc.DropSeed)
    local chance = 0.2
    if npc.MaxHitPoints < 10 then
        chance = 0.02
    elseif npc.MaxHitPoints < 30 then
        chance = 0.1
    end
    if rng:RandomFloat() > chance then
        return
    end
    local heart = Isaac.Spawn(
        EntityType.ENTITY_PICKUP,
        PickupVariant.PICKUP_HEART,
        rng:RandomInt(MAX_HEART_SUBTYPE),
        npc.Position,
        Vector.Zero,
        npc
    ):ToPickup()
    ---@cast heart EntityPickup
    heart.Timeout = 150
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, PostNPCKill)