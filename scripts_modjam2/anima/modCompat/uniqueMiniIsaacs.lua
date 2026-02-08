local constants = include "scripts_modjam2.anima.constants"

function AnimaCharacter:AddUniqueMiniIsaacsCompat()
    if UniqueMinisaacs then
        UniqueMinisaacs.CharacterData[constants.Players.Anima] = {
            Name = "Anima",
            AppendSkinColor = false,
            IsTainted = false,
        }
        UniqueMinisaacs.CharacterData[constants.Players.Anima_Decoy] = {
            AppendSkinColor = false,
            IsTainted = false,
            Filename = "anima",
        }
    end
end
