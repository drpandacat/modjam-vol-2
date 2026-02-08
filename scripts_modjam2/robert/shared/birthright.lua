local mod = ROBERT_MOD

local game = Game()

local function PostNewLevel()
    if not PlayerManager.AnyPlayerTypeHasBirthright(mod.PlayerType.ROBERT) then
        return
    end

    local spawnPos = game:GetRoom():GetRandomPosition(10)
    Isaac.Spawn(
        EntityType.ENTITY_PICKUP,
        PickupVariant.PICKUP_TAROTCARD,
        mod.Card.EXIT_KEYCARD,
        spawnPos,
        Vector.Zero,
        nil
    )
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, PostNewLevel)

---@param item integer
---@param charge integer
---@param firstTime boolean
---@param slot ActiveSlot
---@param varData integer
---@param player EntityPlayer
local function PostBirthrightAdded(_, item, charge, firstTime, slot, varData, player)
    if not firstTime then
        return
    end
    if player:GetPlayerType() == mod.PlayerType.ROBERT then
        local spawnPos = Isaac.GetFreeNearPosition(player.Position, 10)
        Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            PickupVariant.PICKUP_TAROTCARD,
            mod.Card.EXIT_KEYCARD,
            spawnPos,
            Vector.Zero,
            nil
        )
    end
end
mod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, PostBirthrightAdded, CollectibleType.COLLECTIBLE_BIRTHRIGHT)