local mod = ROBERT_MOD

local function PostModsLoaded()
    ---@diagnostic disable-next-line: undefined-global
    if not ConWorm then
        return
    end

    local conwormTrinket = Isaac.GetTrinketIdByName("ConWorm")
    local conpatCostume = Isaac.GetCostumeIdByPath("gfx/characters/robert_conpat_costume.anm2")
    mod:AddCallback(ModCallbacks.MC_POST_TRIGGER_TRINKET_ADDED,
    ---@param player EntityPlayer
    function (_, player)
        local ptype = player:GetPlayerType()
        if ptype == ROBERT_MOD.PlayerType.ROBERT
        or ptype == ROBERT_MOD.PlayerType.ROBERT_B then
            player:AddNullCostume(conpatCostume)
        end
    end, conwormTrinket)

    mod:AddCallback(ModCallbacks.MC_POST_TRIGGER_TRINKET_REMOVED,
    ---@param player EntityPlayer
    function (_, player)
        if not player:HasTrinket(conwormTrinket) then
            player:TryRemoveNullCostume(conpatCostume)
        end
    end, conwormTrinket)
end

mod:AddCallback(ModCallbacks.MC_POST_MODS_LOADED, PostModsLoaded)