local mod = ROBERT_MOD

---@param pickup EntityPickup
local function PostPickupInitCard(_, pickup)
    if pickup.SubType ~= mod.Card.EXIT_KEYCARD then
        return end

    local sprite = pickup:GetSprite()
    sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/robert_exit_card.png")
    sprite:LoadGraphics()
end

mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, PostPickupInitCard, PickupVariant.PICKUP_TAROTCARD)