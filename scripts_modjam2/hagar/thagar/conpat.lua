local mod = HAGAR_MOD

local function PostModsLoaded()
    if not ConWorm then
        return
    end
    local conwormTrinket = Isaac.GetTrinketIdByName("ConWorm")
    ---@param player EntityPlayer
    mod:AddCallback(ModCallbacks.MC_PRE_ADD_TRINKET, function (_, player)
        if player:GetPlayerType() == mod.Enums.Character.T_HAGAR
        and mod.Zamzam.AddToBuffer(player, mod.Enums.StoredHeartKeys.CON) then
            mod.SFX:Play(SoundEffect.SOUND_VAMP_DOUBLE)
            return false
        end
    end, conwormTrinket)

    local CON_COLOR = Color(0.2,0.2,1)

    mod:AddCallback(mod.Enums.Callbacks.ZAMZAM_ENEMY_COLLISION,
    ---@param npc EntityNPC
    ---@param player EntityPlayer
    function (_, npc, player)
        local maggot = Isaac.Spawn(
            EntityType.ENTITY_SMALL_MAGGOT,
            0,
            0,
            player.Position,
            Vector.Zero,
            player
        )
        maggot:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        maggot:AddCharmed(EntityRef(player), -1)
        maggot:SetColor(CON_COLOR, 999999999, 99, false, true)
    end, mod.Enums.StoredHeartKeys.CON)
end
mod:AddCallback(ModCallbacks.MC_POST_MODS_LOADED, PostModsLoaded)