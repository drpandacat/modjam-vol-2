local constants = include "scripts_modjam2.anima.constants"

function AnimaCharacter:AddCustomCoopGhostsCompat()
    if CustomCoopGhost then
        CustomCoopGhost.ChangeSkin(constants.Players.Anima, "gfx/anima/modCompat/customCoopGhost/anima_coop_ghost.png")
    end
end
